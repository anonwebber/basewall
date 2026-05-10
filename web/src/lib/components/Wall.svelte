<script lang="ts">
  import { onMount, onDestroy } from 'svelte';

  let { highlightOwned = false } = $props();

  let canvasEl: HTMLCanvasElement;
  let app: any = null;
  let gridContainer: any = null;

  // 100x100 grid, each brick is BRICK_SIZE px at zoom 1
  const GRID = 100;
  const BRICK_SIZE = 32;
  const TOTAL_W = GRID * BRICK_SIZE;
  const TOTAL_H = GRID * BRICK_SIZE;
  const DEV_RESERVE_START = 9500; // tokenIds 9501..10000 (0-indexed: 9500..9999)

  onMount(async () => {
    const PIXI = await import('pixi.js');

    app = new PIXI.Application();
    await app.init({
      canvas: canvasEl,
      resizeTo: canvasEl.parentElement!,
      backgroundColor: 0x0a0a0a,
      antialias: false,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true
    });

    gridContainer = new PIXI.Container();
    app.stage.addChild(gridContainer);

    // Center the grid initially
    gridContainer.x = (app.screen.width - TOTAL_W) / 2;
    gridContainer.y = (app.screen.height - TOTAL_H) / 2;

    // Draw 10k brick placeholders
    const g = new PIXI.Graphics();
    for (let i = 0; i < GRID * GRID; i++) {
      const x = (i % GRID) * BRICK_SIZE;
      const y = Math.floor(i / GRID) * BRICK_SIZE;
      const isDev =
        i % GRID >= 40 &&
        i % GRID < 60 &&
        Math.floor(i / GRID) >= 38 &&
        Math.floor(i / GRID) < 63;
      g.rect(x + 1, y + 1, BRICK_SIZE - 2, BRICK_SIZE - 2);
      g.fill({ color: isDev ? 0x222244 : 0x1a1a1a });
    }
    gridContainer.addChild(g);

    // Wheel-zoom (clamped 0.05x to 8x)
    canvasEl.addEventListener('wheel', (e) => {
      e.preventDefault();
      const factor = e.deltaY < 0 ? 1.1 : 0.9;
      const next = Math.max(0.05, Math.min(8, gridContainer.scale.x * factor));
      const mx = e.offsetX;
      const my = e.offsetY;
      const wx = (mx - gridContainer.x) / gridContainer.scale.x;
      const wy = (my - gridContainer.y) / gridContainer.scale.y;
      gridContainer.scale.set(next);
      gridContainer.x = mx - wx * next;
      gridContainer.y = my - wy * next;
    }, { passive: false });

    // Drag-pan
    let dragging = false;
    let lx = 0, ly = 0;
    canvasEl.addEventListener('pointerdown', (e) => {
      dragging = true;
      lx = e.clientX;
      ly = e.clientY;
    });
    canvasEl.addEventListener('pointermove', (e) => {
      if (!dragging) return;
      gridContainer.x += e.clientX - lx;
      gridContainer.y += e.clientY - ly;
      lx = e.clientX;
      ly = e.clientY;
    });
    canvasEl.addEventListener('pointerup', () => (dragging = false));
    canvasEl.addEventListener('pointerleave', () => (dragging = false));
  });

  onDestroy(() => {
    if (app) app.destroy(true, true);
  });

  // TODO: react to highlightOwned prop — overlay layer with pulsing yellow on owned brick coords
  $effect(() => {
    if (!gridContainer) return;
    // placeholder — Day 7 implements the overlay
    void highlightOwned;
  });
</script>

<canvas bind:this={canvasEl} class="w-full h-full block"></canvas>
