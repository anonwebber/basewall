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
  let initialFitScale = 1;
  let shimmerInterval: ReturnType<typeof setInterval> | null = null;

  // Pointer position for tooltip (in DOM coords)
  let pointerX = $state(0);
  let pointerY = $state(0);

  // Layout constants — 125 wide × 80 tall (1.56:1, exactly 10,000 bricks)
  const GRID_W = 125;
  const GRID_H = 80;
  const BRICK_SIZE = 16;     // px in world space
  const MORTAR = 1.6;        // gap between bricks
  const TOTAL_W = GRID_W * BRICK_SIZE;
  const TOTAL_H = GRID_H * BRICK_SIZE;

  // Zone tints (warm dark base + Base blue + cream — NO orange/gold)
  const TINT_EMPTY = 0x1f1813;
  const TINT_EMPTY_ALT = 0x27201a;     // checker variation
  const TINT_CORNER_ETH = 0x4a82ff;    // Ethereum-ish blue
  const TINT_CORNER_X = 0xe0e0e0;      // X white
  const TINT_CORNER_BASE = 0x0052ff;   // Base blue
  const TINT_CORNER_UNI = 0xff007a;    // Uniswap pink
  const TINT_CENTER_DEV = 0x1f1813;    // same as empty — marked by outline frame instead of fill
  const TINT_HOVER = 0xf5efe6;         // cream (hover ring + fill)
  const TINT_FRAME = 0xf5efe6;         // wall outer frame (cream)
  const TINT_RESERVE_FRAME = 0xf5efe6; // cream outline around center reserve

  // Zone bounds for 125×80 grid: corners 10×10 at four corners,
  //   center reserve 25×20 at (50,30)-(75,50) — perfectly centered (125/2=62.5±12.5, 80/2=40±10)
  function zoneTint(x: number, y: number): number {
    if (x < 10 && y < 10) return TINT_CORNER_ETH;
    if (x >= GRID_W - 10 && y < 10) return TINT_CORNER_X;
    if (x < 10 && y >= GRID_H - 10) return TINT_CORNER_BASE;
    if (x >= GRID_W - 10 && y >= GRID_H - 10) return TINT_CORNER_UNI;
    if (x >= 50 && x < 75 && y >= 30 && y < 50) return TINT_CENTER_DEV;
    return ((x + y) % 2 === 0) ? TINT_EMPTY : TINT_EMPTY_ALT;
  }

  function brickId(x: number, y: number): number {
    return y * GRID_W + x + 1;
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

    // Initial framing — fit grid with tighter padding for more presence
    const padding = 64;
    const fitScale = Math.min(
      (app.screen.width - padding * 2) / TOTAL_W,
      (app.screen.height - padding * 2) / TOTAL_H
    );
    viewport.setZoom(fitScale, true);
    viewport.moveCenter(TOTAL_W / 2, TOTAL_H / 2);

    // Stash for resetView()
    initialFitScale = fitScale;

    // ----- Outer frame (drawn first, so it sits BEHIND the bricks) -----
    const frame = new PIXI.Graphics();
    const FRAME_PAD = 6;
    frame.rect(-FRAME_PAD, -FRAME_PAD, TOTAL_W + FRAME_PAD * 2, TOTAL_H + FRAME_PAD * 2);
    frame.stroke({ color: TINT_FRAME, width: 1.5, alpha: 0.18 });
    // Subtle inner band
    frame.rect(-2, -2, TOTAL_W + 4, TOTAL_H + 4);
    frame.stroke({ color: TINT_FRAME, width: 1, alpha: 0.08 });
    viewport.addChild(frame);

    // ----- Grid container -----
    gridContainer = new PIXI.Container();
    gridContainer.cullable = false; // we cull children individually
    viewport.addChild(gridContainer);

    // Render 10,000 sprites, all sharing Texture.WHITE for batching
    const sharedTex = PIXI.Texture.WHITE;
    brickSprites = new Array(GRID_W * GRID_H);

    for (let y = 0; y < GRID_H; y++) {
      for (let x = 0; x < GRID_W; x++) {
        const sprite = new PIXI.Sprite(sharedTex);
        sprite.x = x * BRICK_SIZE + MORTAR / 2;
        sprite.y = y * BRICK_SIZE + MORTAR / 2;
        sprite.width = BRICK_SIZE - MORTAR;
        sprite.height = BRICK_SIZE - MORTAR;
        sprite.tint = zoneTint(x, y);
        sprite.cullable = true;
        sprite.eventMode = 'none';
        brickSprites[y * GRID_W + x] = sprite;
        gridContainer.addChild(sprite);
      }
    }

    // ----- Center reserve outline (cream frame marks the dev reserve, no fill tint) -----
    const reserveFrame = new PIXI.Graphics();
    const RX = 50 * BRICK_SIZE - MORTAR / 2;
    const RY = 30 * BRICK_SIZE - MORTAR / 2;
    const RW = 25 * BRICK_SIZE + MORTAR;
    const RH = 20 * BRICK_SIZE + MORTAR;
    reserveFrame.rect(RX, RY, RW, RH);
    reserveFrame.stroke({ color: TINT_RESERVE_FRAME, width: 1.8, alpha: 0.45 });
    // Inner subtle band
    reserveFrame.rect(RX + 2, RY + 2, RW - 4, RH - 4);
    reserveFrame.stroke({ color: TINT_RESERVE_FRAME, width: 0.8, alpha: 0.15 });
    viewport.addChild(reserveFrame);

    // ----- Hover overlay (single sprite that moves around) -----
    hoverOverlay = new PIXI.Graphics();
    hoverOverlay.rect(0, 0, BRICK_SIZE - MORTAR, BRICK_SIZE - MORTAR);
    hoverOverlay.stroke({ color: TINT_HOVER, width: 1.3, alpha: 0.95 });
    hoverOverlay.fill({ color: TINT_HOVER, alpha: 0.14 });
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

      if (col < 0 || col >= GRID_W || row < 0 || row >= GRID_H) {
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
      if (col < 0 || col >= GRID_W || row < 0 || row >= GRID_H) return;
      const id = brickId(col, row);
      onBrickClick?.(id);
    });

    // Sync viewport zoom to store
    viewport.on('zoomed', () => {
      wall.zoom = viewport.scale.x;
      updateViewportRect();
    });
    viewport.on('moved', updateViewportRect);

    function updateViewportRect() {
      if (!viewport || destroyed) return;
      const b = viewport.getVisibleBounds();
      wall.viewportRect = {
        x: Math.max(0, b.x),
        y: Math.max(0, b.y),
        w: Math.min(b.width, TOTAL_W - Math.max(0, b.x)),
        h: Math.min(b.height, TOTAL_H - Math.max(0, b.y))
      };
    }
    // Prime initial
    updateViewportRect();

    // ----- Ambient shimmer: every ~1.4s a random empty brick briefly brightens (life signal) -----
    shimmerInterval = setInterval(() => {
      if (destroyed || !brickSprites.length) return;
      // Pick random brick; if not an empty zone, skip this round
      const idx = Math.floor(Math.random() * brickSprites.length);
      const sprite = brickSprites[idx];
      if (!sprite) return;
      const col = idx % GRID_W;
      const row = Math.floor(idx / GRID_W);
      const tint = zoneTint(col, row);
      if (tint !== TINT_EMPTY && tint !== TINT_EMPTY_ALT) return;

      const orig = sprite.tint;
      // Brighten by ~50% along same hue
      const r = ((orig >> 16) & 0xff) + 30;
      const g = ((orig >> 8) & 0xff) + 25;
      const b = (orig & 0xff) + 22;
      sprite.tint = ((Math.min(255, r) << 16) | (Math.min(255, g) << 8) | Math.min(255, b)) >>> 0;
      setTimeout(() => {
        if (!destroyed && sprite) sprite.tint = orig;
      }, 700);
    }, 1400);

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

  // React to camera commands from outside (zoom controls, fly-to-mine)
  $effect(() => {
    if (!wall.cameraCommand || !viewport || destroyed) return;
    const { action } = wall.cameraCommand;
    const cx = viewport.center.x;
    const cy = viewport.center.y;
    switch (action) {
      case 'in':
        viewport.animate({ scale: Math.min(12, viewport.scale.x * 1.6), time: 250, ease: 'easeOutCubic' });
        break;
      case 'out':
        viewport.animate({ scale: Math.max(initialFitScale, viewport.scale.x / 1.6), time: 250, ease: 'easeOutCubic' });
        break;
      case 'reset':
        viewport.animate({
          position: { x: TOTAL_W / 2, y: TOTAL_H / 2 },
          scale: initialFitScale,
          time: 400,
          ease: 'easeOutCubic'
        });
        break;
      case 'fit-to-me': {
        if (wall.wallet.ownedBrickIds.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const id of wall.wallet.ownedBrickIds) {
          const idx = id - 1;
          const bx = (idx % GRID_W) * BRICK_SIZE;
          const by = Math.floor(idx / GRID_W) * BRICK_SIZE;
          minX = Math.min(minX, bx); minY = Math.min(minY, by);
          maxX = Math.max(maxX, bx + BRICK_SIZE); maxY = Math.max(maxY, by + BRICK_SIZE);
        }
        const centroid = { x: (minX + maxX) / 2, y: (minY + maxY) / 2 };
        const targetScale = Math.min(
          app.screen.width / ((maxX - minX) * 2.2),
          app.screen.height / ((maxY - minY) * 2.2),
          4
        );
        viewport.animate({
          position: centroid,
          scale: Math.max(initialFitScale, targetScale),
          time: 600,
          ease: 'easeOutCubic'
        });
        break;
      }
    }
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
          const col = idx % GRID_W;
          const row = Math.floor(idx / GRID_W);
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
    if (shimmerInterval) {
      clearInterval(shimmerInterval);
      shimmerInterval = null;
    }
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
    const bx = idx % GRID_W;
    const by = Math.floor(idx / GRID_W);
    return wall.getZone(bx, by);
  });
</script>

<div bind:this={containerEl} class="absolute inset-0">
  <canvas bind:this={canvasEl} class="w-full h-full"></canvas>
</div>

<!-- Tooltip overlay (DOM-rendered, follows pointer) -->
{#if wall.hoveredBrick !== null && !wall.tooltipMuted}
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
          ({(wall.hoveredBrick - 1) % GRID_W},{Math.floor((wall.hoveredBrick - 1) / GRID_W)})
        </span>
      </div>
      {#if hoveredZone}
        <div class="font-mono text-2xs tracking-widest uppercase
                    {hoveredZone === 'public' ? 'text-ink-300' :
                     hoveredZone === 'center-dev' ? 'text-accent-cream' :
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
