import type { Config } from 'tailwindcss';

export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        // Warm dark palette — coffee-ink background, cream highlights, Base blue accent. NO ORANGE.
        ink: {
          950: '#0a0805',
          900: '#100c08',
          800: '#1a1410',
          700: '#241c15',
          600: '#332821',
          500: '#4a3a30',
          400: '#6b5a4d',
          300: '#8c7a6a',
          200: '#b5a695',
          100: '#d8cdc0',
          50: '#f5efe6'    // primary cream
        },
        accent: {
          // Base chain blue — primary action + chain identity
          base: '#0052ff',
          'base-dim': '#003fcc',
          'base-glow': '#4a82ff',
          // Cream — premium highlight, hover, stats accents
          cream: '#f5efe6',
          'cream-dim': '#d8cdc0',
          // Mint green — only for "minted/owned" success states
          mint: '#22cc88'
        }
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', '"Fira Code"', '"SF Mono"', 'ui-monospace', 'monospace'],
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'system-ui', 'sans-serif'],
        display: ['"JetBrains Mono"', 'ui-monospace', 'monospace']
      },
      fontSize: { '2xs': '0.6875rem' },
      letterSpacing: { wider: '0.08em', widest: '0.16em' },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'shimmer': 'shimmer 2s linear infinite',
        'scan': 'scan 4s linear infinite',
        'mint-pulse': 'mint-pulse 1.5s ease-out',
        'fade-up': 'fade-up 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
        'breathe': 'breathe 6s ease-in-out infinite'
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
        },
        breathe: {
          '0%, 100%': { opacity: '0.85' },
          '50%': { opacity: '1' }
        }
      },
      backdropBlur: { xs: '2px' },
      boxShadow: {
        'brick': '0 1px 0 rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.06)',
        'brick-hover': '0 0 24px rgba(74,130,255,0.35), inset 0 1px 0 rgba(255,255,255,0.12)',
        'glow-base': '0 0 24px rgba(0,82,255,0.45)',
        'glow-cream': '0 0 24px rgba(245,239,230,0.25)',
        'panel': '0 4px 24px rgba(0,0,0,0.5), 0 1px 0 rgba(255,255,255,0.04) inset'
      }
    }
  },
  plugins: []
} satisfies Config;
