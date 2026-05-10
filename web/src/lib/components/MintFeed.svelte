<script lang="ts">
  import { onMount } from 'svelte';
  import { wall } from '$lib/stores/wall.svelte';
  import { timeAgo, brickCoords } from '$lib/utils/formatters';

  let now = $state(Date.now());
  onMount(() => {
    const t = setInterval(() => (now = Date.now()), 1000);
    return () => clearInterval(t);
  });
</script>

<aside class="fixed right-5 sm:right-7 top-24 z-20 w-64 hidden md:block pointer-events-none">
  <div class="glass rounded-xl p-3 shadow-panel pointer-events-auto">
    <div class="flex items-center justify-between mb-2.5 px-1">
      <div class="flex items-center gap-2">
        <span class="ticker-dot"></span>
        <span class="font-mono text-2xs tracking-widest uppercase text-ink-300">live mints</span>
      </div>
      <span class="font-mono text-2xs text-ink-500">on base</span>
    </div>

    <div class="space-y-1.5 max-h-[280px] overflow-hidden">
      {#each wall.mintFeed as mint (mint.timestamp + '-' + mint.id)}
        <div class="flex items-center justify-between gap-2 px-2.5 py-1.5 rounded-md
                    bg-ink-900/60 hover:bg-ink-800/60 transition-colors animate-fade-up">
          <div class="flex items-center gap-2 min-w-0">
            <span class="font-mono text-2xs text-accent-cream shrink-0">#{mint.id}</span>
            <span class="font-mono text-2xs text-ink-500 shrink-0">{brickCoords(mint.id)}</span>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <span class="font-mono text-2xs text-ink-300">{mint.minter}</span>
            <span class="font-mono text-2xs text-ink-600">{timeAgo(mint.timestamp)}</span>
          </div>
        </div>
      {/each}

      {#if wall.mintFeed.length === 0}
        <div class="px-2.5 py-4 text-center font-mono text-2xs text-ink-500">
          waiting for first mint…
        </div>
      {/if}
    </div>
  </div>
</aside>
