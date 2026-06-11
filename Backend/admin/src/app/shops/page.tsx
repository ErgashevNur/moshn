'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Shop {
  id: string
  shop_name: string
  address: string
  phone: string
  working_hours: string
  service_types: string[]
  verification_status: string
  rating_avg: number
  rating_count: number
  total_bookings: number
  created_at: string
  user: { full_name: string; phone: string; email: string }
}

interface VerifyModal {
  id: string
  name: string
}

const STATUS_LABEL: Record<string, string> = {
  pending:  'Kutilmoqda',
  verified: 'Tasdiqlangan',
  rejected: 'Rad etilgan',
}

export default function ShopsPage() {
  const [shops, setShops] = useState<Shop[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [modal, setModal] = useState<VerifyModal | null>(null)
  const [verifyStatus, setVerifyStatus] = useState<'verified' | 'rejected'>('verified')
  const [notes, setNotes] = useState('')
  const [saving, setSaving] = useState(false)
  const [createModal, setCreateModal] = useState(false)
  const [newShop, setNewShop] = useState({
    email: '', password: '', full_name: '', shop_name: '',
    address: '', phone: '', latitude: '', longitude: '', working_hours: '',
  })

  const fetchShops = () => {
    setLoading(true)
    const params: Record<string, unknown> = { page, limit: 20 }
    if (status) params.status = status
    api.get('/admin/shops', { params })
      .then((r) => { setShops(r.data.data.shops ?? []); setTotal(r.data.data.total ?? 0) })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchShops() }, [status, page])

  const handleVerify = async () => {
    if (!modal) return
    setSaving(true)
    try {
      await api.put(`/admin/shops/${modal.id}/verify`, { status: verifyStatus, notes })
      setModal(null)
      setNotes('')
      fetchShops()
    } catch (e) { console.error(e) }
    finally { setSaving(false) }
  }

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/admin/shops', {
        ...newShop,
        latitude: parseFloat(newShop.latitude) || 0,
        longitude: parseFloat(newShop.longitude) || 0,
      })
      setCreateModal(false)
      setNewShop({ email: '', password: '', full_name: '', shop_name: '', address: '', phone: '', latitude: '', longitude: '', working_hours: '' })
      fetchShops()
    } catch (e) { console.error(e) }
    finally { setSaving(false) }
  }

  return (
    <AdminLayout title="Shinomontajlar">
      <div className="space-y-4">
        {/* Toolbar */}
        <div className="flex flex-wrap gap-3 items-center">
          {['', 'pending', 'verified', 'rejected'].map((s) => (
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
          <span className="text-text3 text-sm ml-auto">{total} ta</span>
          <button onClick={() => setCreateModal(true)} className="btn-primary">+ Qo'shish</button>
        </div>

        {/* Table */}
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border text-text3 text-xs font-mono uppercase tracking-wide">
                <th className="px-4 py-3 text-left">Shinomontaj</th>
                <th className="px-4 py-3 text-left">Egasi</th>
                <th className="px-4 py-3 text-left">Manzil</th>
                <th className="px-4 py-3 text-left">Reyting</th>
                <th className="px-4 py-3 text-left">Bronlar</th>
                <th className="px-4 py-3 text-left">Holat</th>
                <th className="px-4 py-3 text-left">Amal</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 7 }).map((__, j) => (
                      <td key={j} className="px-4 py-3"><div className="h-4 bg-surface2 rounded w-20" /></td>
                    ))}
                  </tr>
                ))
              ) : shops.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-text3">Shinomontaj topilmadi</td></tr>
              ) : shops.map((s) => (
                <tr key={s.id} className="hover:bg-surface2/50 transition-colors">
                  <td className="px-4 py-3">
                    <p className="text-text font-medium">{s.shop_name || '—'}</p>
                    {s.phone && <p className="text-text3 text-xs font-mono">{s.phone}</p>}
                  </td>
                  <td className="px-4 py-3">
                    <p className="text-text2">{s.user?.full_name || '—'}</p>
                    <p className="text-text3 text-xs font-mono">{s.user?.phone}</p>
                  </td>
                  <td className="px-4 py-3 text-text2 text-xs max-w-[160px] truncate">{s.address}</td>
                  <td className="px-4 py-3">
                    <span className="text-gold font-medium">{s.rating_avg?.toFixed(1) ?? '0.0'}</span>
                    <span className="text-text3 text-xs ml-1">({s.rating_count})</span>
                  </td>
                  <td className="px-4 py-3 text-text2">{s.total_bookings}</td>
                  <td className="px-4 py-3">
                    <span className={`badge badge-${s.verification_status}`}>
                      {STATUS_LABEL[s.verification_status] ?? s.verification_status}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {s.verification_status !== 'verified' && (
                      <button
                        onClick={() => setModal({ id: s.id, name: s.shop_name })}
                        className="text-xs text-info hover:text-info/80 transition-colors"
                      >
                        Tasdiqlash
                      </button>
                    )}
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

      {/* Verify modal */}
      {modal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="card p-6 w-full max-w-sm space-y-4">
            <h3 className="text-text font-semibold">Tasdiqlash: {modal.name}</h3>
            <div className="grid grid-cols-2 gap-2">
              {(['verified', 'rejected'] as const).map((st) => (
                <button key={st} onClick={() => setVerifyStatus(st)}
                  className={`py-2.5 rounded-md text-sm font-medium border transition-colors ${
                    verifyStatus === st
                      ? st === 'verified' ? 'border-success/40 bg-success-dim text-success' : 'border-danger/40 bg-danger-dim text-danger'
                      : 'border-border text-text3 hover:text-text2'
                  }`}>
                  {st === 'verified' ? 'Tasdiqlash' : 'Rad etish'}
                </button>
              ))}
            </div>
            <div>
              <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1.5">Izoh (ixtiyoriy)</label>
              <textarea value={notes} onChange={(e) => setNotes(e.target.value)}
                rows={3} className="inp resize-none" placeholder="Sabab..." />
            </div>
            <div className="flex gap-2">
              <button onClick={() => setModal(null)} className="btn-ghost flex-1">Bekor</button>
              <button onClick={handleVerify} disabled={saving} className="btn-primary flex-1">
                {saving ? 'Saqlanmoqda...' : 'Saqlash'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create modal */}
      {createModal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 overflow-y-auto">
          <div className="card p-6 w-full max-w-md space-y-4 my-8">
            <h3 className="text-text font-semibold">Yangi shinomontaj qo'shish</h3>
            <form onSubmit={handleCreate} className="space-y-3">
              {[
                { key: 'email',        label: 'Email',       type: 'email',    ph: 'admin@shina24.uz' },
                { key: 'password',     label: 'Parol',       type: 'password', ph: '••••••' },
                { key: 'full_name',    label: 'Egasi ismi',  type: 'text',     ph: 'Abdullayev Javlon' },
                { key: 'shop_name',    label: 'Servis nomi', type: 'text',     ph: 'Shina24 Yunusobod' },
                { key: 'address',      label: 'Manzil',      type: 'text',     ph: 'Yunusobod t., 5-uy' },
                { key: 'phone',        label: 'Telefon',     type: 'text',     ph: '+998901234567' },
                { key: 'latitude',     label: 'Kenglik',     type: 'number',   ph: '41.299496' },
                { key: 'longitude',    label: 'Uzunlik',     type: 'number',   ph: '69.240073' },
                { key: 'working_hours',label: 'Ish vaqti',   type: 'text',     ph: '08:00-20:00' },
              ].map(({ key, label, type, ph }) => (
                <div key={key}>
                  <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">{label}</label>
                  <input type={type} value={(newShop as any)[key]}
                    onChange={(e) => setNewShop(prev => ({ ...prev, [key]: e.target.value }))}
                    placeholder={ph} className="inp"
                    required={['email','password','full_name','address'].includes(key)}
                  />
                </div>
              ))}
              <div className="flex gap-2 pt-2">
                <button type="button" onClick={() => setCreateModal(false)} className="btn-ghost flex-1">Bekor</button>
                <button type="submit" disabled={saving} className="btn-primary flex-1">
                  {saving ? 'Qo\'shilmoqda...' : 'Qo\'shish'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
