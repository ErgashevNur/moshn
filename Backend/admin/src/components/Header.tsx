'use client'
import { useRouter } from 'next/navigation'

interface HeaderProps {
  title: string
}

export default function Header({ title }: HeaderProps) {
  const router = useRouter()

  const handleLogout = () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    router.push('/login')
  }

  return (
    <header className="h-16 bg-dark-card border-b border-dark-border flex items-center justify-between px-6">
      <div className="flex items-center gap-3">
        <span className="w-1.5 h-1.5 bg-accent" />
        <h2 className="font-display text-lg font-semibold text-ink tracking-tight">{title}</h2>
      </div>
      <button
        onClick={handleLogout}
        className="mono-label text-ink-soft hover:text-accent transition-colors"
      >
        Chiqish →
      </button>
    </header>
  )
}
