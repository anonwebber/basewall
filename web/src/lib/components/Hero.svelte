<script lang="ts">
  import { wall } from '$lib/stores/wall.svelte';
  import { eth, compact } from '$lib/utils/formatters';

  let { dismiss }: { dismiss: () => void } = $props();

  const fillPct = $derived(((wall.publicMinted / wall.publicSupply) * 100).toFixed(2));
</script>

<div class="fixed inset-0 z-20 flex items-center justify-center pointer-events-none">
  <!-- Backdrop fade -->
  <div
    class="absolute inset-0 hero-backdrop pointer-events-auto"
    role="presentation"
    onclick={dismiss}
    onkeydown={(e) => e.key === 'Escape' && dismiss()}
  ></div>

  <!-- Content -->
  <div class="relative pointer-events-auto max-w-3xl px-8 text-center animate-fade-up">
    <!-- Live pill -->
    <div class="inline-flex items-center gap-2 px-3 py-1 mb-8 rounded-full
                bg-ink-900/80 border border-accent-base/30 backdrop-blur-sm">
      <span class="relative flex items-center">
        <span class="absolute w-2 h-2 rounded-full bg-accent-base animate-ping opacity-75"></span>
        <span class="relative w-1.5 h-1.5 rounded-full bg-accent-base-glow"></span>
      </span>
      <span class="font-mono text-2xs tracking-widest uppercase text-accent-base-glow">live on base</span>
    </div>

    <!-- Headline -->
    <h1 class="font-display font-bold tracking-[-0.02em] leading-[0.92] mb-6
               text-[clamp(2.8rem,8vw,6.5rem)]">
      <span class="block text-ink-50">10,000 bricks.</span>
      <span class="block text-accent-cream">one wall.</span>
      <span class="block text-ink-300/80 italic font-normal">forever.</span>
    </h1>

    <!-- Sub -->
    <p class="font-sans text-lg sm:text-xl text-ink-200 max-w-xl mx-auto mb-10 leading-relaxed">
      Mint a brick for <span class="text-accent-cream font-semibold">{eth(0.0005)}</span>.
      Attach any image, text, or link.
      Rent it out as ad space — keep <span class="text-accent-cream">90%</span> of the income.
    </p>

    <!-- CTAs -->
    <div class="flex items-center justify-center gap-3 mb-12">
      <button class="btn-primary px-7 py-3.5 text-base font-semibold" onclick={dismiss}>
        explore the wall →
      </button>
      <button class="btn-connect px-6 py-3 text-sm">
        mint now
      </button>
    </div>

    <!-- Stats strip -->
    <div class="flex items-center justify-center gap-8 sm:gap-12 font-mono text-2xs tracking-widest uppercase text-ink-400">
      <div class="flex flex-col items-center gap-1">
        <span class="text-ink-50 text-xl font-bold normal-case tracking-tight">{compact(wall.publicMinted)}</span>
        <span>minted</span>
      </div>
      <div class="w-px h-9 bg-gradient-to-b from-transparent via-ink-600 to-transparent"></div>
      <div class="flex flex-col items-center gap-1">
        <span class="text-accent-cream text-xl font-bold normal-case tracking-tight">{fillPct}%</span>
        <span>filled</span>
      </div>
      <div class="w-px h-9 bg-gradient-to-b from-transparent via-ink-600 to-transparent"></div>
      <div class="flex flex-col items-center gap-1">
        <span class="text-accent-base-glow text-xl font-bold normal-case tracking-tight">{compact(wall.publicSupply - wall.publicMinted)}</span>
        <span>remaining</span>
      </div>
    </div>

    <p class="mt-12 font-mono text-2xs tracking-wider text-ink-500/80">
      click anywhere to dismiss · esc
    </p>
  </div>
</div>

<style>
  .hero-backdrop {
    background:
      radial-gradient(ellipse 900px 700px at center, transparent 0%, rgba(10, 8, 5, 0.55) 50%, rgba(10, 8, 5, 0.94) 100%);
  }
</style>
