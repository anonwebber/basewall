<script lang="ts">
  import { wall } from '$lib/stores/wall.svelte';

  // 125 wide × 80 tall × 16px per brick (matches Wall.svelte constants)
  const GRID_W = 125;
  const GRID_H = 80;
  const BRICK_PX = 16;
  const WORLD_W = GRID_W * BRICK_PX; // 2000
  const WORLD_H = GRID_H * BRICK_PX; // 1280

  // Display dimensions — keep 125:80 ratio at ~160px wide
  const MAP_W = 160;
  const MAP_H = Math.round(MAP_W * (GRID_H / GRID_W)); // 102

  // Camera viewport rect projected onto the minimap
  const r = $derived({
    x: (wall.viewportRect.x / WORLD_W) * MAP_W,
    y: (wall.viewportRect.y / WORLD_H) * MAP_H,
    w: Math.max(2, (wall.viewportRect.w / WORLD_W) * MAP_W),
    h: Math.max(2, (wall.viewportRect.h / WORLD_H) * MAP_H)
  });

  // Show only when zoomed in past initial fit
  const show = $derived(
    wall.viewportRect.w > 0 &&
      (wall.viewportRect.w < WORLD_W * 0.95 || wall.viewportRect.h < WORLD_H * 0.95)
  );
</script>

{#if show}
  <aside class="fixed bottom-20 sm:bottom-24 right-5 sm:right-7 z-20 pointer-events-none animate-fade-up">
    <div class="glass rounded-lg p-2 shadow-panel">
      <div class="flex items-center justify-between mb-1.5 px-1">
        <span class="font-mono text-2xs tracking-widest uppercase text-ink-400">map</span>
        <span class="font-mono text-2xs text-ink-500">{Math.round(wall.zoom * 100)}%</span>
      </div>
      <div
        class="relative border border-ink-600/60 rounded overflow-hidden bg-ink-900"
        style="width: {MAP_W}px; height: {MAP_H}px;"
      >
        <!-- Schematic: 4 corners at correct proportions -->
        <svg viewBox="0 0 {GRID_W} {GRID_H}" preserveAspectRatio="none" class="w-full h-full">
          <rect width={GRID_W} height={GRID_H} fill="#1f1813" />
          <!-- 4 corners 10×10 each -->
          <rect x="0" y="0" width="10" height="10" fill="#4a82ff" />
          <rect x={GRID_W - 10} y="0" width="10" height="10" fill="#e0e0e0" />
          <rect x="0" y={GRID_H - 10} width="10" height="10" fill="#0052ff" />
          <rect x={GRID_W - 10} y={GRID_H - 10} width="10" height="10" fill="#ff007a" />
        </svg>

        <!-- Camera viewport rect indicator -->
        <div
          class="absolute border border-accent-cream/90 bg-accent-cream/10 pointer-events-none"
          style="left: {r.x}px; top: {r.y}px; width: {r.w}px; height: {r.h}px; box-shadow: 0 0 6px rgba(245,239,230,0.3);"
        ></div>
      </div>
    </div>
  </aside>
{/if}
