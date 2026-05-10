/**
 * Wall state — Svelte 5 runes-based reactive store
 * Tracks: mint count, supply, viewport, hover, selection, wallet state.
 * Stub data for MVP; wires to indexer Day 5+.
 */

export type BrickState = {
  id: number;            // 1..10000
  x: number;             // 0..99
  y: number;             // 0..99
  ownerAddress: string | null;
  contentURI: string | null;
  zone: 'public' | 'corner-eth' | 'corner-x' | 'corner-base' | 'corner-uni' | 'center-dev';
  mintedAt: number | null;
};

export type WalletState = {
  connected: boolean;
  address: string | null;
  ensName: string | null;
  ownedBrickIds: number[];
};

function classifyZone(x: number, y: number): BrickState['zone'] {
  if (x < 10 && y < 10) return 'corner-eth';
  if (x >= 90 && y < 10) return 'corner-x';
  if (x < 10 && y >= 90) return 'corner-base';
  if (x >= 90 && y >= 90) return 'corner-uni';
  if (x >= 40 && x < 60 && y >= 38 && y < 63) return 'center-dev';
  return 'public';
}

class WallStore {
  // Stats
  publicMinted = $state(0);
  totalSupply = 10000;
  publicSupply = 9100;
  bannerClustersMinted = $state(0);

  // Viewport (controlled by Wall.svelte)
  zoom = $state(1);
  focusBrick = $state<number | null>(null);

  // Hover/interaction
  hoveredBrick = $state<number | null>(null);
  selectedBricks = $state<Set<number>>(new Set());

  // Wallet
  wallet = $state<WalletState>({
    connected: false,
    address: null,
    ensName: null,
    ownedBrickIds: []
  });

  // Toggle: highlight my bricks
  highlightOwned = $state(false);

  // Live mint feed (recent N)
  mintFeed = $state<Array<{ id: number; minter: string; timestamp: number }>>([]);

  // Token price stub
  wallPriceUsd = $state(0.000007);
  volume24h = $state(0);

  // Get classification for a brick (pure)
  getZone(x: number, y: number) {
    return classifyZone(x, y);
  }

  // Stub: simulate live mints for design demo
  startDemoFeed() {
    if (typeof window === 'undefined') return;
    setInterval(() => {
      const id = Math.floor(Math.random() * 9100) + 1;
      const minter = '0x' + Math.random().toString(16).slice(2, 6) + '…' + Math.random().toString(16).slice(2, 6);
      this.mintFeed = [{ id, minter, timestamp: Date.now() }, ...this.mintFeed.slice(0, 9)];
      this.publicMinted = Math.min(this.publicSupply, this.publicMinted + 1);
    }, 2800);
  }

  toggleHighlight() {
    this.highlightOwned = !this.highlightOwned;
  }

  connectWallet(address: string) {
    this.wallet = {
      connected: true,
      address,
      ensName: null,
      ownedBrickIds: [42, 1337, 4201, 8003] // stub
    };
  }

  disconnectWallet() {
    this.wallet = { connected: false, address: null, ensName: null, ownedBrickIds: [] };
    this.highlightOwned = false;
  }
}

export const wall = new WallStore();
