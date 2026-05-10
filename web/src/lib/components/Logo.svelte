<script lang="ts">
  let { size = 28, animated = true }: { size?: number; animated?: boolean } = $props();
</script>

<!-- A 4x2 brick stack — wordmark "basewall" pairs to the right -->
<div class="flex items-center gap-2.5" aria-label="basewall">
  <svg
    width={size}
    height={size}
    viewBox="0 0 32 32"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    class={animated ? 'logo-anim' : ''}
  >
    <!-- Row 1: 4 bricks staggered offset -->
    <rect x="1" y="6" width="7" height="8" rx="0.6" fill="#0052ff" />
    <rect x="9" y="6" width="7" height="8" rx="0.6" fill="#f5efe6" />
    <rect x="17" y="6" width="7" height="8" rx="0.6" fill="#4a82ff" />
    <rect x="25" y="6" width="6" height="8" rx="0.6" fill="#f5efe6" />

    <!-- Row 2: 4 bricks offset -->
    <rect x="-3" y="16" width="7" height="8" rx="0.6" fill="#4a82ff" />
    <rect x="5" y="16" width="7" height="8" rx="0.6" fill="#f5efe6" />
    <rect x="13" y="16" width="7" height="8" rx="0.6" fill="#0052ff" />
    <rect x="21" y="16" width="7" height="8" rx="0.6" fill="#4a82ff" />
    <rect x="29" y="16" width="6" height="8" rx="0.6" fill="#0052ff" />

    <!-- Subtle inner highlight -->
    <rect x="0" y="0" width="32" height="32" fill="url(#mortar)" opacity="0.04" />
    <defs>
      <linearGradient id="mortar" x1="0" y1="0" x2="0" y2="32">
        <stop offset="0%" stop-color="#fff" />
        <stop offset="100%" stop-color="#000" />
      </linearGradient>
    </defs>
  </svg>

  <span class="font-display font-bold text-base tracking-tight text-ink-50">
    basewall<span class="text-accent-cream">.fun</span>
  </span>
</div>

<style>
  .logo-anim rect {
    transform-origin: center;
    animation: brick-settle 1.4s cubic-bezier(0.16, 1, 0.3, 1) backwards;
  }
  .logo-anim rect:nth-child(1) { animation-delay: 0ms; }
  .logo-anim rect:nth-child(2) { animation-delay: 60ms; }
  .logo-anim rect:nth-child(3) { animation-delay: 120ms; }
  .logo-anim rect:nth-child(4) { animation-delay: 180ms; }
  .logo-anim rect:nth-child(5) { animation-delay: 90ms; }
  .logo-anim rect:nth-child(6) { animation-delay: 150ms; }
  .logo-anim rect:nth-child(7) { animation-delay: 210ms; }
  .logo-anim rect:nth-child(8) { animation-delay: 270ms; }
  .logo-anim rect:nth-child(9) { animation-delay: 330ms; }

  @keyframes brick-settle {
    0% { transform: translateY(-8px) scale(0.6); opacity: 0; }
    60% { transform: translateY(0) scale(1.04); opacity: 1; }
    100% { transform: translateY(0) scale(1); opacity: 1; }
  }
</style>
