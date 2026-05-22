'use client'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import Icon from './Icon'

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: 'dashboard' as const },
  { href: '/sos', label: 'SOS so\'rovlari', icon: 'sos' as const },
  { href: '/requests', label: 'Tamirlash so\'rovlari', icon: 'clipboard' as const },
  { href: '/mechanics', label: 'Ustalar', icon: 'wrench' as const },
  { href: '/services', label: 'Servis yozuvlari', icon: 'clipboard' as const },
  { href: '/users', label: 'Foydalanuvchilar', icon: 'users' as const },
  { href: '/repair', label: 'Tamirlash', icon: 'repair' as const },
  { href: '/reviews', label: 'Sharhlar', icon: 'star' as const },
  { href: '/warranty', label: 'Kafolat da\'volari', icon: 'shield' as const },
  { href: '/notifications', label: 'Bildirishnomalar', icon: 'bell' as const },
]

export default function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  const handleLogout = () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    router.push('/login')
  }

  return (
    <aside className="w-64 bg-dark-card min-h-screen flex flex-col border-r border-dark-border">
      <div className="px-6 py-6 border-b border-dark-border flex flex-col items-center">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo-cream.png" alt="Moshn" className="h-16 w-auto" />
        <p className="mono-label text-ink-soft mt-3">Admin panel</p>
      </div>

      <nav className="flex-1 px-3 py-5 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = pathname === item.href
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`group relative flex items-center gap-3 px-3 py-2.5 text-sm font-medium transition-all ${
                isActive
                  ? 'bg-accent/10 text-accent'
                  : 'text-ink-mute hover:bg-white/[0.03] hover:text-ink'
              }`}
            >
              {isActive && <span className="absolute left-0 top-1.5 bottom-1.5 w-0.5 bg-accent" />}
              <Icon
                name={item.icon}
                className={`w-[18px] h-[18px] shrink-0 ${
                  isActive ? 'text-accent' : 'text-ink-soft group-hover:text-ink-mute'
                }`}
              />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>

      <div className="p-3 border-t border-dark-border">
        <button
          onClick={handleLogout}
          className="w-full px-3 py-2.5 text-sm font-medium text-ink-mute hover:bg-danger/10 hover:text-danger transition-colors text-left flex items-center gap-3"
        >
          <Icon name="logout" className="w-[18px] h-[18px] shrink-0" />
          <span>Chiqish</span>
        </button>
      </div>
    </aside>
  )
}
