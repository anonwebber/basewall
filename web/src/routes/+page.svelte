<script lang="ts">
  import { onMount } from 'svelte';
  import Wall from '$lib/components/Wall.svelte';
  import Header from '$lib/components/Header.svelte';
  import Footer from '$lib/components/Footer.svelte';
  import MintFeed from '$lib/components/MintFeed.svelte';
  import Hero from '$lib/components/Hero.svelte';
  import ZoomControls from '$lib/components/ZoomControls.svelte';
  import Minimap from '$lib/components/Minimap.svelte';
  import { wall } from '$lib/stores/wall.svelte';

  let showHero = $state(true);
  let selectedBrick = $state<number | null>(null);

  onMount(() => {
    // Start the demo mint feed
    wall.startDemoFeed();
    // Auto-dismiss hero after first interaction or 8s
    const t = setTimeout(() => (showHero = false), 8000);
    return () => clearTimeout(t);
  });

  // Suppress the brick tooltip whenever an overlay is up
  $effect(() => {
    wall.tooltipMuted = showHero || selectedBrick !== null;
  });

  function handleBrickClick(id: number) {
    selectedBrick = id;
    showHero = false;
  }
</script>

<svelte:head>
  <title>basewall — 10,000 bricks. one wall. forever.</title>
  <meta name="description" content="The onchain billboard on Base. Mint a brick for 0.0005 ETH, attach anything, rent it out as ad space and keep 90% of the income." />
</svelte:head>

<main class="fixed inset-0 overflow-hidden">
  <Wall onBrickClick={handleBrickClick} />

  <Header />
  <MintFeed />
  <ZoomControls />
  <Minimap />
  <Footer />

  {#if showHero}
    <Hero dismiss={() => (showHero = false)} />
  {/if}

  {#if selectedBrick !== null}
    <div class="fixed inset-0 z-30 flex items-center justify-center pointer-events-none">
      <div
        class="absolute inset-0 bg-ink-950/70 pointer-events-auto animate-fade-up"
        role="presentation"
        onclick={() => (selectedBrick = null)}
        onkeydown={(e) => e.key === 'Escape' && (selectedBrick = null)}
      ></div>
      <div class="relative pointer-events-auto glass-strong rounded-2xl p-6 w-full max-w-md shadow-panel animate-fade-up">
        <div class="flex items-center justify-between mb-4">
          <div>
            <div class="font-mono text-2xs tracking-widest uppercase text-ink-400 mb-1">brick</div>
            <h2 class="font-display text-3xl font-bold text-ink-50">#{selectedBrick}</h2>
          </div>
          <button
            onclick={() => (selectedBrick = null)}
            class="font-mono text-2xs text-ink-400 hover:text-accent-cream transition"
            aria-label="close"
          >
            ✕ esc
          </button>
        </div>

        <div class="aspect-square w-full bg-ink-900 rounded-lg border border-ink-700 mb-4
                    flex items-center justify-center">
          <span class="font-mono text-sm text-ink-500">unminted</span>
        </div>

        <div class="grid grid-cols-2 gap-3 mb-4 font-mono text-xs">
          <div class="px-3 py-2 bg-ink-900/60 rounded-md">
            <div class="text-2xs text-ink-500 uppercase tracking-wider mb-0.5">position</div>
            <div class="text-ink-100">
              ({(selectedBrick - 1) % 125},{Math.floor((selectedBrick - 1) / 125)})
            </div>
          </div>
          <div class="px-3 py-2 bg-ink-900/60 rounded-md">
            <div class="text-2xs text-ink-500 uppercase tracking-wider mb-0.5">price</div>
            <div class="text-accent-cream">0.0005 ETH</div>
          </div>
        </div>

        <button class="btn-primary w-full py-3">claim this brick →</button>
      </div>
    </div>
  {/if}
</main>
