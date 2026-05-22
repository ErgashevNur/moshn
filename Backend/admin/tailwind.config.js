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
        // moshn.uz brand — coral accent
        primary: '#ff5230',
        accent: '#ff5230',
        'accent-deep': '#e83c1f',
        'accent-soft': '#ff6b4d',
        // moshn.uz dark ("Qorong'u rejim") surfaces — navy
        'dark-bg': '#0e1620',
        'dark-card': '#1a2535',
        'dark-input': '#131d2b',
        'dark-border': '#283449',
        // semantic ink (light text on navy)
        ink: '#f2ece2',
        'ink-mute': '#9aa3af',
        'ink-soft': '#6b7580',
        danger: '#ff5252',
        warning: '#ffd600',
      },
      fontFamily: {
        // moshn.uz typography
        display: ['"Clash Display"', '"Cabinet Grotesk"', 'system-ui', 'sans-serif'],
        sans: ['"Switzer"', '"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
        mono: ['"IBM Plex Mono"', 'ui-monospace', 'monospace'],
      },
      borderRadius: {
        // moshn.uz editorial style — sharp corners
        none: '0',
        sm: '0',
        DEFAULT: '2px',
        md: '2px',
        lg: '2px',
        xl: '3px',
        '2xl': '4px',
        '3xl': '4px',
        full: '9999px',
      },
      maxWidth: {
        content: '1200px',
      },
    },
  },
  plugins: [],
}
