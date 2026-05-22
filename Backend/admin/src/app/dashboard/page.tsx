'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import Icon from '@/components/Icon'
import api from '@/lib/api'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'

interface Stats {
  users: number
  vehicles: number
  services: number
  mechanics: number
}

const mockChartData = [
  { day: 'Dush', services: 4 },
  { day: 'Sesh', services: 7 },
  { day: 'Chor', services: 5 },
  { day: 'Pay', services: 12 },
  { day: 'Jum', services: 9 },
  { day: 'Shan', services: 6 },
  { day: 'Yak', services: 3 },
]

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.get('/admin/stats')
      .then((res) => setStats(res.data.data))
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [])

  const cards = [
    { label: 'Foydalanuvchilar', value: stats?.users ?? 0, icon: 'users' as const },
    { label: 'Mashinalar', value: stats?.vehicles ?? 0, icon: 'car' as const },
    { label: 'Servis yozuvlari', value: stats?.services ?? 0, icon: 'clipboard' as const },
    { label: 'Tasdiqlangan ustalar', value: stats?.mechanics ?? 0, icon: 'wrench' as const },
  ]

  return (
    <AdminLayout title="Dashboard">
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="w-8 h-8 border-2 border-accent border-t-transparent rounded-full animate-spin" />
        </div>
      ) : (
        <div className="space-y-6">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {cards.map((card) => (
              <div
                key={card.label}
                className="group relative bg-dark-card p-6 border border-dark-border hover:border-accent/40 transition-colors"
              >
                <span className="absolute top-0 left-0 h-0.5 w-10 bg-accent/70" />
                <div className="flex items-center justify-between mb-4">
                  <span className="flex items-center justify-center w-10 h-10 bg-accent/10 text-accent">
                    <Icon name={card.icon} className="w-5 h-5" />
                  </span>
                </div>
                <p className="font-display text-4xl font-bold tabular-nums text-ink leading-none">{card.value}</p>
                <p className="mono-label text-ink-soft mt-2">{card.label}</p>
              </div>
            ))}
          </div>

          <div className="bg-dark-card p-6 border border-dark-border">
            <div className="flex items-center justify-between mb-5">
              <h3 className="font-display text-lg font-semibold text-ink">Oxirgi 7 kundagi servislar</h3>
              <span className="mono-label text-ink-soft">§ Haftalik</span>
            </div>
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={mockChartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#283449" />
                <XAxis dataKey="day" stroke="#6b7580" />
                <YAxis stroke="#6b7580" />
                <Tooltip
                  contentStyle={{ background: '#1a2535', border: '1px solid #283449', borderRadius: 0 }}
                  labelStyle={{ color: '#f2ece2' }}
                  cursor={{ fill: '#ff52301a' }}
                />
                <Bar dataKey="services" fill="#ff5230" radius={[0, 0, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
