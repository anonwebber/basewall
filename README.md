# basewall

The onchain billboard on Base. 10,000 bricks. One giant wall. Mutable forever.

**Domain**: basewall.fun (pending purchase)
**Chain**: Base mainnet (deploy target), Base Sepolia (testnet)
**Status**: pre-build (PRD v2.0 — NFT-only, locked 2026-05-17)

## Structure

```
basewall/
├── contracts/      Foundry project — Brick NFT (ERC-721 + ERC-2981)
├── web/            SvelteKit + Pixi.js frontend (the wall renderer)
└── docs/           PRD, session logs
```

## Supply (locked)

| Zone | Count | Price | Cap |
|---|---|---|---|
| Corner reserves (4 × 10×10) | 400 | — | — |
| Free phase (wallet-quality gated, 1/wallet) | 1,000 | 0 ETH | 1 |
| Paid phase (random alloc, 100/wallet) | 8,600 | 0.0005 ETH | 100 |
| Banner cluster (10×3) | subset of paid | 0.015 ETH flat | — |
| **Total** | **10,000** | | |

- 5% secondary royalty → treasury (EIP-2981)
- Ad-rental marketplace: 90% to brick owner / 10% to treasury

See `docs/PRD.md` for the full spec.

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
