'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Rule {
  id: string
  name: string
  send_month: number
  send_day: number
  message_uz: string
  message_ru: string
  is_active: boolean
  last_sent_at: string | null
  created_at: string
}

const MONTHS = [
  '', 'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
  'Iyul', 'Avgust', 'Sentyabr', 'Oktyabr', 'Noyabr', 'Dekabr',
]

const emptyForm = {
  name: '', send_month: 10, send_day: 1,
  message_uz: '', message_ru: '', is_active: true,
}

export default function SeasonalPage() {
  const [rules, setRules] = useState<Rule[]>([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(false)
  const [editRule, setEditRule] = useState<Rule | null>(null)
  const [form, setForm] = useState({ ...emptyForm })
  const [saving, setSaving] = useState(false)
  const [sendingId, setSendingId] = useState<string | null>(null)

  const fetchRules = () => {
    setLoading(true)
    api.get('/admin/seasonal-rules')
      .then((r) => setRules(r.data.data?.rules ?? r.data.data ?? []))
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchRules() }, [])

  const openCreate = () => { setEditRule(null); setForm({ ...emptyForm }); setModal(true) }
  const openEdit = (r: Rule) => {
    setEditRule(r)
    setForm({ name: r.name, send_month: r.send_month, send_day: r.send_day, message_uz: r.message_uz, message_ru: r.message_ru, is_active: r.is_active })
    setModal(true)
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    try {
      if (editRule) {
        await api.put(`/admin/seasonal-rules/${editRule.id}`, form)
      } else {
        await api.post('/admin/seasonal-rules', form)
      }
      setModal(false)
      fetchRules()
    } catch (e) { console.error(e) }
    finally { setSaving(false) }
  }

  const handleSendNow = async (id: string) => {
    setSendingId(id)
    try { await api.post(`/admin/seasonal-rules/${id}/send`); fetchRules() }
    catch (e) { console.error(e) }
    finally { setSendingId(null) }
  }

  return (
    <AdminLayout title="Mavsum bildirshnoma qoidalari">
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <p className="text-text3 text-sm">{rules.length} ta qoida</p>
          <button onClick={openCreate} className="btn-primary">+ Qoida qo'shish</button>
        </div>

        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="card p-4 animate-pulse">
                <div className="h-5 bg-surface2 rounded w-48 mb-2" />
                <div className="h-4 bg-surface2 rounded w-32" />
              </div>
            ))}
          </div>
        ) : rules.length === 0 ? (
          <div className="card p-10 text-center text-text3">
            Hali qoida qo'shilmagan
          </div>
        ) : (
          <div className="space-y-3">
            {rules.map((r) => (
              <div key={r.id} className="card p-4">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="text-text font-semibold">{r.name}</p>
                      <span className={`badge ${r.is_active ? 'badge-confirmed' : 'badge-cancelled'}`}>
                        {r.is_active ? 'Faol' : 'Nofaol'}
                      </span>
                    </div>
                    <p className="text-text3 text-xs mt-1 font-mono">
                      {MONTHS[r.send_month]} {r.send_day}-kuni yuboriladi
                    </p>
                    <p className="text-text2 text-sm mt-2 truncate">{r.message_uz}</p>
                    {r.last_sent_at && (
                      <p className="text-text3 text-xs mt-1">
                        So'ngi yuborish: {new Date(r.last_sent_at).toLocaleDateString('uz-UZ')}
                      </p>
                    )}
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => handleSendNow(r.id)}
                      disabled={sendingId === r.id}
                      className="btn-ghost text-xs py-1.5 px-3 disabled:opacity-40"
                    >
                      {sendingId === r.id ? 'Yuborilmoqda...' : 'Hozir yuborish'}
                    </button>
                    <button onClick={() => openEdit(r)} className="btn-ghost text-xs py-1.5 px-3">
                      Tahrirlash
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Create/Edit modal */}
      {modal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 overflow-y-auto">
          <div className="card p-6 w-full max-w-md space-y-4 my-8">
            <h3 className="text-text font-semibold">
              {editRule ? 'Qoidani tahrirlash' : 'Yangi qoida'}
            </h3>
            <form onSubmit={handleSave} className="space-y-4">
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">Nomi</label>
                <input type="text" value={form.name} required
                  onChange={(e) => setForm(f => ({ ...f, name: e.target.value }))}
                  placeholder="Qish shinasi almashtirish" className="inp" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">Oy</label>
                  <select value={form.send_month}
                    onChange={(e) => setForm(f => ({ ...f, send_month: +e.target.value }))}
                    className="inp">
                    {MONTHS.slice(1).map((m, i) => (
                      <option key={i + 1} value={i + 1}>{m}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">Kun</label>
                  <input type="number" min={1} max={31} value={form.send_day}
                    onChange={(e) => setForm(f => ({ ...f, send_day: +e.target.value }))}
                    className="inp" />
                </div>
              </div>
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">Xabar (UZ)</label>
                <textarea rows={3} value={form.message_uz} required
                  onChange={(e) => setForm(f => ({ ...f, message_uz: e.target.value }))}
                  placeholder="Qish mavsumi keldi..." className="inp resize-none" />
              </div>
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">Xabar (RU)</label>
                <textarea rows={3} value={form.message_ru}
                  onChange={(e) => setForm(f => ({ ...f, message_ru: e.target.value }))}
                  placeholder="Наступил зимний сезон..." className="inp resize-none" />
              </div>
              <label className="flex items-center gap-3 cursor-pointer">
                <div className={`w-10 h-5 rounded-full transition-colors ${form.is_active ? 'bg-success' : 'bg-surface3'} relative`}>
                  <div className={`absolute top-0.5 w-4 h-4 rounded-full bg-text transition-transform ${form.is_active ? 'translate-x-5' : 'translate-x-0.5'}`} />
                </div>
                <input type="checkbox" className="hidden" checked={form.is_active}
                  onChange={(e) => setForm(f => ({ ...f, is_active: e.target.checked }))} />
                <span className="text-text2 text-sm">Faol</span>
              </label>
              <div className="flex gap-2 pt-2">
                <button type="button" onClick={() => setModal(false)} className="btn-ghost flex-1">Bekor</button>
                <button type="submit" disabled={saving} className="btn-primary flex-1">
                  {saving ? 'Saqlanmoqda...' : 'Saqlash'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
