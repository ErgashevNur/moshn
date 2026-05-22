'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface ServiceRecord {
  id: string
  vehicle: { current_plate: string; make: string; model: string }
  mechanic: { user: { full_name: string }; workshop_name: string }
  owner: { full_name: string }
  service_date: string
  service_type: string
  price_uzs: number | null
  status: string
}

const STATUS_LABELS: Record<string, string> = {
  created: 'Kutilmoqda',
  confirmed: 'Tasdiqlangan',
  rejected: 'Rad etilgan',
  auto_confirmed: 'Avtomatik tasdiqlangan',
}

function StatusBadge({ status }: { status: string }) {
  return <span className={`status-${status}`}>{STATUS_LABELS[status] || status}</span>
}

export default function ServicesPage() {
  const [records, setRecords] = useState<ServiceRecord[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)

  useEffect(() => {
    setLoading(true)
    api.get('/admin/services', { params: { status, page, limit: 20 } })
      .then((res) => { setRecords(res.data.data.records); setTotal(res.data.data.total) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [status, page])

  return (
    <AdminLayout title="Servis yozuvlari">
      <div className="space-y-4">
        <div className="flex gap-3 flex-wrap">
          {['', 'created', 'confirmed', 'rejected', 'auto_confirmed'].map((s) => (
            <button
              key={s}
              onClick={() => { setStatus(s); setPage(1) }}
              className={`px-4 py-2 rounded-lg text-sm transition-colors ${
                status === s ? 'bg-primary text-white font-semibold' : 'bg-dark-card text-gray-300 hover:bg-dark-input'
              }`}
            >
              {s === '' ? 'Hammasi' : STATUS_LABELS[s]}
            </button>
          ))}
          <span className="ml-auto text-gray-400 text-sm self-center">Jami: {total}</span>
        </div>

        <div className="bg-dark-card rounded-xl border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-gray-400">
                <th className="px-4 py-3 text-left">Mashina</th>
                <th className="px-4 py-3 text-left">Usta</th>
                <th className="px-4 py-3 text-left">Egasi</th>
                <th className="px-4 py-3 text-left">Sana</th>
                <th className="px-4 py-3 text-left">Ish turi</th>
                <th className="px-4 py-3 text-left">Narx</th>
                <th className="px-4 py-3 text-left">Status</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={7} className="text-center py-8 text-gray-400">Yuklanmoqda...</td></tr>
              ) : records.length === 0 ? (
                <tr><td colSpan={7} className="text-center py-8 text-gray-400">Ma'lumot yo'q</td></tr>
              ) : records.map((r) => (
                <tr key={r.id} className="border-b border-dark-border/50 hover:bg-dark-input/30 transition-colors">
                  <td className="px-4 py-3">
                    <div className="font-medium">{r.vehicle?.current_plate}</div>
                    <div className="text-gray-400 text-xs">{r.vehicle?.make} {r.vehicle?.model}</div>
                  </td>
                  <td className="px-4 py-3">
                    <div>{r.mechanic?.user?.full_name}</div>
                    <div className="text-gray-400 text-xs">{r.mechanic?.workshop_name}</div>
                  </td>
                  <td className="px-4 py-3">{r.owner?.full_name}</td>
                  <td className="px-4 py-3 text-gray-300">{new Date(r.service_date).toLocaleDateString('uz')}</td>
                  <td className="px-4 py-3">{r.service_type}</td>
                  <td className="px-4 py-3 text-gray-300">{r.price_uzs ? `${r.price_uzs.toLocaleString()} so'm` : '—'}</td>
                  <td className="px-4 py-3"><StatusBadge status={r.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {total > 20 && (
          <div className="flex gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="px-3 py-1.5 bg-dark-card rounded-lg text-sm disabled:opacity-50">← Oldingi</button>
            <span className="px-3 py-1.5 text-sm text-gray-400">Sahifa {page}</span>
            <button onClick={() => setPage(p => p + 1)} disabled={page * 20 >= total} className="px-3 py-1.5 bg-dark-card rounded-lg text-sm disabled:opacity-50">Keyingi →</button>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
