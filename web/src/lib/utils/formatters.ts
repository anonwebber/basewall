/** Address shorten: 0xCAFE…BEEF */
export function shortAddress(addr: string, head = 4, tail = 4): string {
  if (!addr) return '';
  if (addr.length <= head + tail + 2) return addr;
  return `${addr.slice(0, 2 + head)}…${addr.slice(-tail)}`;
}

/** Compact number: 9100 -> 9.1K, 1234567 -> 1.23M */
export function compact(n: number, digits = 2): string {
  if (n < 1000) return n.toString();
  if (n < 1_000_000) return `${(n / 1000).toFixed(digits).replace(/\.?0+$/, '')}K`;
  if (n < 1_000_000_000) return `${(n / 1_000_000).toFixed(digits).replace(/\.?0+$/, '')}M`;
  return `${(n / 1_000_000_000).toFixed(digits).replace(/\.?0+$/, '')}B`;
}

/** ETH amount: 0.001 → "0.001 ETH" */
export function eth(n: number, digits = 4): string {
  return `${n.toFixed(digits).replace(/\.?0+$/, '')} ETH`;
}

/** USD: 1234.56 → "$1.2K" */
export function usd(n: number): string {
  if (n < 1) return `$${n.toFixed(2)}`;
  if (n < 1000) return `$${n.toFixed(0)}`;
  if (n < 1_000_000) return `$${(n / 1000).toFixed(1).replace(/\.0$/, '')}K`;
  return `$${(n / 1_000_000).toFixed(2).replace(/\.?0+$/, '')}M`;
}

/** Relative time: "23s ago" */
export function timeAgo(ts: number): string {
  const s = Math.floor((Date.now() - ts) / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

/** Brick coords from id (1-indexed) → "(x,y)" on the 125×80 grid */
const GRID_W = 125;
export function brickCoords(id: number): string {
  const idx = id - 1;
  return `(${idx % GRID_W},${Math.floor(idx / GRID_W)})`;
}
