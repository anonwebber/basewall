<script lang="ts">
  import { wall } from '$lib/stores/wall.svelte';
  import { brickCoords, shortAddress } from '$lib/utils/formatters';

  let { x = 0, y = 0 }: { x?: number; y?: number } = $props();

  // Determine zone label for hovered brick
  function zoneLabel(id: number | null) {
    if (!id) return null;
    const idx = id - 1;
    const bx = idx % 100;
    const by = Math.floor(idx / 100);
    const zone = wall.getZone(bx, by);
    switch (zone) {
      case 'corner-eth': return { label: 'ETHEREUM CORNER', tone: 'text-accent-base' };
      case 'corner-x': return { label: 'X CORNER', tone: 'text-ink-50' };
      case 'corner-base': return { label: 'BASE CORNER', tone: 'text-accent-base' };
      case 'corner-uni': return { label: 'UNISWAP CORNER', tone: 'text-accent-gold' };
      case 'center-dev': return { label: 'PREMIUM RESERVE', tone: 'text-accent-gold' };
      default: return { label: 'PUBLIC', tone: 'text-ink-300' };
    }
  }

  const zone = $derived(zoneLabel(wall.hoveredBrick));
</script>

{#if wall.hoveredBrick !== null}
  <div
    class="fixed pointer-events-none z-40 transition-opacity duration-100"
    style="left: {x + 16}px; top: {y + 16}px;"
  >
    <div class="glass-strong rounded-md px-3 py-2 shadow-panel min-w-[200px]">
      <div class="flex items-center justify-between gap-3 mb-1">
        <span class="font-display text-sm font-bold text-ink-50">
          brick #{wall.hoveredBrick}
        </span>
        <span class="font-mono text-2xs text-ink-500">
          {brickCoords(wall.hoveredBrick)}
        </span>
      </div>

      {#if zone}
        <div class="font-mono text-2xs tracking-widest uppercase {zone.tone}">
          {zone.label}
        </div>
      {/if}

      <div class="mt-1.5 pt-1.5 border-t border-ink-700/60 font-mono text-2xs text-ink-400">
        unminted · 0.001 ETH
      </div>
    </div>
  </div>
{/if}
