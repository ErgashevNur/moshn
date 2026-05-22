import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Moshn Admin',
  description: 'Moshn boshqaruv paneli',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="uz">
      <body className="bg-dark-bg text-ink min-h-screen font-sans antialiased">
        {children}
      </body>
    </html>
  )
}
