'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Mechanic {
  id: string
  user: { full_name: string; phone: string }
  workshop_name: string
  workshop_address: string
  star_level: number
  verification_status: string
  rating_avg: number
  total_services: number
}

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    pending: 'status-pending',
    verified: 'status-verified',
    rejected: 'status-rejected',
  }
  const labels: Record<string, string> = {
    pending: 'Kutilmoqda',
    verified: 'Tasdiqlangan',
    rejected: 'Rad etilgan',
  }
  return <span className={map[status] || 'status-pending'}>{labels[status] || status}</span>
}

export default function MechanicsPage() {
  const [mechanics, setMechanics] = useState<Mechanic[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [modal, setModal] = useState<{ id: string; name: string } | null>(null)
  const [verifyInput, setVerifyInput] = useState({ status: 'verified', star_level: 1, notes: '' })

  const fetchMechanics = async () => {
    setLoading(true)
    try {
      const res = await api.get('/admin/mechanics', { params: { status, page, limit: 20 } })
      setMechanics(res.data.data.mechanics)
      setTotal(res.data.data.total)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchMechanics() }, [status, page])

  const handleVerify = async () => {
    if (!modal) return
    try {
      await api.put(`/admin/mechanics/${modal.id}/verify`, verifyInput)
      setModal(null)
      fetchMechanics()
    } catch (e) {
      console.error(e)
    }
  }

  return (
    <AdminLayout title="Ustalar boshqaruvi">
      <div className="space-y-4">
        <div className="flex gap-3">
          {['', 'pending', 'verified', 'rejected'].map((s) => (
            <button
              key={s}
              onClick={() => { setStatus(s); setPage(1) }}
              className={`px-4 py-2 rounded-lg text-sm transition-colors ${
                status === s ? 'bg-primary text-white font-semibold' : 'bg-dark-card text-gray-300 hover:bg-dark-input'
              }`}
            >
              {s === '' ? 'Hammasi' : s === 'pending' ? 'Kutilmoqda' : s === 'verified' ? 'Tasdiqlangan' : 'Rad etilgan'}
            </button>
          ))}
          <span className="ml-auto text-gray-400 text-sm self-center">Jami: {total}</span>
        </div>

        <div className="bg-dark-card rounded-xl border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-gray-400">
                <th className="px-4 py-3 text-left">Ism</th>
                <th className="px-4 py-3 text-left">Ustaxona</th>
                <th className="px-4 py-3 text-left">Manzil</th>
                <th className="px-4 py-3 text-left">Daraja</th>
                <th className="px-4 py-3 text-left">Reyting</th>
                <th className="px-4 py-3 text-left">Status</th>
                <th className="px-4 py-3 text-left">Amallar</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={7} className="text-center py-8 text-gray-400">Yuklanmoqda...</td></tr>
              ) : mechanics.length === 0 ? (
                <tr><td colSpan={7} className="text-center py-8 text-gray-400">Ma'lumot yo'q</td></tr>
              ) : mechanics.map((m) => (
                <tr key={m.id} className="border-b border-dark-border/50 hover:bg-dark-input/30 transition-colors">
                  <td className="px-4 py-3">
                    <div className="font-medium">{m.user?.full_name}</div>
                    <div className="text-gray-400 text-xs">{m.user?.phone}</div>
                  </td>
                  <td className="px-4 py-3">{m.workshop_name || '—'}</td>
                  <td className="px-4 py-3 max-w-xs truncate text-gray-300">{m.workshop_address}</td>
                  <td className="px-4 py-3">{'⭐'.repeat(m.star_level) || '—'}</td>
                  <td className="px-4 py-3">{m.rating_avg?.toFixed(1)} ({m.total_services})</td>
                  <td className="px-4 py-3"><StatusBadge status={m.verification_status} /></td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => setModal({ id: m.id, name: m.user?.full_name })}
                      className="text-xs bg-primary/10 text-primary hover:bg-primary/20 px-3 py-1.5 rounded-lg transition-colors"
                    >
                      Boshqarish
                    </button>
                  </td>
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

      {modal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-dark-card rounded-xl p-6 w-full max-w-md border border-dark-border">
            <h3 className="text-lg font-semibold mb-4">Usta: {modal.name}</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-1.5">Qaror</label>
                <select
                  value={verifyInput.status}
                  onChange={(e) => setVerifyInput(p => ({ ...p, status: e.target.value }))}
                  className="w-full bg-dark-input border border-dark-border rounded-lg px-3 py-2.5 text-white focus:outline-none focus:border-primary"
                >
                  <option value="verified">Tasdiqlash</option>
                  <option value="rejected">Rad etish</option>
                </select>
              </div>
              {verifyInput.status === 'verified' && (
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5">Yulduz darajasi</label>
                  <div className="flex gap-2">
                    {[1, 2, 3].map((n) => (
                      <button
                        key={n}
                        onClick={() => setVerifyInput(p => ({ ...p, star_level: n }))}
                        className={`flex-1 py-2 rounded-lg text-sm transition-colors ${
                          verifyInput.star_level === n ? 'bg-primary text-white font-semibold' : 'bg-dark-input text-gray-300'
                        }`}
                      >
                        {'⭐'.repeat(n)}
                      </button>
                    ))}
                  </div>
                </div>
              )}
              <div>
                <label className="block text-sm text-gray-400 mb-1.5">Izoh</label>
                <textarea
                  value={verifyInput.notes}
                  onChange={(e) => setVerifyInput(p => ({ ...p, notes: e.target.value }))}
                  rows={3}
                  className="w-full bg-dark-input border border-dark-border rounded-lg px-3 py-2.5 text-white focus:outline-none focus:border-primary resize-none"
                  placeholder="Ixtiyoriy izoh..."
                />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setModal(null)} className="flex-1 py-2.5 bg-dark-input rounded-lg text-sm text-gray-300 hover:bg-dark-border transition-colors">Bekor</button>
              <button onClick={handleVerify} className="flex-1 py-2.5 bg-primary text-white font-semibold rounded-lg text-sm hover:bg-primary/90 transition-colors">Saqlash</button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
