<script lang="ts">
  import Logo from './Logo.svelte';
  import { wall } from '$lib/stores/wall.svelte';
  import { shortAddress, compact } from '$lib/utils/formatters';

  const fillPercent = $derived(((wall.publicMinted / wall.publicSupply) * 100).toFixed(1));
</script>

<header class="fixed top-0 left-0 right-0 z-30 px-5 sm:px-7 pt-4">
  <div class="glass-strong rounded-xl px-4 py-2.5 flex items-center justify-between gap-4 shadow-panel">
    <!-- Left: brand + live counter -->
    <div class="flex items-center gap-5">
      <Logo size={26} />

      <div class="hidden sm:flex items-center gap-3 pl-4 border-l border-ink-600/60">
        <div class="ticker-dot"></div>
        <div class="flex flex-col leading-tight">
          <span class="font-mono text-2xs tracking-widest uppercase text-ink-400">minted</span>
          <span class="font-mono text-sm text-ink-50">
            <span class="text-accent-cream">{compact(wall.publicMinted)}</span>
            <span class="text-ink-400"> / {compact(wall.publicSupply)}</span>
            <span class="text-ink-500 text-2xs ml-1">{fillPercent}%</span>
          </span>
        </div>
      </div>

      <div class="hidden lg:flex items-center gap-2 pl-4 border-l border-ink-600/60">
        <span class="font-mono text-2xs tracking-widest uppercase text-ink-400">on</span>
        <span class="font-mono text-xs text-accent-base">base</span>
      </div>
    </div>

    <!-- Right: actions -->
    <div class="flex items-center gap-2">
      {#if wall.wallet.connected}
        <button
          class="btn-ghost"
          class:!border-accent-cream={wall.highlightOwned}
          class:!text-accent-cream={wall.highlightOwned}
          onclick={() => wall.toggleHighlight()}
          aria-pressed={wall.highlightOwned}
        >
          {wall.highlightOwned ? '◉ hiding' : '○ mine'}
        </button>

        <div class="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-ink-800/60 rounded-md font-mono text-xs">
          <span class="w-1.5 h-1.5 rounded-full bg-accent-mint"></span>
          <span class="text-ink-100">{shortAddress(wall.wallet.address ?? '')}</span>
          <span class="text-ink-400">·</span>
          <span class="text-accent-cream">{wall.wallet.ownedBrickIds.length}</span>
        </div>
      {:else}
        <button
          class="btn-connect"
          onclick={() => wall.connectWallet('0xC0FFEE000000000000000000000000000000BEEF')}
        >
          connect
        </button>
      {/if}

      <button class="btn-primary">
        mint a brick
      </button>
    </div>
  </div>
</header>
