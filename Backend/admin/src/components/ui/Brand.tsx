'use client'

// Основной фирменный знак (шина/колесо). `theme` определяет, в каком
// цвете он выводится — компонент всегда отображается на "инверсном"
// фоне (var(--inv)), поэтому выбирается вариант, контрастный этому фону.
export default function Brand({ s = 26, theme = 'dark' }: { s?: number; theme?: 'dark' | 'light' }) {
  // тёмная тема -> var(--inv) светлый (бело-серый) -> знак должен быть тёмным
  // светлая тема -> var(--inv) тёмный -> знак должен быть светлым
  const src = theme === 'dark'
    ? '/logos/shina24-mark-transparent.png'
    : '/logos/shina24-mark-white.png'

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={src} alt="Shina24" width={s} height={s} style={{ width: s, height: s, objectFit: 'contain' }} />
  )
}
