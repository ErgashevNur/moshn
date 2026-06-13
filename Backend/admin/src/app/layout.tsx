import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Shina24',
  description: 'Shina24 boshqaruv paneli',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz">
      <body>{children}</body>
    </html>
  )
}
