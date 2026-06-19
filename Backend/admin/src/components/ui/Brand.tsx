'use client'

// Asosiy brend belgisi (shina/g'ildirak). `theme` qaysi rangda chiqishini
// belgilaydi — bu komponent har doim "inverse" foni (var(--inv)) ustida
// chiqadi, shuning uchun fon rangiga qarama-qarshi rangli variant tanlanadi.
export default function Brand({ s = 26, theme = 'dark' }: { s?: number; theme?: 'dark' | 'light' }) {
  // dark tema -> var(--inv) yorug' (oq-kulrang) -> belgi qora rangda bo'lishi kerak
  // light tema -> var(--inv) qora -> belgi oq rangda bo'lishi kerak
  const src = theme === 'dark'
    ? '/logos/shina24-mark-transparent.png'
    : '/logos/shina24-mark-white.png'

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={src} alt="Shina24" width={s} height={s} style={{ width: s, height: s, objectFit: 'contain' }} />
  )
}
