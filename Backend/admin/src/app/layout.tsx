import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Shina24 Admin',
  description: 'Shina24 boshqaruv paneli',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz">
      <body className="bg-bg text-text min-h-screen font-sans antialiased">
        {children}
      </body>
    </html>
  )
}
