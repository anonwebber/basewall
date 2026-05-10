import type { Config } from 'tailwindcss';

export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        // Warm dark palette — industrial brickwork meets premium degen
        ink: {
          950: '#0a0805',  // primary background, warmest near-black
          900: '#100c08',  // base layer
          800: '#1a1410',  // cards, modals
          700: '#241c15',  // raised
          600: '#332821',  // borders, dividers
          500: '#4a3a30',  // hover states on dark
          400: '#6b5a4d',  // muted text
          300: '#8c7a6a',  // secondary text
          200: '#b5a695',  // tertiary text
          100: '#d8cdc0',  // primary text on dark
          50: '#f5efe6'    // brightest, warm off-white
        },
        brick: {
          mortar: '#2a1f18',
          empty: '#1e1812',
          base: '#8c4a2c',  // terracotta
          warm: '#a0552d',
          rich: '#c2693a',
          glow: '#ff9a4d'   // hover/active
        },
        accent: {
          base: '#0052ff',     // Base chain blue
          'base-dim': '#003fcc',
          'base-glow': '#3380ff',
          gold: '#ffb020',     // warm amber gold
          'gold-deep': '#cc8800',
          burn: '#ff5722',     // burn/danger
          mint: '#22cc88'      // success/owned
        }
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', '"Fira Code"', '"SF Mono"', 'ui-monospace', 'monospace'],
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'system-ui', 'sans-serif'],
        display: ['"JetBrains Mono"', 'ui-monospace', 'monospace']
      },
      fontSize: {
        '2xs': '0.6875rem'
      },
      letterSpacing: {
        wider: '0.08em',
        widest: '0.16em'
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'shimmer': 'shimmer 2s linear infinite',
        'scan': 'scan 4s linear infinite',
        'mint-pulse': 'mint-pulse 1.5s ease-out',
        'fade-up': 'fade-up 0.4s cubic-bezier(0.16, 1, 0.3, 1)'
      },
      keyframes: {
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' }
        },
        scan: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(100%)' }
        },
        'mint-pulse': {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '50%': { transform: 'scale(1.02)', opacity: '1' },
          '100%': { transform: 'scale(1)', opacity: '1' }
        },
        'fade-up': {
          '0%': { transform: 'translateY(8px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' }
        }
      },
      backdropBlur: {
        xs: '2px'
      },
      boxShadow: {
        'brick': '0 1px 0 rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.06)',
        'brick-hover': '0 0 24px rgba(255,176,32,0.3), inset 0 1px 0 rgba(255,255,255,0.12)',
        'glow-base': '0 0 24px rgba(0,82,255,0.35)',
        'glow-gold': '0 0 24px rgba(255,176,32,0.35)',
        'panel': '0 4px 24px rgba(0,0,0,0.5), 0 1px 0 rgba(255,255,255,0.04) inset'
      }
    }
  },
  plugins: []
} satisfies Config;
