# basewall — PRD v2.0 (NFT-only)

**Status**: locked, pre-build
**Date locked**: 2026-05-17 (pivot from v1.0 token-economy spec)
**Domain**: `basewall.fun` (pending purchase), `xwall.fun` (alias)
**Chain**: Base (mainnet); Base Sepolia for testnet

---

## 1. Concept

10,000-brick onchain billboard on Base (**125 × 80 grid, 1.56:1 ratio**). Each brick is an NFT with mutable image/text/link content. Brick owners can rent their brick to advertisers as ad space — owner keeps 90%, treasury takes 10%. **No token. No hook. No LP.** The wall IS the product.

Million Dollar Homepage, but mutable, rentable, and onchain forever.

### Why NFT-only?

Cut ~70% of build complexity (Uniswap v4 hook, $WALL token, LP seed, UNCX lock, hook peer review). Ship in ~7 days instead of 17. Rental marketplace replaces swap-fee accumulator as the recurring-revenue mechanism — tied directly to actual wall usage, not memecoin volume.

---

## 2. Supply (LOCKED)

| Zone | Count | Price | Cap | Notes |
|---|---|---|---|---|
| **Corner reserves** (4 × 10×10) | 400 | — | — | Treasury holds, ETH/X/Base/Uniswap brand homages |
| **Free phase** | 1,000 | 0 ETH | 1 per wallet | Wallet-quality gated, stealth-launched (no marketing) |
| **Paid phase** | 8,600 | 0.0005 ETH | 100 per wallet | Random allocation via committed seed |
| **Total** | 10,000 | — | — | |

- **Banner cluster mint**: 10×3 contiguous = 30 bricks at flat `30 × mintPrice` = **0.015 ETH (~$45)**. Matches X-banner 3:1 ratio. Cluster start cell chosen by caller, contract validates non-overlap with corners + availability.
- **5% royalty** on secondary → treasury (ERC-2981)
- **IPFS storage** (Pinata free tier for MVP)

---

## 3. Rental Marketplace

Brick owners can list their brick for monthly rent. Advertisers pay upfront for N months, content rotates to advertiser-supplied URI for the rental term.

| Param | Value |
|---|---|
| Treasury cut | 10% (default) |
| Treasury cut cap | 20% (owner-tunable via `setTreasuryRentBps`, hard-coded ceiling) |
| Minimum rental term | Per-listing, set by brick owner (`minMonths`) |
| Mid-rental cancel | None (locked for the term both parties agreed to) |
| Owner content lock | Owner CAN'T `updateContent` mid-rental (advertiser is paying for that screen-time) |
| Rental survives transfer | Yes — new brick owner inherits the active rental and future income credits |
| Earnings model | Pull (claimable via `withdrawRentalEarnings()`) |

**Content moderation**: frontend filter only. Contract stays immutable; chain data is permanent. Our UI hides flagged content but never censors the chain.

---

## 4. Free-phase Stealth Launch

The first 1,000 bricks are free, but:

1. **Wallet-quality gate**: caller must be EOA (`code.length == 0`), `tx.origin == msg.sender` (kills router-wrapped sybils), balance ≥ 0.01 ETH. Sybil-expensive, not sybil-proof — combined with 1-per-wallet mapping.
2. **No marketing channel** until the free phase mints out. No `@basewall` Twitter, no website link in the wild.
3. **Website URL is gated in the contract**: `websiteURL()` reverts with `WebsiteNotRevealed` until the 1,000th free mint. `WebsiteRevealed(url)` event fires on the 1,000th mint, signaling to indexers that the paid phase + marketing channel is opening.
4. **Free bricks get NO post-mint reward** beyond the brick itself. (No token to airdrop.) Justifies asymmetry vs paid bricks.
5. **Fallback**: if free phase doesn't mint out organically, owner can call `setWebsiteURL` later to manually trigger reveal (the reveal event fires once free phase reaches 1k OR when owner sets URL after, whichever comes first).

This is the "found it" launch — Base contract-scanners and CT degens are the first audience. Free brick + cult narrative = 1,000 organic shillers before any tweet.

---

## 5. Day-1 Math

| Item | Amount |
|---|---|
| Free phase | 1,000 × 0 = 0 ETH |
| Paid phase | 8,600 × 0.0005 = **4.3 ETH** (~$12.9k @ $3k ETH) |
| Banner clusters (subset of paid) | depends on demand |
| LP commit | **0 ETH** (no token, no LP) |
| **Net treasury day 1** | **~4.3 ETH** (~$12.9k) |
| Corner reserve held | 400 bricks (treasury upside) |

---

## 6. Revenue Streams (4)

1. **Brick mint** (~4.3 ETH one-time)
2. **Rental marketplace** — 10% cut on every brick-rental payment (recurring, tied to actual wall usage)
3. **Sponsored corner-cluster rentals** — brands rent adjacent bricks from our 400-brick corner reserve at premium rates
4. **5% secondary royalty** on brick resales (recurring, EIP-2981)

