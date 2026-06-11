'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
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

const emptyForm = { slug: '', name_uz: '', name_ru: '', icon: '', base_price: 0, is_active: true }

export default function ServiceTypesPage() {
  const [types, setTypes] = useState<ServiceType[]>([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(false)
  const [editItem, setEditItem] = useState<ServiceType | null>(null)
  const [form, setForm] = useState({ ...emptyForm })
  const [saving, setSaving] = useState(false)

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

  const openCreate = () => { setEditItem(null); setForm({ ...emptyForm }); setModal(true) }
  const openEdit = (t: ServiceType) => {
    setEditItem(t)
    setForm({ slug: t.slug, name_uz: t.name_uz, name_ru: t.name_ru, icon: t.icon, base_price: t.base_price, is_active: t.is_active })
    setModal(true)
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    try {
      if (editItem) {
        await api.put(`/admin/service-types/${editItem.id}`, form)
      } else {
        await api.post('/admin/service-types', form)
      }
      setModal(false)
      fetchTypes()
    } catch (e) { console.error(e) }
    finally { setSaving(false) }
  }

  return (
    <AdminLayout title="Xizmat turlari katalogi">
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
                <div className="text-2xl mb-2">{t.icon || '🔧'}</div>
                <p className="text-text font-semibold text-sm group-hover:text-gold transition-colors truncate">{t.name_uz}</p>
                <p className="text-text3 text-xs font-mono mt-0.5">{t.slug}</p>
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

      {/* Modal */}
      {modal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
          <div className="card p-6 w-full max-w-sm space-y-4">
            <h3 className="text-text font-semibold">
              {editItem ? 'Xizmat turini tahrirlash' : 'Yangi xizmat turi'}
            </h3>
            <form onSubmit={handleSave} className="space-y-3">
              {[
                { key: 'slug',    label: 'Slug',      ph: 'tire_change' },
                { key: 'name_uz', label: 'Nomi (UZ)', ph: 'G\'ildirak almashtirish' },
                { key: 'name_ru', label: 'Nomi (RU)', ph: 'Замена шин' },
                { key: 'icon',    label: 'Icon',      ph: '🔧' },
              ].map(({ key, label, ph }) => (
                <div key={key}>
                  <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">{label}</label>
                  <input type="text" value={(form as any)[key]} placeholder={ph} className="inp"
                    required={['slug', 'name_uz'].includes(key)}
                    onChange={(e) => setForm(f => ({ ...f, [key]: e.target.value }))} />
                </div>
              ))}
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1">Taxminiy narx (so'm)</label>
                <input type="number" min={0} value={form.base_price} className="inp"
                  onChange={(e) => setForm(f => ({ ...f, base_price: +e.target.value }))} />
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
