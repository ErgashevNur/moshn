/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        bg:       '#09090A',
        elevated: '#131316',
        surface:  '#1A1A1E',
        surface2: '#242429',
        surface3: '#2E2E34',

        text:  '#F4F4F2',
        text2: 'rgba(244,244,242,0.60)',
        text3: 'rgba(244,244,242,0.36)',

        gold:         '#D4A843',
        'gold-dim':   'rgba(212,168,67,0.16)',
        danger:       '#E5382B',
        'danger-dim': 'rgba(229,56,43,0.16)',
        success:      '#30D158',
        'success-dim':'rgba(48,209,88,0.16)',
        info:         '#38BDF8',
        'info-dim':   'rgba(56,189,248,0.16)',
        warning:      '#FFB800',
        'warning-dim':'rgba(255,184,0,0.16)',

        border:  'rgba(255,255,255,0.085)',
        border2: 'rgba(255,255,255,0.14)',
      },
      fontFamily: {
        sans: ['"Inter"', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
      borderRadius: {
        sm:    '8px',
        DEFAULT:'12px',
        md:    '12px',
        lg:    '16px',
        xl:    '20px',
        '2xl': '24px',
        full:  '9999px',
      },
      maxWidth: {
        content: '1280px',
      },
    },
  },
  plugins: [],
}
