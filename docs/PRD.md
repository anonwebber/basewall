# basewall ($WALL) — PRD v1.0

**Status**: locked, pre-build
**Date locked**: 2026-05-10
**Domain**: `basewall.fun` (pending purchase)
**Chain**: Base (mainnet); Base Sepolia for testnet

---

## 1. Concept

10,000-brick onchain billboard on Base (**125 × 80 grid, 1.56:1 ratio**). Each brick is an NFT with mutable image/text/link content. A Uniswap v4 hook on the `$WALL` token routes 5% of every swap to dev / brick owners / LP — turning bricks into rent-yielding internet real estate.

Million Dollar Homepage + a v4 token economy + Base degen impulse pricing.

---

## 2. Tokenomics (LOCKED)

### Bricks (ERC-721)

| Zone | Count | Price | Cap | Mint | Owner |
|---|---|---|---|---|---|
| Public ring | 9,500 | 0.001 ETH flat | 100/wallet | FCFS | Buyers |
| Dev reserve — 4 corners (10×10 each) | 400 | — | — | Treasury holds, ETH/X/Base/Uniswap homages | Us |
| Dev reserve — center 25×20 block | 500 | — | — | Treasury holds, sold/auctioned later | Us |

- No lockup on dev bricks
- 5% royalty on secondary → treasury
- IPFS storage (Pinata free tier for MVP)

### $WALL (ERC-20)

| Bucket | Amount | Notes |
|---|---|---|
| Total supply | 1,000,000,000 | Fixed |
| LP seed | 600M | Paired with 1 ETH |
| Brick mint reward | 475M | 50,000 $WALL airdropped per public brick |
| Dev wallet | 50M (5%) | Vested 6 months |
| Marketing | 50M (5%) | |
| Burn at deploy | 25M (2.5%) | Sent to 0xdead |
| LP lock | 90 days | Via UNCX |

---

## 3. v4 Hook Fee Split (LOCKED)

**Total swap tax: 5%**

| Bucket | % | Destination |
|---|---|---|
| Dev fee | 2% | Multisig (in ETH) |
| Brick owner pool | 1% | Sushi-style accumulator, distributed by brick count (NOT activity state) |
| LP auto-compound | 2% | Re-injected into pool to deepen liquidity |

Architecture: pool LP fee tier 2% (standard Uniswap accrual) + hook surcharge 3% via `afterSwap` delta (2% to dev, 1% to brick pool).

Brick owners pull via `claim()` — Sushi-style accumulator. No looping over 9.5k owners per swap.

---

## 4. Day-1 Math

| Item | Amount |
|---|---|
| Public sale | 9,500 × 0.001 = **9.5 ETH** (~$28.5k) |
| LP commit | 1 ETH |
| **Net treasury day 1** | **~8.5 ETH** (~$25.5k) |
| Dev brick reserve | 500 (future ~25–250 ETH potential) |

---

## 5. Revenue Streams (5)

1. One-time brick sale (~9.5 ETH)
2. 2% dev fee on every $WALL swap (recurring, in ETH)
3. Center brick Dutch auctions (drip 10–50/month at variable prices)
4. Sponsored ad cluster rentals (brands rent adjacent bricks from our reserve, 0.5–2 ETH/cluster)
5. 5% secondary royalty on brick resales

---

## 6. Tech Stack

| Layer | Choice |
|---|---|
| Contracts | Solidity 0.8.26 + Foundry 1.5.1 |
| Hook | Uniswap v4 PoolManager + custom Hook |
| NFT | ERC-721 with onchain coords + IPFS metadata pointer |
| Storage | Pinata (IPFS) |
| Frontend | SvelteKit 2 + Svelte 5 (runes) + TypeScript strict |
| Renderer | **Pixi.js v8** (GPU-accelerated 2D, 10k sprites, smooth zoom) |
| Styling | Tailwind 3 |
| Wallet | viem + wagmi/AppKit (Day 6 decision) |
| Indexer | Node + viem + Base RPC (Alchemy free) → Supabase |
| Deploy | Vercel + Base mainnet |

---

## 7. Build Plan (17 Days, 2 Devs)

| Day | Dev 1 (contracts) | Dev 2 (frontend/infra) |
|---|---|---|
| 1 | ✅ Brick.sol skeleton + tests | ✅ Workspace scaffold + Pixi placeholder |
| 2 | WallToken.sol + dev mint flow | Brick mint UI + wallet connect (viem) |
| 3 | WallHook.sol — 5% split logic | Brick detail modal + content edit flow |
| 4 | Hook accrual + claim function + Foundry fuzz tests | IPFS upload pipeline (Pinata API) |
| 5 | Mainnet fork test on Base + LP setup script | Wallet highlight overlay (toggle pulse) |
| 6 | Deploy script + UNCX LP lock integration | Indexer: brick ownership + content sync to Supabase |
| 7 | Buffer/fix | "Fly to my bricks" + share-as-image |
| 8 | Deploy to Base Sepolia | Frontend wired to testnet |
| 9 | Buffer/fix | Multi-brick image slicing flow |
| 10 | Internal testing — 200 test bricks + swap simulations | Lasso-select + cluster preview |
| 11 | Lite peer review (~$1.5k) | UX polish, mobile, share-card generator |
| 12 | Buffer | Twitter share images per brick (auto-gen) |
| 13 | Mainnet contract deploy | Switch frontend to mainnet, soft launch with friends |
| 14 | LP seed + lock | Live mint feed + brick of the day rotator |
| 15 | Buffer / monitor | Sound design + final polish pass |
| 16 | KOL DMs / pre-launch | Tease site live, countdown |
| 17 | LAUNCH | LAUNCH |

---

## 8. All-In Cost

- Domain `basewall.fun`: ~$8/yr
- Pinata: $0 (free tier)
- Vercel + Supabase: $0 (free tier)
- Alchemy Base RPC: $0 (free tier)
- Lite peer review: $1,500
- LP seed: 1 ETH (~$3,000)
- Base deploy gas: ~$10
- **Total: ~$4,500 + 1 ETH**

---

## 9. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Wall doesn't fill | KOL pre-airdrop (50 free bricks) + $3 price + 0.05 ETH bounty for first community art collage |
| Spam/NSFW content | Frontend filter (illegal hidden, NSFW behind blur toggle); chain data unaffected |
| Sybil bricks (100/wallet cap is soft) | At $3 + gas, sybiling 1k bricks costs ~$3050 paid TO US. Net positive. |
| v4 hook bug | Foundry property tests + lite peer review pre-mainnet + cap max payout |
| Dev brick rug optics | Counter narrative: "no $WALL bag to dump, dev fee = ETH only" |
| IPFS Pinata pulls | Migrate to Arweave in v2; for MVP, Pinata is fine |

---

## 10. Open Items Before Launch

- [ ] Buy `basewall.fun` domain
- [ ] Generate Mascot/branding via Lovart
- [ ] Decide: Wagmi vs RainbowKit vs custom WalletConnect for connection UX (Day 6)
- [ ] Set up Twitter `@basewall` (or `@base_wall`) account
- [ ] Compose KOL DM list (target 50 mid-CT accounts for pre-launch airdrop)
- [ ] Set up multisig for treasury (Safe on Base)
