/**
 * Wall state — Svelte 5 runes-based reactive store
 * Tracks: mint count, supply, viewport, hover, selection, wallet state.
 * Stub data for MVP; wires to indexer Day 5+.
 */

export type BrickState = {
  id: number;            // 1..10000
  x: number;             // 0..124
  y: number;             // 0..79
  ownerAddress: string | null;
  contentURI: string | null;
  zone: 'public' | 'corner-eth' | 'corner-x' | 'corner-base' | 'corner-uni';
  mintedAt: number | null;
};

export type WalletState = {
  connected: boolean;
  address: string | null;
  ensName: string | null;
  ownedBrickIds: number[];
};

// Grid is 125 wide × 80 tall (1.56:1). Only reserve: 4 corners (10×10 each).
export const GRID_W = 125;
export const GRID_H = 80;

function classifyZone(x: number, y: number): BrickState['zone'] {
  if (x < 10 && y < 10) return 'corner-eth';
  if (x >= GRID_W - 10 && y < 10) return 'corner-x';
  if (x < 10 && y >= GRID_H - 10) return 'corner-base';
  if (x >= GRID_W - 10 && y >= GRID_H - 10) return 'corner-uni';
  return 'public';
}

class WallStore {
  // Stats
  publicMinted = $state(0);
  freeMinted = $state(0);
  totalSupply = 10000;
  publicSupply = 9600;
  freePhaseSupply = 1000;
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

  // Camera command bus — page sends imperative commands to Wall.svelte's viewport
  // Each command must have a fresh timestamp to re-trigger $effect
  cameraCommand = $state<{ action: 'in' | 'out' | 'reset' | 'fit-to-me'; ts: number } | null>(null);

  // Tooltip suppression (used when hero/modal is up)
  tooltipMuted = $state(false);

  // Camera state for minimap
  viewportRect = $state({ x: 0, y: 0, w: 0, h: 0 });

  // Get classification for a brick (pure)
  getZone(x: number, y: number) {
    return classifyZone(x, y);
  }

  // Stub: simulate live mints for design demo
  startDemoFeed() {
    if (typeof window === 'undefined') return;
    setInterval(() => {
      const id = Math.floor(Math.random() * 9600) + 1;
      const minter = '0x' + Math.random().toString(16).slice(2, 6) + '…' + Math.random().toString(16).slice(2, 6);
      this.mintFeed = [{ id, minter, timestamp: Date.now() }, ...this.mintFeed.slice(0, 9)];
      this.publicMinted = Math.min(this.publicSupply, this.publicMinted + 1);
    }, 2800);
  }

  toggleHighlight() {
    this.highlightOwned = !this.highlightOwned;
  }

  zoomIn() { this.cameraCommand = { action: 'in', ts: Date.now() }; }
  zoomOut() { this.cameraCommand = { action: 'out', ts: Date.now() }; }
  resetView() { this.cameraCommand = { action: 'reset', ts: Date.now() }; }
  flyToMine() { this.cameraCommand = { action: 'fit-to-me', ts: Date.now() }; }

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
