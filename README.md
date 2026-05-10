# basewall ($WALL)

The onchain billboard memecoin on Base. 10,000 bricks. One giant wall. Mutable forever.

**Domain**: basewall.fun (pending purchase)
**Chain**: Base mainnet (deploy target), Base Sepolia (testnet)
**Status**: pre-build (PRD locked)

## Structure

```
basewall/
├── contracts/      Foundry project — Brick NFT, $WALL token, v4 hook
├── web/            SvelteKit + Pixi.js frontend (the wall renderer)
└── docs/           PRD, build log, deployment notes
```

## Tokenomics (locked)

| Item | Value |
|---|---|
| Total bricks | 10,000 (100×100 grid) |
| Public mint | 9,500 @ 0.001 ETH (FCFS, 100/wallet cap) |
| Dev reserve | 500 (center 20×25 block) |
| $WALL supply | 1,000,000,000 |
| Mint reward | 50,000 $WALL airdropped per public brick |
| Total swap tax | 5% (2% dev / 1% brick owners / 2% LP auto-compound) |
| Fee distribution | By brick count, NOT activity state |

## Build plan (17 days)

See `docs/BUILD-PLAN.md` (TBD).

## Quick start

```bash
# Contracts
cd contracts
forge install
forge build
forge test

# Frontend
cd web
npm install
npm run dev
```
