<script lang="ts">
  import { wall } from '$lib/stores/wall.svelte';
  import { eth, compact } from '$lib/utils/formatters';

  let { dismiss }: { dismiss: () => void } = $props();

  const fillPct = $derived(((wall.publicMinted / wall.publicSupply) * 100).toFixed(1));
</script>

<div class="fixed inset-0 z-20 flex items-center justify-center pointer-events-none">
  <!-- Backdrop fade -->
  <div class="absolute inset-0 bg-gradient-radial from-ink-950/0 via-ink-950/40 to-ink-950/85 pointer-events-auto"
       role="presentation"
       onclick={dismiss}
       onkeydown={(e) => e.key === 'Escape' && dismiss()}></div>

  <!-- Content -->
  <div class="relative pointer-events-auto max-w-2xl px-8 text-center animate-fade-up">
    <div class="inline-flex items-center gap-2 px-3 py-1 mb-6 rounded-full bg-ink-800/80 border border-accent-gold/20">
      <span class="w-1.5 h-1.5 rounded-full bg-accent-gold animate-pulse"></span>
      <span class="font-mono text-2xs tracking-widest uppercase text-accent-gold">live on base</span>
    </div>

    <h1 class="font-display text-5xl sm:text-7xl font-bold tracking-tight leading-[0.95] mb-5">
      <span class="text-ink-50">10,000 bricks.</span><br />
      <span class="text-accent-gold">one wall.</span>
      <span class="text-ink-300">forever.</span>
    </h1>

    <p class="font-sans text-base sm:text-lg text-ink-200 max-w-xl mx-auto mb-8 leading-relaxed">
      Mint a brick for <span class="text-accent-gold font-medium">{eth(0.001)}</span>.
      Attach any image, text, or link.
      Earn from every <span class="font-mono text-ink-50">$WALL</span> swap — forever.
    </p>

    <div class="flex items-center justify-center gap-3 mb-10">
      <button
        class="btn-primary px-6 py-3 text-base"
        onclick={dismiss}
      >
        explore the wall →
      </button>
      <button class="btn-ghost px-5 py-2.5 text-sm">
        mint now
      </button>
    </div>

    <!-- Stats strip -->
    <div class="flex items-center justify-center gap-6 sm:gap-10 font-mono text-2xs tracking-widest uppercase text-ink-400">
      <div class="flex flex-col items-center gap-0.5">
        <span class="text-ink-50 text-lg font-bold normal-case tracking-tight">{compact(wall.publicMinted)}</span>
        <span>minted</span>
      </div>
      <div class="w-px h-8 bg-ink-700"></div>
      <div class="flex flex-col items-center gap-0.5">
        <span class="text-accent-gold text-lg font-bold normal-case tracking-tight">{fillPct}%</span>
        <span>filled</span>
      </div>
      <div class="w-px h-8 bg-ink-700"></div>
      <div class="flex flex-col items-center gap-0.5">
        <span class="text-accent-base text-lg font-bold normal-case tracking-tight">{compact(wall.publicSupply - wall.publicMinted)}</span>
        <span>remaining</span>
      </div>
    </div>

    <p class="mt-10 font-mono text-2xs tracking-wider text-ink-500">
      click anywhere to dismiss · esc
    </p>
  </div>
</div>

<style>
  .bg-gradient-radial {
    background: radial-gradient(ellipse at center, transparent 0%, rgba(10, 8, 5, 0.45) 50%, rgba(10, 8, 5, 0.92) 100%);
  }
</style>
