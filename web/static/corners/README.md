# Corner brand artwork

Drop **any normal image** here — the wall slices it into 100 sub-tiles (10×10 brick grid) and applies one tile to each brick of that corner.

This is the SAME pipeline that handles user-uploaded X banners (30×10 clusters) and any other multi-brick cluster — the corners just happen to be 10×10.

| File | Corner | Brand |
|------|--------|-------|
| `eth.png`  | top-left     | Ethereum |
| `x.png`    | top-right    | X (Twitter) |
| `base.png` | bottom-left  | Base chain |
| `uni.png`  | bottom-right | Uniswap |

## How the image renders

- Any size, any aspect ratio works
- Non-square images are **cover-fit** to a square (center-cropped)
- Transparent areas (PNG alpha) fall onto a dark warm-black `#1a1410` background — so logos with transparency show on dark, not on neon corner tints
- The image fades in on load with no rebuild needed; just refresh the page

Missing files = the solid corner tints stay visible (no broken image).
