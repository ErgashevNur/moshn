'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Booking {
  id: string
  customer: { full_name: string; phone: string }
  shop: { shop_name: string }
  vehicle: { plate: string; make: string; model: string }
  service_type: { name_uz: string }
  scheduled_at: string
  status: string
  total_price: number
  created_at: string
}

const STATUS_LABEL: Record<string, string> = {
  pending:     'Kutilmoqda',
  confirmed:   'Tasdiqlangan',
  in_progress: 'Jarayonda',
  completed:   'Bajarildi',
  cancelled:   'Bekor qilindi',
}

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)

  useEffect(() => {
    setLoading(true)
    const params: Record<string, unknown> = { page, limit: 20 }
    if (status) params.status = status
    api.get('/admin/bookings', { params })
      .then((r) => { setBookings(r.data.data.bookings ?? []); setTotal(r.data.data.total ?? 0) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [status, page])

  return (
    <AdminLayout title="Bronlar">
      <div className="space-y-4">
        {/* Status filter */}
        <div className="flex flex-wrap gap-2 items-center">
          {['', 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'].map((s) => (
            <button key={s} onClick={() => { setStatus(s); setPage(1) }}
              className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-colors ${
                status === s
                  ? 'border-text/30 bg-text/10 text-text'
                  : 'border-border text-text3 hover:text-text2'
              }`}
            >
              {s === '' ? 'Hammasi' : STATUS_LABEL[s]}
            </button>
          ))}
          <span className="text-text3 text-sm ml-auto">{total} ta bron</span>
        </div>

        {/* Table */}
        <div className="card overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-text3 text-xs font-mono uppercase tracking-wide">
                <th className="px-4 py-3 text-left">Mijoz</th>
                <th className="px-4 py-3 text-left">Servis</th>
                <th className="px-4 py-3 text-left">Avtomobil</th>
                <th className="px-4 py-3 text-left">Xizmat</th>
                <th className="px-4 py-3 text-left">Sana/vaqt</th>
                <th className="px-4 py-3 text-left">Narx</th>
                <th className="px-4 py-3 text-left">Holat</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 7 }).map((__, j) => (
                      <td key={j} className="px-4 py-3"><div className="h-4 bg-surface2 rounded w-24" /></td>
                    ))}
                  </tr>
                ))
              ) : bookings.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-text3">Bron topilmadi</td></tr>
              ) : bookings.map((b) => (
                <tr key={b.id} className="hover:bg-surface2/50 transition-colors">
                  <td className="px-4 py-3">
                    <p className="text-text font-medium">{b.customer?.full_name || '—'}</p>
                    <p className="text-text3 text-xs font-mono">{b.customer?.phone}</p>
                  </td>
                  <td className="px-4 py-3 text-text2">{b.shop?.shop_name || '—'}</td>
                  <td className="px-4 py-3">
                    <p className="text-text2 font-mono text-xs">{b.vehicle?.plate}</p>
                    <p className="text-text3 text-xs">{b.vehicle?.make} {b.vehicle?.model}</p>
                  </td>
                  <td className="px-4 py-3 text-text2 text-xs">{b.service_type?.name_uz || '—'}</td>
                  <td className="px-4 py-3 text-text3 text-xs">
                    {new Date(b.scheduled_at).toLocaleString('uz-UZ', {
                      day: '2-digit', month: '2-digit', year: '2-digit',
                      hour: '2-digit', minute: '2-digit',
                    })}
                  </td>
                  <td className="px-4 py-3 text-text2 font-mono text-xs">
                    {b.total_price > 0 ? b.total_price.toLocaleString() + ' so\'m' : '—'}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`badge badge-${b.status}`}>{STATUS_LABEL[b.status] ?? b.status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {total > 20 && (
          <div className="flex items-center gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-ghost disabled:opacity-40">← Oldingi</button>
            <span className="text-text3 text-sm">{page}-sahifa</span>
            <button onClick={() => setPage(p => p + 1)} disabled={page * 20 >= total} className="btn-ghost disabled:opacity-40">Keyingi →</button>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
