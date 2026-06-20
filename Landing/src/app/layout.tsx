import type { Metadata } from 'next'
import { Sora } from 'next/font/google'
import './globals.css'
import { I18nProvider } from '@/lib/i18n'

const sora = Sora({ subsets: ['latin'], weight: ['400', '500', '600', '700', '800'], variable: '--font-sora' })

export const metadata: Metadata = {
  title: 'Shina24 — Shinomontaj bron qilish va boshqarish platformasi',
  description: 'Eng yaqin shinomontajni toping, bir necha bosishda bron qiling, navbatsiz xizmat oling. Shina24 — mijoz va servislar uchun yagona platforma.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="uz">
      <body className={`${sora.variable} font-sora`}>
        <I18nProvider>{children}</I18nProvider>
      </body>
    </html>
  )
}
