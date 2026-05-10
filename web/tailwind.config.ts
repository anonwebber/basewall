import type { Config } from 'tailwindcss';

export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        wall: {
          bg: '#0a0a0a',
          fg: '#f5f5f5',
          accent: '#0052ff',
          highlight: '#ffd700'
        }
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'Fira Code', 'monospace']
      }
    }
  },
  plugins: []
} satisfies Config;
