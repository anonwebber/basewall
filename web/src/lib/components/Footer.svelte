<script lang="ts">
  import { wall } from '$lib/stores/wall.svelte';
  import { eth } from '$lib/utils/formatters';

  const fillPercent = $derived(((wall.publicMinted / wall.publicSupply) * 100).toFixed(1));
</script>

<footer class="fixed bottom-0 left-0 right-0 z-30 px-5 sm:px-7 pb-4 pointer-events-none">
  <div class="glass rounded-xl px-4 py-2.5 flex items-center justify-between gap-4 shadow-panel pointer-events-auto">
    <!-- Left: fill progress -->
    <div class="flex items-center gap-4">
      <div class="flex items-center gap-2">
        <span class="font-mono text-2xs tracking-widest uppercase text-ink-400">filled</span>
        <span class="font-mono text-xs text-accent-cream">{fillPercent}%</span>
      </div>
      <div class="hidden sm:flex items-center gap-2 pl-4 border-l border-ink-600/60">
        <span class="font-mono text-2xs tracking-widest uppercase text-ink-400">minted</span>
        <span class="font-mono text-xs text-ink-100">{wall.publicMinted.toLocaleString()} / {wall.publicSupply.toLocaleString()}</span>
      </div>
    </div>

    <!-- Center: brick economy -->
    <div class="hidden md:flex items-center gap-4">
      <div class="flex items-center gap-2">
        <span class="font-mono text-2xs tracking-widest uppercase text-ink-400">brick</span>
        <span class="font-mono text-xs text-ink-100">{eth(0.0005)}</span>
      </div>
      <div class="flex items-center gap-2 pl-4 border-l border-ink-600/60">
        <span class="font-mono text-2xs tracking-widest uppercase text-ink-400">x banner</span>
        <span class="font-mono text-xs text-ink-100">30 bricks · {eth(0.015)}</span>
      </div>
    </div>

    <!-- Right: controls -->
    <div class="flex items-center gap-3 font-mono text-2xs tracking-wider uppercase text-ink-500">
      <span class="hidden sm:inline">scroll = zoom</span>
      <span class="hidden sm:inline text-ink-700">·</span>
      <span class="hidden sm:inline">drag = pan</span>
      <span class="hidden sm:inline text-ink-700">·</span>
      <span>click = brick</span>
    </div>
  </div>
</footer>
