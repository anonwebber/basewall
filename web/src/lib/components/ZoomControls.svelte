<script lang="ts">
  import { wall } from '$lib/stores/wall.svelte';

  const zoomPercent = $derived(`${Math.round(wall.zoom * 100)}%`);
</script>

<div class="fixed bottom-20 sm:bottom-24 left-5 sm:left-7 z-20 pointer-events-none">
  <div class="glass rounded-lg shadow-panel pointer-events-auto flex flex-col overflow-hidden divide-y divide-ink-700/60">
    <button
      class="zoom-btn"
      aria-label="zoom in"
      onclick={() => wall.zoomIn()}
    >
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <path d="M7 2v10M2 7h10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
      </svg>
    </button>
    <button
      class="zoom-btn"
      aria-label="zoom out"
      onclick={() => wall.zoomOut()}
    >
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <path d="M2 7h10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
      </svg>
    </button>
    <button
      class="zoom-btn !text-[10px] !leading-none font-mono tracking-wider !w-9 !h-9"
      aria-label="reset view"
      onclick={() => wall.resetView()}
      title="fit to screen"
    >
      fit
    </button>
    {#if wall.wallet.connected && wall.wallet.ownedBrickIds.length > 0}
      <button
        class="zoom-btn text-accent-cream"
        aria-label="fly to my bricks"
        onclick={() => wall.flyToMine()}
        title="fly to my bricks"
      >
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <circle cx="7" cy="7" r="1.5" fill="currentColor" />
          <circle cx="7" cy="7" r="4" stroke="currentColor" stroke-width="1.2" />
          <path d="M7 1v2M7 11v2M1 7h2M11 7h2" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" />
        </svg>
      </button>
    {/if}
  </div>

  <div class="mt-1.5 text-center font-mono text-2xs text-ink-500 pointer-events-none">
    {zoomPercent}
  </div>
</div>

<style>
  .zoom-btn {
    width: 36px;
    height: 36px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: theme('colors.ink.200');
    transition: all 0.15s ease;
  }
  .zoom-btn:hover {
    background: theme('colors.ink.700' / 60%);
    color: theme('colors.accent.cream');
  }
  .zoom-btn:active {
    transform: scale(0.95);
  }
</style>
