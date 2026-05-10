<script lang="ts">
  import Wall from '$lib/components/Wall.svelte';

  let mintedCount = $state(0);
  let connected = $state(false);
  let highlightOwned = $state(false);
</script>

<svelte:head>
  <title>basewall — 10,000 bricks. one wall. forever.</title>
</svelte:head>

<header class="absolute top-0 left-0 right-0 z-10 flex items-center justify-between px-6 py-4 bg-gradient-to-b from-black/80 to-transparent">
  <div class="flex items-center gap-3">
    <span class="font-mono text-xl font-bold tracking-tight">🧱 basewall</span>
    <span class="font-mono text-sm text-white/60">{mintedCount} / 9,500 minted</span>
  </div>

  <div class="flex items-center gap-3">
    {#if connected}
      <button
        class="px-3 py-1.5 text-sm font-mono border border-wall-highlight/50 hover:bg-wall-highlight/10 rounded transition"
        onclick={() => (highlightOwned = !highlightOwned)}
      >
        {highlightOwned ? '🔦 hiding mine' : '🔦 highlight mine'}
      </button>
    {/if}
    <button
      class="px-4 py-1.5 text-sm font-mono bg-wall-accent hover:bg-wall-accent/90 rounded transition"
      onclick={() => (connected = !connected)}
    >
      {connected ? '0xCAFE…BEEF' : 'connect wallet'}
    </button>
    <button class="px-4 py-1.5 text-sm font-mono bg-wall-highlight text-black hover:bg-wall-highlight/90 rounded transition">
      mint a brick
    </button>
  </div>
</header>

<main class="w-screen h-screen overflow-hidden">
  <Wall {highlightOwned} />
</main>

<footer class="absolute bottom-0 left-0 right-0 z-10 px-6 py-3 flex justify-between items-center font-mono text-xs text-white/40 bg-gradient-to-t from-black/60 to-transparent">
  <span>0.001 ETH per brick · max 100/wallet · base mainnet</span>
  <span>scroll to zoom · drag to pan</span>
</footer>
