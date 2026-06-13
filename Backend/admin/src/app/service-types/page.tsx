'use client'
import { useEffect, useState } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import api from '@/lib/api'

interface ServiceType {
  id: string
  slug: string
  name_uz: string
  name_ru: string
  icon: string
  base_price: number
  is_active: boolean
}

// â”€â”€ SVG icon library â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const ICON_LIST: { id: string; label: string; svg: React.ReactNode }[] = [
  {
    id: 'wheel',
    label: "G'ildirak / shina almashtirish",
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/><line x1="12" y1="2" x2="12" y2="9"/><line x1="12" y1="15" x2="22" y2="12" transform="rotate(60 12 12)"/><line x1="12" y1="15" x2="22" y2="12" transform="rotate(-60 12 12)"/></svg>,
  },
  {
    id: 'pump',
    label: 'Podkachka â€” havo bosimini tekshirish',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2v6M8 8h8l1 10H7L8 8z"/><path d="M9 18v3M15 18v3"/><path d="M7 8c0-2.2 2.2-4 5-4s5 1.8 5 4"/></svg>,
  },
  {
    id: 'balance',
    label: 'BalansÐ¸Ñ€Ð¾Ð²ÐºÐ° â€” g\'ildirak muvozanati',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="3" x2="12" y2="21"/><path d="M5 7l7-4 7 4"/><path d="M4 17l3-6 5 3 5-3 3 6"/></svg>,
  },
  {
    id: 'alignment',
    label: 'Razvval-sxojdeniye â€” ko\'ndalang moslash',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18M3 12h18M3 18h18"/><path d="M8 3l-5 3 5 3"/><path d="M16 15l5 3-5 3"/></svg>,
  },
  {
    id: 'wrench',
    label: 'Ta\'mirlash â€” mexanik ta\'mirlar',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>,
  },
  {
    id: 'snowflake',
    label: 'Qish shinasi â€” qishki g\'ildirak o\'rnatish',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="2" x2="12" y2="22"/><path d="M17 7l-5 5-5-5"/><path d="M17 17l-5-5-5 5"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M7 7l5 5 5-5"/><path d="M7 17l5-5 5 5"/></svg>,
  },
  {
    id: 'sun',
    label: 'Yoz shinasi â€” yozgi g\'ildirak o\'rnatish',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>,
  },
  {
    id: 'rim',
    label: 'Disk ta\'mirlash â€” g\'ildirak diskini tiklash',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="4"/><line x1="12" y1="2" x2="12" y2="8"/><line x1="12" y1="16" x2="12" y2="22"/><line x1="2" y1="12" x2="8" y2="12"/><line x1="16" y1="12" x2="22" y2="12"/><line x1="4.93" y1="4.93" x2="9.17" y2="9.17"/><line x1="14.83" y1="14.83" x2="19.07" y2="19.07"/></svg>,
  },
  {
    id: 'car',
    label: 'Umumiy avtomobil xizmati',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M5 17H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1l2-3h10l2 3h1a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2h-2"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/></svg>,
  },
  {
    id: 'gauge',
    label: 'Bosim o\'lchash â€” shina bosimini diagnostika',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2a10 10 0 1 0 10 10"/><path d="M12 6v6l4 2"/><circle cx="18" cy="6" r="3"/></svg>,
  },
  {
    id: 'shield',
    label: 'Kafolat â€” xizmat kafolati',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>,
  },
  {
    id: 'check',
    label: 'Texnik ko\'rik â€” avtomobil tekshiruvi',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>,
  },
  {
    id: 'clock',
    label: 'Tez xizmat â€” express ta\'mirlash',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>,
  },
  {
    id: 'zap',
    label: 'Elektr tizimi â€” akkumulator, elektr',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>,
  },
  {
    id: 'droplet',
    label: 'Suyuqlik â€” moy, antifriz almashtirish',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>,
  },
  {
    id: 'search',
    label: 'Diagnostika â€” kompyuter diagnostikasi',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>,
  },
  {
    id: 'settings',
    label: 'Sozlash â€” umumiy sozlash ishlari',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>,
  },
  {
    id: 'tool',
    label: 'Mexanik ishlar â€” har qanday ta\'mirlash',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z"/><path d="M13 13l6 6"/></svg>,
  },
  {
    id: 'star',
    label: 'Premium xizmat â€” VIP mijozlar uchun',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>,
  },
  {
    id: 'package',
    label: 'To\'liq paket â€” kompleks xizmat',
    svg: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21"/><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>,
  },
]

