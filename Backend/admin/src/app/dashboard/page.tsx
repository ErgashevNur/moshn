'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Stats {
  users: number
  vehicles: number
  bookings: number
  shops: number
  active_shops: number
}

function StatCard({ label, value, sub, color }: { label: string; value: number; sub?: string; color: string }) {
  return (
    <div className="card p-5">
      <p className={`text-3xl font-bold tabular-nums ${color}`}>{value.toLocaleString()}</p>
      <p className="text-text text-sm font-medium mt-1">{label}</p>
      {sub && <p className="text-text3 text-xs mt-0.5">{sub}</p>}
    </div>
  )
}

function CardSkeleton() {
  return (
    <div className="card p-5 animate-pulse space-y-2">
      <div className="h-8 w-14 bg-surface2 rounded" />
      <div className="h-4 w-24 bg-surface2 rounded" />
    </div>
  )
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/admin/stats')
      .then((r) => setStats(r.data.data))
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [])

  return (
    <AdminLayout title="Dashboard">
      <div className="space-y-6">
        {/* Stats grid */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
          {loading || !stats ? (
            Array.from({ length: 5 }).map((_, i) => <CardSkeleton key={i} />)
          ) : (
            <>
              <StatCard label="Mijozlar"       value={stats.users}        color="text-info"    />
              <StatCard label="Avtomobillar"   value={stats.vehicles}      color="text-text2"   />
              <StatCard label="Jami bronlar"   value={stats.bookings}      color="text-gold"    />
              <StatCard label="Shinomontajlar" value={stats.shops}         color="text-text2"   />
              <StatCard label="Tasdiqlangan"   value={stats.active_shops}  color="text-success" sub="servislar" />
            </>
          )}
        </div>

        {/* Quick actions */}
        <div>
          <p className="text-text3 text-xs font-mono uppercase tracking-widest mb-3">Tez harakatlar</p>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {[
              { href: '/shops',         label: 'Shinomontajlar',        desc: 'Ro\'yxat, tasdiqlash'       },
              { href: '/bookings',      label: 'Bronlar',               desc: 'Barcha bronlarni ko\'rish'   },
              { href: '/seasonal',      label: 'Mavsum bildirshnomasi', desc: 'Qoida yaratish, yuborish'   },
            ].map((q) => (
              <a key={q.href} href={q.href}
                className="card p-4 hover:bg-surface2 transition-colors group">
                <p className="text-text font-semibold text-sm group-hover:text-gold transition-colors">{q.label}</p>
                <p className="text-text3 text-xs mt-0.5">{q.desc}</p>
              </a>
            ))}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
