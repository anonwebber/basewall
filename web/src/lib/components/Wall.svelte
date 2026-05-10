<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { browser } from '$app/environment';
  import { wall } from '$lib/stores/wall.svelte';

  let { onBrickClick }: { onBrickClick?: (id: number) => void } = $props();

  let canvasEl: HTMLCanvasElement;
  let containerEl: HTMLDivElement;

  // Pixi internals — kept in plain `let` (NOT $state) to avoid Proxy wrap
  let app: any = null;
  let viewport: any = null;
  let gridContainer: any = null;
  let brickSprites: any[] = [];
  let hoverOverlay: any = null;
  let highlightOverlay: any = null;
  let destroyed = false;
  let resizeHandler: (() => void) | null = null;

  // Pointer position for tooltip (in DOM coords)
  let pointerX = $state(0);
  let pointerY = $state(0);

  // Layout constants
  const GRID = 100;
  const BRICK_SIZE = 16;     // px in world space
  const MORTAR = 1.6;        // gap between bricks
  const TOTAL_W = GRID * BRICK_SIZE;
  const TOTAL_H = GRID * BRICK_SIZE;

  // Zone tints (warm dark palette)
  const TINT_EMPTY = 0x1e1812;
  const TINT_EMPTY_ALT = 0x231a13;   // slight stagger for organic look
  const TINT_CORNER_ETH = 0x4a82ff;  // Ethereum-ish blue
  const TINT_CORNER_X = 0xe0e0e0;    // X white
  const TINT_CORNER_BASE = 0x0052ff; // Base blue
  const TINT_CORNER_UNI = 0xff007a;  // Uniswap pink
  const TINT_CENTER_DEV = 0x4a3624;  // dark warm gold-brown
  const TINT_HOVER = 0xffb020;       // gold

  function zoneTint(x: number, y: number): number {
    if (x < 10 && y < 10) return TINT_CORNER_ETH;
    if (x >= 90 && y < 10) return TINT_CORNER_X;
    if (x < 10 && y >= 90) return TINT_CORNER_BASE;
    if (x >= 90 && y >= 90) return TINT_CORNER_UNI;
    if (x >= 40 && x < 60 && y >= 38 && y < 63) return TINT_CENTER_DEV;
    return ((x + y) % 2 === 0) ? TINT_EMPTY : TINT_EMPTY_ALT;
  }

  function brickId(x: number, y: number): number {
    return y * GRID + x + 1;
  }

  onMount(async () => {
    if (!browser) return;

    const PIXI = await import('pixi.js');
    const { Viewport } = await import('pixi-viewport');

    app = new PIXI.Application();
    await app.init({
      canvas: canvasEl,
      resizeTo: containerEl,
      backgroundAlpha: 0,
      antialias: true,
      resolution: Math.min(window.devicePixelRatio || 1, 2),
      autoDensity: true,
      preference: 'webgl'
    });

    // Enable culling globally (CullerPlugin)
    PIXI.extensions.add(PIXI.CullerPlugin);

    // ----- Viewport (camera) -----
    viewport = new Viewport({
      screenWidth: app.screen.width,
      screenHeight: app.screen.height,
      worldWidth: TOTAL_W,
      worldHeight: TOTAL_H,
      events: app.renderer.events
    });

    // Disable propagation to per-brick events; we'll handle pointer at viewport level
    viewport.eventMode = 'static';
    viewport.interactiveChildren = false;

    app.stage.addChild(viewport);

    viewport
      .drag({ mouseButtons: 'all' })
      .pinch()
      .wheel({ smooth: 5, percent: 0.12 })
      .decelerate({ friction: 0.93 })
      .clampZoom({ minScale: 0.25, maxScale: 12 });

    // Initial framing — fit grid with padding
    const padding = 80;
    const fitScale = Math.min(
      (app.screen.width - padding * 2) / TOTAL_W,
      (app.screen.height - padding * 2) / TOTAL_H
    );
    viewport.setZoom(fitScale, true);
    viewport.moveCenter(TOTAL_W / 2, TOTAL_H / 2);

    // ----- Grid container -----
    gridContainer = new PIXI.Container();
    gridContainer.cullable = false; // we cull children individually
    viewport.addChild(gridContainer);

    // Render 10,000 sprites, all sharing Texture.WHITE for batching
    const sharedTex = PIXI.Texture.WHITE;
    brickSprites = new Array(GRID * GRID);

    for (let y = 0; y < GRID; y++) {
      for (let x = 0; x < GRID; x++) {
        const sprite = new PIXI.Sprite(sharedTex);
        sprite.x = x * BRICK_SIZE + MORTAR / 2;
        sprite.y = y * BRICK_SIZE + MORTAR / 2;
        sprite.width = BRICK_SIZE - MORTAR;
        sprite.height = BRICK_SIZE - MORTAR;
        sprite.tint = zoneTint(x, y);
        sprite.cullable = true;
        sprite.eventMode = 'none';
        brickSprites[y * GRID + x] = sprite;
        gridContainer.addChild(sprite);
      }
    }

    // ----- Hover overlay (single sprite that moves around) -----
    hoverOverlay = new PIXI.Graphics();
    hoverOverlay.rect(0, 0, BRICK_SIZE - MORTAR, BRICK_SIZE - MORTAR);
    hoverOverlay.stroke({ color: TINT_HOVER, width: 1.2, alpha: 0.9 });
    hoverOverlay.fill({ color: TINT_HOVER, alpha: 0.18 });
    hoverOverlay.visible = false;
    hoverOverlay.eventMode = 'none';
    viewport.addChild(hoverOverlay);

    // ----- Highlight overlay (for owned bricks toggle) -----
    highlightOverlay = new PIXI.Container();
    highlightOverlay.visible = false;
    viewport.addChild(highlightOverlay);

    // ----- Global pointer handler (integer-math hit test) -----
    viewport.on('globalpointermove', (e: any) => {
      const world = viewport.toWorld(e.global);
      pointerX = e.global.x;
      pointerY = e.global.y;

      const col = Math.floor(world.x / BRICK_SIZE);
      const row = Math.floor(world.y / BRICK_SIZE);

      if (col < 0 || col >= GRID || row < 0 || row >= GRID) {
        wall.hoveredBrick = null;
        hoverOverlay.visible = false;
        return;
      }

      const id = brickId(col, row);
      wall.hoveredBrick = id;
      hoverOverlay.x = col * BRICK_SIZE + MORTAR / 2;
      hoverOverlay.y = row * BRICK_SIZE + MORTAR / 2;
      hoverOverlay.visible = true;
    });

    viewport.on('pointerleave', () => {
      wall.hoveredBrick = null;
      hoverOverlay.visible = false;
    });

    viewport.on('clicked', (e: any) => {
      // pixi-viewport emits 'clicked' for click vs drag distinction
      const world = e.world;
      const col = Math.floor(world.x / BRICK_SIZE);
      const row = Math.floor(world.y / BRICK_SIZE);
      if (col < 0 || col >= GRID || row < 0 || row >= GRID) return;
      const id = brickId(col, row);
      onBrickClick?.(id);
    });

    // Sync viewport zoom to store
    viewport.on('zoomed', () => {
      wall.zoom = viewport.scale.x;
    });

    // ----- Resize handling -----
    resizeHandler = () => {
      if (!viewport || destroyed) return;
      viewport.resize(app.screen.width, app.screen.height, TOTAL_W, TOTAL_H);
    };
    window.addEventListener('resize', resizeHandler);

    // Render loop: keep cullable sprites pruned each frame
    app.ticker.add(() => {
      if (destroyed) return;
      const bounds = viewport.getVisibleBounds();
      // Manual cull — Pixi's CullerPlugin culls vs screen, but viewport is transformed
      const margin = BRICK_SIZE * 4;
      const minX = bounds.x - margin;
      const maxX = bounds.x + bounds.width + margin;
      const minY = bounds.y - margin;
      const maxY = bounds.y + bounds.height + margin;

      for (let i = 0; i < brickSprites.length; i++) {
        const s = brickSprites[i];
        s.visible = s.x < maxX && s.x + s.width > minX && s.y < maxY && s.y + s.height > minY;
      }
    });
  });

  // React to highlight toggle — draw pulsing rings on owned bricks
  $effect(() => {
    if (!highlightOverlay) return;
    highlightOverlay.removeChildren();

    if (wall.highlightOwned && wall.wallet.ownedBrickIds.length > 0) {
      import('pixi.js').then((PIXI) => {
        if (destroyed) return;
        for (const id of wall.wallet.ownedBrickIds) {
          const idx = id - 1;
          const col = idx % GRID;
          const row = Math.floor(idx / GRID);
          const ring = new PIXI.Graphics();
          ring.rect(-MORTAR / 2, -MORTAR / 2, BRICK_SIZE, BRICK_SIZE);
          ring.stroke({ color: TINT_HOVER, width: 2, alpha: 1 });
          ring.fill({ color: TINT_HOVER, alpha: 0.22 });
          ring.x = col * BRICK_SIZE + MORTAR / 2;
          ring.y = row * BRICK_SIZE + MORTAR / 2;
          highlightOverlay.addChild(ring);
        }
        highlightOverlay.visible = true;
      });
    } else {
      highlightOverlay.visible = false;
    }
  });

  onDestroy(() => {
    destroyed = true;
    if (resizeHandler) {
      window.removeEventListener('resize', resizeHandler);
      resizeHandler = null;
    }
    if (app) {
      app.destroy(true, { children: true, texture: false });
      app = null;
    }
  });

  // Zone label for hover tooltip
  const hoveredZone = $derived.by(() => {
    if (wall.hoveredBrick === null) return null;
    const idx = wall.hoveredBrick - 1;
    const bx = idx % GRID;
    const by = Math.floor(idx / GRID);
    return wall.getZone(bx, by);
  });
