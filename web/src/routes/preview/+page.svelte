<script lang="ts">
  type Layout = {
    name: string;
    ratio: string;
    w: number;
    h: number;
    cornerSize: { w: number; h: number };
    bannerExample: { x: number; y: number };
    notes: string;
    vibe: string;
  };

  // X banner cluster is always 30×10 bricks (matches 1500×500 = 3:1 X banner)
  const BANNER_W = 30;
  const BANNER_H = 10;

  const layouts: Layout[] = [
    {
      name: '200 × 50',
      ratio: '4:1',
      w: 200,
      h: 50,
      cornerSize: { w: 10, h: 10 },
      bannerExample: { x: 60, y: 20 },
      vibe: 'highway billboard · bold horizontal',
      notes: 'Exactly 10,000 · 400 corners reserved · 9,600 public'
    },
    {
      name: '175 × 57',
      ratio: '3.07:1',
      w: 175,
      h: 57,
      cornerSize: { w: 10, h: 10 },
      bannerExample: { x: 50, y: 24 },
      vibe: 'X banner ratio · twin-shape with banners',
      notes: '9,975 bricks · same shape as X-banner clusters'
    },
    {
      name: '150 × 66',
      ratio: '2.27:1',
      w: 150,
      h: 66,
      cornerSize: { w: 10, h: 10 },
      bannerExample: { x: 40, y: 28 },
      vibe: 'subtle rectangle · classroom wall',
      notes: '9,900 bricks · less extreme, still rectangular'
    },
    {
      name: '125 × 80',
      ratio: '1.56:1',
      w: 125,
      h: 80,
      cornerSize: { w: 10, h: 10 },
      bannerExample: { x: 35, y: 35 },
      vibe: 'screen-shaped · cinema · LOCKED',
      notes: 'Exactly 10,000 · 400 corners reserved · 9,600 public'
    }
  ];

  // Visual scale: each card has fixed visual width
  const CARD_W = 640;
  function px(l: Layout, val: number, axis: 'x' | 'y' = 'x') {
    // Always scale by width so wider layouts look wider
    return (val / 200) * CARD_W;
  }

  function brickCount(l: Layout) {
    return l.w * l.h;
  }
  function publicCount(l: Layout) {
    return brickCount(l) - 4 * l.cornerSize.w * l.cornerSize.h;
  }
</script>

<svelte:head>
  <title>basewall · layout preview</title>
</svelte:head>

