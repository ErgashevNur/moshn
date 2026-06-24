import type { Metadata } from 'next'
import { Sora } from 'next/font/google'
import './globals.css'
import { I18nProvider } from '@/lib/i18n'

const sora = Sora({ subsets: ['latin'], weight: ['400', '500', '600', '700', '800'], variable: '--font-sora' })

export const metadata: Metadata = {
  title: 'Shina24 — платформа бронирования и управления шиномонтажом',
  description: 'Найдите ближайший шиномонтаж, забронируйте в несколько кликов и получите услугу без очереди. Shina24 — единая платформа для клиентов и сервисов.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ru">
      <body className={`${sora.variable} font-sora`}>
        <I18nProvider>{children}</I18nProvider>
      </body>
    </html>
  )
}
