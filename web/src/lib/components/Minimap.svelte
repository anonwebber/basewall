<script lang="ts">
  import { wall } from '$lib/stores/wall.svelte';

  const WORLD = 100 * 16; // grid 100 × brick 16px (matches Wall.svelte constants)
  const MAP_SIZE = 116;   // px size of the minimap

  // Camera viewport rect projected onto the minimap
  const r = $derived({
    x: (wall.viewportRect.x / WORLD) * MAP_SIZE,
    y: (wall.viewportRect.y / WORLD) * MAP_SIZE,
    w: Math.max(2, (wall.viewportRect.w / WORLD) * MAP_SIZE),
    h: Math.max(2, (wall.viewportRect.h / WORLD) * MAP_SIZE)
  });

  // Show only when zoomed in past initial fit (i.e. viewport rect smaller than world)
  const show = $derived(wall.viewportRect.w > 0 && wall.viewportRect.w < WORLD * 0.95);
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
        style="width: {MAP_SIZE}px; height: {MAP_SIZE}px;"
      >
        <!-- Static minimap art: 4 corners + center reserve as proportional rects -->
        <svg viewBox="0 0 100 100" class="w-full h-full">
          <rect x="0" y="0" width="100" height="100" fill="#1f1813" />
          <!-- corners 10x10 each -->
          <rect x="0" y="0" width="10" height="10" fill="#4a82ff" />
          <rect x="90" y="0" width="10" height="10" fill="#e0e0e0" />
          <rect x="0" y="90" width="10" height="10" fill="#0052ff" />
          <rect x="90" y="90" width="10" height="10" fill="#ff007a" />
          <!-- center reserve 20×25 at (40-60, 38-63) -->
          <rect x="40" y="38" width="20" height="25" fill="#6b4a2e" />
        </svg>

        <!-- Camera viewport rect indicator -->
        <div
          class="absolute border border-accent-gold/90 bg-accent-gold/10 pointer-events-none"
          style="left: {r.x}px; top: {r.y}px; width: {r.w}px; height: {r.h}px; box-shadow: 0 0 6px rgba(255,176,32,0.3);"
        ></div>
      </div>
    </div>
  </aside>
{/if}
