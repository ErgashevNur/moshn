'use client'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'

type IconName =
  | 'dashboard' | 'shop' | 'calendar' | 'users' | 'star'
  | 'bell' | 'leaf' | 'tag' | 'logout'

const ICONS: Record<IconName, string> = {
  dashboard: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
  shop:      'M20 4H4v2l8 5 8-5V4zM4 13v7h16v-7l-8 5-8-5z',
  calendar:  'M19 4h-1V2h-2v2H8V2H6v2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V9h14v11z',
  users:     'M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z',
  star:      'M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z',
  bell:      'M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z',
  leaf:      'M17 8C8 10 5.9 16.17 3.82 21.34L5.71 22l1-2.3A4.49 4.49 0 008 20c9 0 11-6 11-10 0-3.03-.59-5.53-2-7zm-8.08 9.27A6.5 6.5 0 0113 13c-1.67 2.5-4.44 4-8.08 4.27z',
  tag:       'M21.41 11.58l-9-9C12.05 2.22 11.55 2 11 2H4c-1.1 0-2 .9-2 2v7c0 .55.22 1.05.59 1.42l9 9c.36.36.86.58 1.41.58.55 0 1.05-.22 1.41-.59l7-7c.37-.36.59-.86.59-1.41 0-.55-.23-1.06-.59-1.42zM5.5 7C4.67 7 4 6.33 4 5.5S4.67 4 5.5 4 7 4.67 7 5.5 6.33 7 5.5 7z',
  logout:    'M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z',
}

function SvgIcon({ name, className }: { name: IconName; className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className ?? 'w-5 h-5'}>
      <path d={ICONS[name]} />
    </svg>
  )
}

const NAV = [
  { href: '/dashboard',     label: 'Dashboard',        icon: 'dashboard' as IconName },
  { href: '/shops',         label: 'Shinomontajlar',   icon: 'shop'      as IconName },
  { href: '/bookings',      label: 'Bronlar',          icon: 'calendar'  as IconName },
  { href: '/users',         label: 'Foydalanuvchilar', icon: 'users'     as IconName },
  { href: '/reviews',       label: 'Sharhlar',         icon: 'star'      as IconName },
  { href: '/seasonal',      label: 'Mavsum qoidalari', icon: 'leaf'      as IconName },
  { href: '/service-types', label: 'Xizmat turlari',   icon: 'tag'       as IconName },
  { href: '/notifications', label: 'Bildirishnomalar', icon: 'bell'      as IconName },
]

export default function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  return (
    <aside className="w-60 bg-elevated min-h-screen flex flex-col border-r border-border shrink-0">
      {/* Logo */}
      <div className="px-5 py-5 border-b border-border">
        <p className="text-text font-semibold text-lg tracking-tight">Shina24</p>
        <p className="text-text3 text-xs font-mono mt-0.5">Admin panel</p>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
        {NAV.map((item) => {
          const active = pathname === item.href || pathname.startsWith(item.href + '/')
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium transition-colors ${
                active
                  ? 'bg-text/10 text-text'
                  : 'text-text2 hover:bg-surface hover:text-text'
              }`}
            >
              <SvgIcon
                name={item.icon}
                className={`w-4 h-4 shrink-0 ${active ? 'text-text' : 'text-text3'}`}
              />
              {item.label}
            </Link>
          )
        })}
      </nav>

      {/* Logout */}
      <div className="p-3 border-t border-border">
        <button
          onClick={() => {
            localStorage.removeItem('access_token')
            localStorage.removeItem('refresh_token')
            router.push('/login')
          }}
          className="w-full flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium text-text2 hover:bg-danger-dim hover:text-danger transition-colors"
        >
          <SvgIcon name="logout" className="w-4 h-4 shrink-0" />
          Chiqish
        </button>
      </div>
    </aside>
  )
}