<main class="min-h-screen px-6 sm:px-10 py-12">
  <div class="max-w-5xl mx-auto">
    <a href="/" class="font-mono text-2xs tracking-wider text-ink-400 hover:text-accent-cream">← back to wall</a>

    <header class="mt-6 mb-12">
      <h1 class="font-display text-5xl font-bold text-ink-50 mb-3">layout preview</h1>
      <p class="text-ink-300 max-w-2xl text-lg">
        Four candidate wall ratios. Each schematic shows: 4 corner reserves (tinted),
        and one example X-banner cluster (cream outline) to scale. <strong class="text-accent-cream">125×80 is locked</strong>.
      </p>
    </header>

    <div class="space-y-8">
      {#each layouts as l, i}
        <article class="glass-strong rounded-2xl p-5 shadow-panel">
          <div class="flex flex-wrap items-baseline justify-between gap-3 mb-4">
            <div>
              <div class="font-mono text-2xs tracking-widest uppercase text-ink-400 mb-1">option {i + 1}</div>
              <h2 class="font-display text-3xl font-bold">
                <span class="text-ink-50">{l.name}</span>
                <span class="text-accent-cream font-normal text-2xl ml-2">{l.ratio}</span>
              </h2>
              <p class="font-mono text-xs text-ink-300 mt-1">{l.vibe}</p>
            </div>
            <div class="font-mono text-xs text-right">
              <div class="text-ink-100">{brickCount(l).toLocaleString()} total</div>
              <div class="text-ink-400">{publicCount(l).toLocaleString()} public · 400 corners</div>
            </div>
          </div>

          <!-- Schematic -->
          <div class="relative bg-ink-950/60 border border-ink-700 rounded-lg overflow-hidden mx-auto"
               style="width: {CARD_W}px; aspect-ratio: {l.w} / {l.h};">
            <svg
              viewBox="0 0 {l.w} {l.h}"
              preserveAspectRatio="none"
              class="absolute inset-0 w-full h-full"
            >
              <!-- Subtle grid pattern -->
              <defs>
                <pattern id="grid-{i}" width="2" height="2" patternUnits="userSpaceOnUse">
                  <rect width="2" height="2" fill="#1f1813" />
                  <rect width="1" height="1" fill="#27201a" />
                  <rect x="1" y="1" width="1" height="1" fill="#27201a" />
                </pattern>
              </defs>
              <rect width={l.w} height={l.h} fill="url(#grid-{i})" />

              <!-- 4 corners -->
              <rect x="0" y="0" width={l.cornerSize.w} height={l.cornerSize.h} fill="#4a82ff" opacity="0.85" />
              <rect x={l.w - l.cornerSize.w} y="0" width={l.cornerSize.w} height={l.cornerSize.h} fill="#e0e0e0" opacity="0.85" />
              <rect x="0" y={l.h - l.cornerSize.h} width={l.cornerSize.w} height={l.cornerSize.h} fill="#0052ff" opacity="0.85" />
              <rect x={l.w - l.cornerSize.w} y={l.h - l.cornerSize.h} width={l.cornerSize.w} height={l.cornerSize.h} fill="#ff007a" opacity="0.85" />

              <!-- Example X-banner cluster (30×10) -->
              <rect
                x={l.bannerExample.x}
                y={l.bannerExample.y}
                width={BANNER_W}
                height={BANNER_H}
                fill="none"
                stroke="#f5efe6"
                stroke-width="0.4"
                stroke-dasharray="0.8 0.8"
              />
              <text
                x={l.bannerExample.x + BANNER_W / 2}
                y={l.bannerExample.y + BANNER_H / 2 + 1.5}
                font-family="JetBrains Mono, monospace"
                font-size="2.4"
                fill="#f5efe6"
                text-anchor="middle"
              >
                example X banner
              </text>

              <!-- Outer frame -->
              <rect width={l.w} height={l.h} fill="none" stroke="#f5efe6" stroke-width="0.3" stroke-opacity="0.4" />
            </svg>

            <!-- Corner labels -->
            <div class="absolute top-2 left-2 font-mono text-2xs text-white/80">ETH</div>
            <div class="absolute top-2 right-2 font-mono text-2xs text-black/80">X</div>
            <div class="absolute bottom-2 left-2 font-mono text-2xs text-white/80">BASE</div>
            <div class="absolute bottom-2 right-2 font-mono text-2xs text-white/80">UNI</div>
          </div>

          <p class="mt-3 font-mono text-2xs text-ink-400">{l.notes}</p>
        </article>
      {/each}
    </div>

    <div class="mt-10 glass rounded-xl p-5 shadow-panel">
      <h3 class="font-display text-lg font-bold text-ink-50 mb-2">how to pick</h3>
      <ul class="space-y-1.5 text-sm text-ink-200 list-disc list-inside marker:text-accent-cream">
        <li><strong class="text-ink-50">200×50 (4:1)</strong> — boldest billboard. The "I built a wall" energy. Wall is short and wide; tons of vertical screen space for hero/header/footer.</li>
        <li><strong class="text-ink-50">175×57 (3:1)</strong> — exact X-banner ratio. The whole wall IS a giant X banner. Banner clusters tile naturally.</li>
        <li><strong class="text-ink-50">150×66 (2.27:1)</strong> — middle ground. Rectangular but not extreme. Easier to render mobile-friendly.</li>
        <li><strong class="text-ink-50">125×80 (1.56:1)</strong> — barely rectangular. Closer to a window/monitor. Bricks stay roughly square in visual presence. <span class="text-accent-cream">LOCKED.</span></li>
      </ul>
    </div>
  </div>
</main>
