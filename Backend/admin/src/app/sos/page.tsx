'use client'
import { useEffect, useRef, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'
import { connectAdminSocket } from '@/lib/ws'

interface Mechanic {
  id: string
  user: { full_name: string; phone: string } | null
  workshop_name: string
}

interface SosRequest {
  id: string
  user: { full_name: string; phone: string } | null
  phone: string
  latitude: number
  longitude: number
  address: string
  status: string
  admin_notes: string
  assigned_mechanic_id: string | null
  assigned_mechanic: { id: string; workshop_name: string; user: { full_name: string } | null } | null
  created_at: string
  resolved_at: string | null
}

const STATUS_LABELS: Record<string, string> = {
  new: 'Yangi',
  in_progress: 'Jarayonda',
  resolved: 'Hal qilindi',
  cancelled: 'Bekor qilindi',
}

const STATUS_OPTIONS = ['new', 'in_progress', 'resolved', 'cancelled']

export default function SosPage() {
  const [requests, setRequests] = useState<SosRequest[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState('new')
  const [page, setPage] = useState(1)
  const [modal, setModal] = useState<SosRequest | null>(null)
  const [form, setForm] = useState({ status: 'in_progress', admin_notes: '', mechanic_id: '' })
  const [mechanics, setMechanics] = useState<Mechanic[]>([])
  const [live, setLive] = useState(false)
  const [flashId, setFlashId] = useState<string | null>(null)

  const statusRef = useRef(status)
  statusRef.current = status

  const fetchRequests = () => {
    setLoading(true)
    api.get('/admin/sos', { params: { status, page, limit: 20 } })
      .then((res) => { setRequests(res.data.data.requests || []); setTotal(res.data.data.total) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchRequests() }, [status, page])

  // Tasdiqlangan ustalar — yo'naltirish uchun.
  useEffect(() => {
    api.get('/admin/mechanics', { params: { limit: 100 } })
      .then((res) => {
        const list: Mechanic[] = (res.data.data.mechanics || []).filter(
          (m: any) => m.verification_status === 'verified',
        )
        setMechanics(list)
      })
      .catch(() => {})
  }, [])

  // WebSocket — real-time SOS (refreshsiz).
  useEffect(() => {
    const ws = connectAdminSocket(
      (type, data) => {
        if (type === 'sos.created') {
          // Faqat ko'rilayotgan "new" filtriga mos kelsa qo'shamiz.
          if (statusRef.current === 'new') {
            setRequests((prev) => {
              if (prev.some((r) => r.id === data.id)) return prev
              return [data, ...prev]
            })
            setTotal((t) => t + 1)
            setFlashId(data.id)
            setTimeout(() => setFlashId((id) => (id === data.id ? null : id)), 4000)
            // ovozli/title signal
            if (typeof document !== 'undefined') document.title = '🆘 Yangi SOS — Moshn Admin'
          }
        } else if (type === 'sos.updated') {
          setRequests((prev) =>
            prev.map((r) => (r.id === data.id ? { ...r, ...data } : r))
              // statusi o'zgarib filtrdan chiqsa olib tashlaymiz
              .filter((r) => r.status === statusRef.current),
          )
        }
      },
      (connected) => setLive(connected),
    )
    return () => { ws?.close() }
  }, [])

  const openModal = (r: SosRequest) => {
    setModal(r)
    setForm({
      status: r.status === 'new' ? 'in_progress' : r.status,
      admin_notes: r.admin_notes || '',
      mechanic_id: r.assigned_mechanic_id || '',
    })
    if (typeof document !== 'undefined') document.title = 'Moshn Admin'
  }

  const handleUpdate = async () => {
    if (!modal) return
    try {
      await api.put(`/admin/sos/${modal.id}/status`, { status: form.status, admin_notes: form.admin_notes })
      setModal(null)
      fetchRequests()
    } catch (e) { console.error(e) }
  }

  const handleAssign = async () => {
    if (!modal || !form.mechanic_id) return
    try {
      await api.put(`/admin/sos/${modal.id}/assign`, { mechanic_id: form.mechanic_id, admin_notes: form.admin_notes })
      setModal(null)
      fetchRequests()
    } catch (e) { console.error(e) }
  }

  return (
    <AdminLayout title="SOS so'rovlari">
      <div className="space-y-4">
        <div className="flex gap-3 flex-wrap items-center">
          {STATUS_OPTIONS.map((s) => (
            <button
              key={s}
              onClick={() => { setStatus(s); setPage(1) }}
              className={`px-4 py-2 text-sm transition-colors ${
                status === s ? 'bg-accent text-white font-semibold' : 'bg-dark-card text-ink-mute hover:bg-dark-input'
              }`}
            >
              {STATUS_LABELS[s]}
            </button>
          ))}
          <span className="ml-auto flex items-center gap-2 mono-label">
            <span className={`w-2 h-2 rounded-full ${live ? 'bg-emerald-400 animate-pulse' : 'bg-ink-soft'}`} />
            <span className={live ? 'text-emerald-400' : 'text-ink-soft'}>{live ? 'Jonli' : 'Uzilgan'}</span>
            <span className="text-ink-soft">· Jami {total}</span>
          </span>
        </div>

        <div className="bg-dark-card border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-ink-soft mono-label">
                <th className="px-4 py-3 text-left font-normal">Foydalanuvchi</th>
                <th className="px-4 py-3 text-left font-normal">Aloqa raqami</th>
                <th className="px-4 py-3 text-left font-normal">Manzil</th>
                <th className="px-4 py-3 text-left font-normal">Usta</th>
                <th className="px-4 py-3 text-left font-normal">Xarita</th>
                <th className="px-4 py-3 text-left font-normal">Status</th>
                <th className="px-4 py-3 text-left font-normal">Sana</th>
                <th className="px-4 py-3 text-left font-normal">Amallar</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={8} className="text-center py-8 text-ink-soft">Yuklanmoqda...</td></tr>
              ) : requests.length === 0 ? (
                <tr><td colSpan={8} className="text-center py-8 text-ink-soft">So'rov yo'q</td></tr>
              ) : requests.map((r) => (
                <tr
                  key={r.id}
                  className={`border-b border-dark-border/50 transition-colors ${
                    flashId === r.id ? 'bg-accent/15 animate-pulse' : 'hover:bg-dark-input/30'
                  }`}
                >
                  <td className="px-4 py-3">
                    <div className="text-ink">{r.user?.full_name || '—'}</div>
                    <div className="text-ink-soft text-xs">{r.user?.phone}</div>
                  </td>
                  <td className="px-4 py-3 font-medium">
                    <a href={`tel:${r.phone}`} className="text-accent hover:underline">{r.phone}</a>
                  </td>
                  <td className="px-4 py-3 max-w-xs text-ink-mute text-xs">
                    {r.address || <span className="text-ink-soft">{r.latitude.toFixed(5)}, {r.longitude.toFixed(5)}</span>}
                  </td>
                  <td className="px-4 py-3 text-xs">
                    {r.assigned_mechanic
                      ? <span className="text-ink">{r.assigned_mechanic.workshop_name || r.assigned_mechanic.user?.full_name}</span>
                      : <span className="text-ink-soft">—</span>}
                  </td>
                  <td className="px-4 py-3">
                    <a
                      href={`https://www.openstreetmap.org/?mlat=${r.latitude}&mlon=${r.longitude}#map=17/${r.latitude}/${r.longitude}`}
                      target="_blank"
                      rel="noreferrer"
                      className="text-xs bg-accent/10 text-accent hover:bg-accent/20 px-3 py-1.5 transition-colors inline-block"
                    >
                      📍 Ochish
                    </a>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`status-${r.status}`}>{STATUS_LABELS[r.status]}</span>
                  </td>
                  <td className="px-4 py-3 text-ink-soft">{new Date(r.created_at).toLocaleString('uz')}</td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => openModal(r)}
                      className="text-xs bg-accent/10 text-accent hover:bg-accent/20 px-3 py-1.5 transition-colors"
                    >
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
            <h3 className="font-display text-lg font-semibold mb-4 text-ink">SOS so'rovini boshqarish</h3>
            <div className="space-y-3 text-sm">
              <div className="bg-dark-input/40 p-3 space-y-1">
                <div><span className="text-ink-soft">Mijoz:</span> <span className="text-ink">{modal.user?.full_name || '—'}</span></div>
                <div><span className="text-ink-soft">Raqam:</span> <a href={`tel:${modal.phone}`} className="text-accent">{modal.phone}</a></div>
                <div><span className="text-ink-soft">Manzil:</span> <span className="text-ink">{modal.address || '—'}</span></div>
                <div><span className="text-ink-soft">Koordinatalar:</span> <span className="text-ink">{modal.latitude.toFixed(5)}, {modal.longitude.toFixed(5)}</span></div>
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
                      <option key={m.id} value={m.id}>
                        {m.workshop_name || m.user?.full_name} ({m.user?.full_name})
                      </option>
                    ))}
                  </select>
                  <button
                    onClick={handleAssign}
                    disabled={!form.mechanic_id}
                    className="px-4 py-2.5 bg-accent text-white font-semibold text-sm disabled:opacity-40 whitespace-nowrap"
                  >
                    Yo'naltirish
                  </button>
                </div>
                {modal.assigned_mechanic && (
                  <p className="text-xs text-ink-soft mt-1.5">
                    Hozir: {modal.assigned_mechanic.workshop_name || modal.assigned_mechanic.user?.full_name}
                  </p>
                )}
              </div>

              <div>
                <label className="block mono-label text-ink-soft mb-1.5">Status</label>
                <select
                  value={form.status}
                  onChange={(e) => setForm(p => ({ ...p, status: e.target.value }))}
                  className="w-full bg-dark-input border border-dark-border px-3 py-2.5 text-ink focus:outline-none focus:border-accent"
                >
                  {STATUS_OPTIONS.map((s) => (
                    <option key={s} value={s}>{STATUS_LABELS[s]}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block mono-label text-ink-soft mb-1.5">Operator izohi</label>
                <textarea
                  value={form.admin_notes}
                  onChange={(e) => setForm(p => ({ ...p, admin_notes: e.target.value }))}
                  rows={3}
                  className="w-full bg-dark-input border border-dark-border px-3 py-2.5 text-ink focus:outline-none focus:border-accent resize-none"
                />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setModal(null)} className="flex-1 py-2.5 bg-dark-input text-sm text-ink-mute">Yopish</button>
              <button onClick={handleUpdate} className="flex-1 py-2.5 bg-accent text-white font-semibold text-sm">Statusni saqlash</button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
