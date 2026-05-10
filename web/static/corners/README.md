# Corner brand artwork

Drop 4 PNGs here at exactly **160 × 160 px** (10 brick cells × 16 px each):

| File | Corner | Brand |
|------|--------|-------|
| `eth.png`  | top-left     | Ethereum |
| `x.png`    | top-right    | X (Twitter) |
| `base.png` | bottom-left  | Base chain |
| `uni.png`  | bottom-right | Uniswap |

The Wall renderer auto-loads each on mount via Pixi's `Assets.load`. If any file is missing, the solid brand tint stays visible underneath. Adding a new file = appears next page refresh, with a fade-in transition.

## Style guide

- 160 × 160 PNG, transparent background or matching dark base (`#1a1410`)
- Logo occupies a clear 10 × 10 cell grid (each cell = 16 px), pixel-aligned to the brick mortar
- Crisp pixel edges, no anti-aliasing across cells
- One brand-recognizable silhouette per corner — readable at full zoom-out (one cell ≈ 1px)