const toSlug = (s: string) =>
  s.toLowerCase().trim().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '').substring(0, 40) || `type_${Date.now()}`

const emptyForm = { name_uz: '', name_ru: '', icon: 'wheel', base_price: '' as string, is_active: true }

export default function ServiceTypesPage() {
  const [types, setTypes] = useState<ServiceType[]>([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(false)
  const [editItem, setEditItem] = useState<ServiceType | null>(null)
  const [form, setForm] = useState({ ...emptyForm })
  const [saving, setSaving] = useState(false)
  const [tooltip, setTooltip] = useState('')

  const fetchTypes = () => {
    setLoading(true)
    api.get('/admin/service-types')
      .then((r) => {
        const d = r.data.data
        setTypes(Array.isArray(d) ? d : d?.types ?? [])
      })
      .catch(console.error)
      .finally(() => setLoading(false))
  }

  useEffect(() => { fetchTypes() }, [])

  const iconNode = (id: string) => ICON_LIST.find(i => i.id === id)?.svg ?? ICON_LIST[0].svg

  const openCreate = () => { setEditItem(null); setForm({ ...emptyForm }); setModal(true) }
  const openEdit = (t: ServiceType) => {
    setEditItem(t)
    setForm({
      name_uz: t.name_uz,
      name_ru: t.name_ru,
      icon: t.icon || 'wheel',
      base_price: t.base_price > 0 ? String(t.base_price) : '',
      is_active: t.is_active,
    })
    setModal(true)
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    try {
      const payload = {
        ...form,
        base_price: Number(form.base_price) || 0,
        slug: editItem?.slug || toSlug(form.name_uz),
      }
      if (editItem) {
        await api.put(`/admin/service-types/${editItem.id}`, payload)
      } else {
        await api.post('/admin/service-types', payload)
      }
      setModal(false)
      fetchTypes()
    } catch (e) { console.error(e) }
    finally { setSaving(false) }
  }

  return (
    <AdminShell title="Xizmat turlari katalogi">
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <p className="text-text3 text-sm">{types.length} ta xizmat turi</p>
          <button onClick={openCreate} className="btn-primary">+ Qo'shish</button>
        </div>

        {loading ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="card p-4 animate-pulse space-y-2">
                <div className="h-8 w-8 bg-surface2 rounded" />
                <div className="h-4 bg-surface2 rounded w-24" />
                <div className="h-3 bg-surface2 rounded w-16" />
              </div>
            ))}
          </div>
        ) : types.length === 0 ? (
          <div className="card p-10 text-center text-text3">Xizmat turlari yo'q</div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {types.map((t) => (
              <button key={t.id} onClick={() => openEdit(t)}
                className="card p-4 text-left hover:bg-surface2 transition-colors group">
                <div className="w-8 h-8 mb-3 text-text2 group-hover:text-gold transition-colors">
                  {iconNode(t.icon)}
                </div>
                <p className="text-text font-semibold text-sm group-hover:text-gold transition-colors truncate">{t.name_uz}</p>
                <p className="text-text3 text-xs mt-0.5 truncate">{t.name_ru}</p>
                {t.base_price > 0 && (
                  <p className="text-text2 text-xs mt-1">{t.base_price.toLocaleString()} so'm</p>
                )}
                {!t.is_active && (
                  <span className="badge badge-cancelled mt-2 inline-block">Nofaol</span>
                )}
              </button>
            ))}
          </div>
        )}
      </div>

      {modal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4 overflow-y-auto">
          <div className="card p-6 w-full max-w-md space-y-5 my-8">
            <h3 className="text-text font-semibold">
              {editItem ? 'Xizmat turini tahrirlash' : 'Yangi xizmat turi'}
            </h3>
            <form onSubmit={handleSave} className="space-y-4">

              {/* Icon picker */}
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-3">
                  Icon tanlang
                </label>
                <div className="grid grid-cols-5 gap-2">
                  {ICON_LIST.map((ic) => {
                    const active = form.icon === ic.id
                    return (
                      <button
                        key={ic.id}
                        type="button"
                        onMouseEnter={() => setTooltip(ic.label)}
                        onMouseLeave={() => setTooltip('')}
                        onClick={() => setForm(f => ({ ...f, icon: ic.id }))}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          padding: 10,
                          borderRadius: 10,
                          border: active ? '1.5px solid rgba(255,255,255,0.3)' : '1.5px solid transparent',
                          background: active ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.03)',
                          color: active ? 'var(--text)' : 'var(--text3)',
                          cursor: 'pointer',
                          transition: 'all 0.12s',
                          width: '100%',
                          aspectRatio: '1',
                        }}
                        onMouseOver={(e) => {
                          if (!active) (e.currentTarget as HTMLElement).style.background = 'rgba(255,255,255,0.07)'
                        }}
                        onMouseOut={(e) => {
                          if (!active) (e.currentTarget as HTMLElement).style.background = 'rgba(255,255,255,0.03)'
                        }}
                      >
                        <span style={{ width: 22, height: 22, display: 'block' }}>{ic.svg}</span>
                      </button>
                    )
                  })}
                </div>

                {/* Tooltip */}
                <div style={{
                  minHeight: 28,
                  marginTop: 8,
                  padding: '4px 10px',
                  borderRadius: 6,
                  background: tooltip ? 'rgba(255,255,255,0.06)' : 'transparent',
                  fontSize: 12,
                  color: 'var(--text2)',
                  transition: 'all 0.15s',
                }}>
                  {tooltip || ' '}
                </div>
              </div>

              {/* Nomi UZ */}
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">
                  Nomi (O'zbek) *
                </label>
                <input type="text" value={form.name_uz} required className="inp"
                  placeholder="G'ildirak almashtirish"
                  onChange={(e) => setForm(f => ({ ...f, name_uz: e.target.value }))} />
              </div>

              {/* Nomi RU */}
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">
                  Nomi (Rus)
                </label>
                <input type="text" value={form.name_ru} className="inp"
                  placeholder="Ð—Ð°Ð¼ÐµÐ½Ð° ÑˆÐ¸Ð½"
                  onChange={(e) => setForm(f => ({ ...f, name_ru: e.target.value }))} />
              </div>

              {/* Narx */}
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">
                  Taxminiy narx (so'm) â€” ixtiyoriy
                </label>
                <input type="number" min={0} value={form.base_price} className="inp"
                  placeholder="50000"
                  onChange={(e) => setForm(f => ({ ...f, base_price: e.target.value }))} />
              </div>

              {/* Toggle */}
              <label className="flex items-center gap-3 cursor-pointer select-none">
                <div className={`w-10 h-5 rounded-full transition-colors ${form.is_active ? 'bg-success' : 'bg-surface3'} relative`}>
                  <div className={`absolute top-0.5 w-4 h-4 rounded-full bg-text transition-transform ${form.is_active ? 'translate-x-5' : 'translate-x-0.5'}`} />
                </div>
                <input type="checkbox" className="hidden" checked={form.is_active}
                  onChange={(e) => setForm(f => ({ ...f, is_active: e.target.checked }))} />
                <span className="text-text2 text-sm">Faol</span>
              </label>

              <div className="flex gap-2 pt-1">
                <button type="button" onClick={() => setModal(false)} className="btn-ghost flex-1">Bekor</button>
                <button type="submit" disabled={saving} className="btn-primary flex-1">
                  {saving ? 'Saqlanmoqda...' : 'Saqlash'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AdminShell>
  )
}