---

## 7. Tech Stack

| Layer | Choice |
|---|---|
| Contract | Solidity 0.8.26 + Foundry 1.5.1 |
| Standards | ERC-721 + ERC-2981 (royalty) |
| Storage | Pinata (IPFS) |
| Frontend | SvelteKit 2 + Svelte 5 (runes) + TypeScript strict |
| Renderer | Pixi.js v8 (GPU-accelerated, 10k sprites) |
| Styling | Tailwind 3 |
| Wallet | viem + wagmi/AppKit (TBD Day 3) |
| Indexer | Node + viem + Base RPC (Alchemy free) → Supabase |
| Deploy | Vercel + Base mainnet |

---

## 8. Build Plan (7 Days)

| Day | Contracts | Frontend/infra |
|---|---|---|
| 1 | ✅ Brick.sol full rewrite (free + paid + cluster + rentals + reveal) | ✅ Wall renderer, store, chrome (all in place) |
| 2 | Tests: bring suite to ~25 tests covering all paths + Foundry fuzz on rental math | Wallet connect (viem + wagmi-svelte or AppKit decision) |
| 3 | Deploy to Base Sepolia + smoke test all mint paths | Mint UI (free + paid + banner cluster) wired to testnet |
| 4 | Lite peer review prep (~$500 — much smaller surface than v1) | Rental flow UI (list/rent/end) + IPFS upload (Pinata) |
| 5 | Mainnet fork tests + final patches | Indexer: brick ownership + content + rental events → Supabase |
| 6 | Mainnet contract deploy + `mintCornerReserves()` | Switch frontend to mainnet, soft launch with friends |
| 7 | LAUNCH — contract deploys with empty `websiteURL`; community finds it via Base scanner | The 1,000 free mints out; `WebsiteRevealed` fires; we tweet |

---

## 9. All-In Cost

- Domain `basewall.fun` + `xwall.fun`: ~$16/yr total
- Pinata: $0 (free tier)
- Vercel + Supabase: $0 (free tier)
- Alchemy Base RPC: $0 (free tier)
- Lite peer review: ~$500 (smaller surface — no hook math)
- Base deploy gas: ~$20 (Brick + corner-reserve mint of 400)
- **Total: ~$540** (vs $4,500 + 1 ETH in v1)

---

## 10. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Free phase sniped by bots | Wallet-quality gate (EOA only, min balance, no router wrap) raises sybil cost; 1-per-wallet mapping. Real defense = no marketing channel until 1k done, so bots can't shill. |
| Free phase never mints out | Owner can manually `setWebsiteURL` to trigger reveal at any point, opening paid phase regardless of free progress. |
| Rental advertiser puts illegal/NSFW content onchain | Frontend filter only (chain stays clean ideologically). No on-contract void/ban — keeps trust-minimization intact. Could revisit if a real incident forces our hand. |
| Cluster mint griefing (someone reserves a key 10×3 spot to squat) | Acceptable — they paid 30× the price. Free market for prime real estate. |
| Wall doesn't fill | KOL airdrop from corner reserve (100 free corner bricks to mid-CT accounts, costs 0 ETH) + the cult-launch narrative + $1.50/brick floor (cheapest land in crypto). |
| ERC-2981 royalty ignored by marketplaces (Blur etc) | Accept it. Royalty is bonus, not load-bearing. Rental marketplace + brick sale carry the economics. |

---

## 11. What Got Cut From v1.0

- ❌ `$WALL` ERC-20 token (1B supply, all allocations)
- ❌ Uniswap v4 hook (`WallHook.sol`) with 5% swap tax
- ❌ Sushi-style fee accumulator + `claim()` flow
- ❌ 600M $WALL + 1 ETH LP seed
- ❌ UNCX 90-day LP lock
- ❌ Hook address CREATE2 mining
- ❌ 50,000 $WALL airdrop per public brick
- ❌ Center 25×20 reserve (500 bricks → returned to public supply)
- ❌ Day 5 mainnet fork hook tests; Day 14 LP seed; full v4 integration
- ❌ $1.5k full hook peer review (now ~$500 for the smaller contract)

---

## 12. Open Items Before Launch

- [ ] Buy `basewall.fun` + `xwall.fun` domains
- [ ] Generate corner brand art for ETH/X/Base/Uniswap homages (✅ already in `web/static/corners/`)
- [ ] Decide: wagmi-svelte vs AppKit for wallet UX (Day 3)
- [ ] Set up multisig for treasury (Safe on Base)
- [ ] Plan post-mint reward drops for early minters (cool-stuff TBD — possibilities: free banner cluster vouchers, retroactive corner-brick airdrop from reserve, advertiser referral bonuses)
- [ ] Pre-stage `@basewall` Twitter (don't activate until free phase mints out)
- [ ] Write a one-pager pitch for KOLs explaining the cult launch
