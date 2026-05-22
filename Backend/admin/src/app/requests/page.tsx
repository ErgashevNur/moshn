'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Mechanic {
  id: string
  user: { full_name: string; phone: string } | null
  workshop_name: string
}

interface RepairRequest {
  id: string
  user: { full_name: string; phone: string } | null
  phone: string
  car_info: string
  description: string
  status: string
  admin_notes: string
  preferred_mechanic: { workshop_name: string; user: { full_name: string } | null } | null
  assigned_mechanic: { workshop_name: string; user: { full_name: string } | null } | null
  assigned_mechanic_id: string | null
  created_at: string
}

const STATUS_LABELS: Record<string, string> = {
  new: 'Yangi',
  in_progress: 'Jarayonda',
  resolved: 'Hal qilindi',
  cancelled: 'Bekor qilindi',
}
const STATUS_OPTIONS = ['new', 'in_progress', 'resolved', 'cancelled']

export default function RequestsPage() {
  const [requests, setRequests] = useState<RepairRequest[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState('new')
  const [mechanics, setMechanics] = useState<Mechanic[]>([])
  const [modal, setModal] = useState<RepairRequest | null>(null)
  const [form, setForm] = useState({ mechanic_id: '', admin_notes: '', status: 'in_progress' })

  const fetchRequests = () => {
    setLoading(true)
    api.get('/admin/repair-requests', { params: { status, limit: 50 } })
      .then((res) => { setRequests(res.data.data.requests || []); setTotal(res.data.data.total) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }
  useEffect(() => { fetchRequests() }, [status])

  useEffect(() => {
    api.get('/admin/mechanics', { params: { limit: 100 } })
      .then((res) => setMechanics((res.data.data.mechanics || []).filter((m: any) => m.verification_status === 'verified')))
      .catch(() => {})
  }, [])

  const openModal = (r: RepairRequest) => {
    setModal(r)
    setForm({
      mechanic_id: r.assigned_mechanic_id || '',
      admin_notes: r.admin_notes || '',
      status: r.status === 'new' ? 'in_progress' : r.status,
    })
  }

  const handleAssign = async () => {
    if (!modal || !form.mechanic_id) return
    try {
      await api.put(`/admin/repair-requests/${modal.id}/assign`, { mechanic_id: form.mechanic_id, admin_notes: form.admin_notes })
      setModal(null); fetchRequests()
    } catch (e) { console.error(e) }
  }
  const handleStatus = async () => {
    if (!modal) return
    try {
      await api.put(`/admin/repair-requests/${modal.id}/status`, { status: form.status, admin_notes: form.admin_notes })
      setModal(null); fetchRequests()
    } catch (e) { console.error(e) }
  }

  return (
    <AdminLayout title="Tamirlash so'rovlari">
      <div className="space-y-4">
        <div className="flex gap-3 flex-wrap items-center">
          {STATUS_OPTIONS.map((s) => (
            <button
              key={s}
              onClick={() => setStatus(s)}
              className={`px-4 py-2 text-sm transition-colors ${
                status === s ? 'bg-accent text-white font-semibold' : 'bg-dark-card text-ink-mute hover:bg-dark-input'
              }`}
            >
              {STATUS_LABELS[s]}
            </button>
          ))}
          <span className="ml-auto mono-label text-ink-soft self-center">Jami {total}</span>
        </div>

        <div className="bg-dark-card border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-ink-soft mono-label">
                <th className="px-4 py-3 text-left font-normal">Mijoz</th>
                <th className="px-4 py-3 text-left font-normal">Mashina</th>
                <th className="px-4 py-3 text-left font-normal">Muammo</th>
                <th className="px-4 py-3 text-left font-normal">Tanlangan usta</th>
                <th className="px-4 py-3 text-left font-normal">Yo'naltirilgan</th>
                <th className="px-4 py-3 text-left font-normal">Status</th>
                <th className="px-4 py-3 text-left font-normal">Amallar</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={7} className="text-center py-8 text-ink-soft">Yuklanmoqda...</td></tr>
              ) : requests.length === 0 ? (
                <tr><td colSpan={7} className="text-center py-8 text-ink-soft">So'rov yo'q</td></tr>
              ) : requests.map((r) => (
                <tr key={r.id} className="border-b border-dark-border/50 hover:bg-dark-input/30 transition-colors align-top">
                  <td className="px-4 py-3">
                    <div className="text-ink">{r.user?.full_name || '—'}</div>
                    <a href={`tel:${r.phone}`} className="text-accent text-xs hover:underline">{r.phone}</a>
                  </td>
                  <td className="px-4 py-3 text-ink-mute text-xs">{r.car_info || '—'}</td>
                  <td className="px-4 py-3 text-ink-mute text-xs max-w-xs">{r.description}</td>
                  <td className="px-4 py-3 text-xs text-ink-mute">
                    {r.preferred_mechanic?.workshop_name || r.preferred_mechanic?.user?.full_name || '—'}
                  </td>
                  <td className="px-4 py-3 text-xs">
                    {r.assigned_mechanic
                      ? <span className="text-ink">{r.assigned_mechanic.workshop_name || r.assigned_mechanic.user?.full_name}</span>
                      : <span className="text-ink-soft">—</span>}
                  </td>
                  <td className="px-4 py-3"><span className={`status-${r.status}`}>{STATUS_LABELS[r.status]}</span></td>
                  <td className="px-4 py-3">
                    <button onClick={() => openModal(r)} className="text-xs bg-accent/10 text-accent hover:bg-accent/20 px-3 py-1.5 transition-colors">
                      Boshqarish
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {modal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="bg-dark-card p-6 w-full max-w-md border border-dark-border">
            <h3 className="font-display text-lg font-semibold mb-4 text-ink">Tamirlash so'rovi</h3>
            <div className="space-y-3 text-sm">
              <div className="bg-dark-input/40 p-3 space-y-1">
                <div><span className="text-ink-soft">Mijoz:</span> <span className="text-ink">{modal.user?.full_name || '—'}</span></div>
                <div><span className="text-ink-soft">Raqam:</span> <a href={`tel:${modal.phone}`} className="text-accent">{modal.phone}</a></div>
                <div><span className="text-ink-soft">Mashina:</span> <span className="text-ink">{modal.car_info || '—'}</span></div>
                <div><span className="text-ink-soft">Muammo:</span> <span className="text-ink">{modal.description}</span></div>
                {modal.preferred_mechanic && (
                  <div><span className="text-ink-soft">Mijoz tanlagan:</span> <span className="text-ink">{modal.preferred_mechanic.workshop_name || modal.preferred_mechanic.user?.full_name}</span></div>
                )}
              </div>

              <div>
                <label className="block mono-label text-ink-soft mb-1.5">Ustaga yo'naltirish</label>
                <div className="flex gap-2">
                  <select
                    value={form.mechanic_id}
                    onChange={(e) => setForm(p => ({ ...p, mechanic_id: e.target.value }))}
                    className="flex-1 bg-dark-input border border-dark-border px-3 py-2.5 text-ink focus:outline-none focus:border-accent"
                  >
                    <option value="">— usta tanlang —</option>
                    {mechanics.map((m) => (
                      <option key={m.id} value={m.id}>{m.workshop_name || m.user?.full_name} ({m.user?.full_name})</option>
                    ))}
                  </select>
                  <button onClick={handleAssign} disabled={!form.mechanic_id} className="px-4 py-2.5 bg-accent text-white font-semibold text-sm disabled:opacity-40 whitespace-nowrap">
                    Yo'naltirish
                  </button>
                </div>
              </div>

              <div>
                <label className="block mono-label text-ink-soft mb-1.5">Operator izohi</label>
                <textarea
                  value={form.admin_notes}
                  onChange={(e) => setForm(p => ({ ...p, admin_notes: e.target.value }))}
                  rows={2}
                  className="w-full bg-dark-input border border-dark-border px-3 py-2.5 text-ink focus:outline-none focus:border-accent resize-none"
                />
              </div>
              <div>
                <label className="block mono-label text-ink-soft mb-1.5">Status</label>
                <select
                  value={form.status}
                  onChange={(e) => setForm(p => ({ ...p, status: e.target.value }))}
                  className="w-full bg-dark-input border border-dark-border px-3 py-2.5 text-ink focus:outline-none focus:border-accent"
                >
                  {STATUS_OPTIONS.map((s) => <option key={s} value={s}>{STATUS_LABELS[s]}</option>)}
                </select>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setModal(null)} className="flex-1 py-2.5 bg-dark-input text-sm text-ink-mute">Yopish</button>
              <button onClick={handleStatus} className="flex-1 py-2.5 bg-accent text-white font-semibold text-sm">Statusni saqlash</button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
