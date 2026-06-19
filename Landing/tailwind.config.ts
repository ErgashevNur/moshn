import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        bg: '#09090a',
        bgE: '#131316',
        surf: '#1a1a1e',
        surf2: '#242429',
        surf3: '#2e2e34',
        txt: '#f4f4f2',
        txt2: 'rgba(244,244,242,.60)',
        txt3: 'rgba(244,244,242,.36)',
        gold: '#d4a843',
        goldDim: 'rgba(212,168,67,.16)',
      },
      fontFamily: {
        sora: ['var(--font-sora)'],
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic':
          'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
      },
    },
  },
  plugins: [],
}
export default config