</script>

<div bind:this={containerEl} class="absolute inset-0">
  <canvas bind:this={canvasEl} class="w-full h-full"></canvas>
</div>

<!-- Tooltip overlay (DOM-rendered, follows pointer) -->
{#if wall.hoveredBrick !== null}
  <div
    class="fixed pointer-events-none z-40 transition-opacity duration-75"
    style="left: {pointerX + 18}px; top: {pointerY + 18}px;"
  >
    <div class="glass-strong rounded-md px-3 py-2 shadow-panel min-w-[180px]">
      <div class="flex items-center justify-between gap-3 mb-1">
        <span class="font-display text-sm font-bold text-ink-50">
          brick #{wall.hoveredBrick}
        </span>
        <span class="font-mono text-2xs text-ink-500">
          ({(wall.hoveredBrick - 1) % GRID},{Math.floor((wall.hoveredBrick - 1) / GRID)})
        </span>
      </div>
      {#if hoveredZone}
        <div class="font-mono text-2xs tracking-widest uppercase
                    {hoveredZone === 'public' ? 'text-ink-300' :
                     hoveredZone === 'center-dev' ? 'text-accent-gold' :
                     'text-accent-base'}">
          {hoveredZone.replace('-', ' ')}
        </div>
      {/if}
      <div class="mt-1.5 pt-1.5 border-t border-ink-700/60 font-mono text-2xs text-ink-400">
        click to view · 0.001 ETH to mint
      </div>
    </div>
  </div>
{/if}
