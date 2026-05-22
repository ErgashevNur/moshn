'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface WarrantyClaim {
  id: string
  owner: { full_name: string; phone: string }
  mechanic: { user: { full_name: string }; workshop_name: string }
  description: string
  status: string
  created_at: string
  amount_uzs: number | null
}

const STATUS_LABELS: Record<string, string> = {
  open: 'Ochiq',
  reviewing: 'Ko\'rib chiqilmoqda',
  approved: 'Tasdiqlandi',
  rejected: 'Rad etildi',
}

export default function WarrantyPage() {
  const [claims, setClaims] = useState<WarrantyClaim[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState('open')
  const [page, setPage] = useState(1)
  const [modal, setModal] = useState<{ id: string } | null>(null)
  const [resolve, setResolve] = useState({ status: 'approved', admin_notes: '', amount_uzs: '' })

  const fetchClaims = () => {
    setLoading(true)
    api.get('/admin/warranty', { params: { status, page, limit: 20 } })
      .then((res) => { setClaims(res.data.data.claims); setTotal(res.data.data.total) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchClaims() }, [status, page])

  const handleResolve = async () => {
    if (!modal) return
    try {
      await api.put(`/admin/warranty/${modal.id}/resolve`, {
        status: resolve.status,
        admin_notes: resolve.admin_notes,
        amount_uzs: resolve.amount_uzs ? parseInt(resolve.amount_uzs) : null,
      })
      setModal(null)
      fetchClaims()
    } catch (e) {
      console.error(e)
    }
  }

  return (
    <AdminLayout title="Kafolat da'volari">
      <div className="space-y-4">
        <div className="flex gap-3">
          {['open', 'reviewing', 'approved', 'rejected'].map((s) => (
            <button
              key={s}
              onClick={() => { setStatus(s); setPage(1) }}
              className={`px-4 py-2 rounded-lg text-sm transition-colors ${
                status === s ? 'bg-primary text-white font-semibold' : 'bg-dark-card text-gray-300 hover:bg-dark-input'
              }`}
            >
              {STATUS_LABELS[s]}
            </button>
          ))}
          <span className="ml-auto text-gray-400 text-sm self-center">Jami: {total}</span>
        </div>

        <div className="bg-dark-card rounded-xl border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-gray-400">
                <th className="px-4 py-3 text-left">Egasi</th>
                <th className="px-4 py-3 text-left">Usta</th>
                <th className="px-4 py-3 text-left">Tavsif</th>
                <th className="px-4 py-3 text-left">Status</th>
                <th className="px-4 py-3 text-left">Sana</th>
                <th className="px-4 py-3 text-left">Amallar</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} className="text-center py-8 text-gray-400">Yuklanmoqda...</td></tr>
              ) : claims.length === 0 ? (
                <tr><td colSpan={6} className="text-center py-8 text-gray-400">Da'vo yo'q</td></tr>
              ) : claims.map((c) => (
                <tr key={c.id} className="border-b border-dark-border/50 hover:bg-dark-input/30 transition-colors">
                  <td className="px-4 py-3">
                    <div>{c.owner?.full_name}</div>
                    <div className="text-gray-400 text-xs">{c.owner?.phone}</div>
                  </td>
                  <td className="px-4 py-3">
                    <div>{c.mechanic?.user?.full_name}</div>
                    <div className="text-gray-400 text-xs">{c.mechanic?.workshop_name}</div>
                  </td>
                  <td className="px-4 py-3 max-w-xs text-gray-300 text-xs">{c.description}</td>
                  <td className="px-4 py-3">
                    <span className={`status-${c.status}`}>{STATUS_LABELS[c.status]}</span>
                  </td>
                  <td className="px-4 py-3 text-gray-400">{new Date(c.created_at).toLocaleDateString('uz')}</td>
                  <td className="px-4 py-3">
                    {(c.status === 'open' || c.status === 'reviewing') && (
                      <button
                        onClick={() => setModal({ id: c.id })}
                        className="text-xs bg-primary/10 text-primary hover:bg-primary/20 px-3 py-1.5 rounded-lg transition-colors"
                      >
                        Hal qilish
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {modal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-dark-card rounded-xl p-6 w-full max-w-md border border-dark-border">
            <h3 className="text-lg font-semibold mb-4">Da'voni hal qilish</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-1.5">Qaror</label>
                <select
                  value={resolve.status}
                  onChange={(e) => setResolve(p => ({ ...p, status: e.target.value }))}
                  className="w-full bg-dark-input border border-dark-border rounded-lg px-3 py-2.5 text-white focus:outline-none focus:border-primary"
                >
                  <option value="approved">Tasdiqlash</option>
                  <option value="rejected">Rad etish</option>
                </select>
              </div>
              <div>
                <label className="block text-sm text-gray-400 mb-1.5">Admin izohi</label>
                <textarea
                  value={resolve.admin_notes}
                  onChange={(e) => setResolve(p => ({ ...p, admin_notes: e.target.value }))}
                  rows={3}
                  className="w-full bg-dark-input border border-dark-border rounded-lg px-3 py-2.5 text-white focus:outline-none focus:border-primary resize-none"
                />
              </div>
              {resolve.status === 'approved' && (
                <div>
                  <label className="block text-sm text-gray-400 mb-1.5">Kompensatsiya (so'm)</label>
                  <input
                    type="number"
                    value={resolve.amount_uzs}
                    onChange={(e) => setResolve(p => ({ ...p, amount_uzs: e.target.value }))}
                    className="w-full bg-dark-input border border-dark-border rounded-lg px-3 py-2.5 text-white focus:outline-none focus:border-primary"
                    placeholder="0"
                  />
                </div>
              )}
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setModal(null)} className="flex-1 py-2.5 bg-dark-input rounded-lg text-sm text-gray-300">Bekor</button>
              <button onClick={handleResolve} className="flex-1 py-2.5 bg-primary text-white font-semibold rounded-lg text-sm">Saqlash</button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
