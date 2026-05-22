'use client'
import { useEffect, useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

interface Mechanic {
  id: string
  user: { full_name: string; phone: string }
  workshop_name: string
  workshop_address: string
  specialization: string[] | null
  star_level: number
  verification_status: string
  rating_avg: number
  total_services: number
}

const STATUS_LABELS: Record<string, string> = {
  pending: 'Kutilmoqda',
  verified: 'Tasdiqlangan',
  rejected: 'Rad etilgan',
}

const emptyForm = {
  full_name: '',
  phone: '',
  email: '',
  password: '',
  workshop_name: '',
  workshop_address: '',
  work_hours: '',
  specialization: '',
}

export default function RepairPage() {
  const [mechanics, setMechanics] = useState<Mechanic[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ ...emptyForm })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const fetchMechanics = async () => {
    setLoading(true)
    try {
      const res = await api.get('/admin/mechanics', { params: { limit: 50 } })
      setMechanics(res.data.data.mechanics || [])
      setTotal(res.data.data.total)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchMechanics() }, [])

  const set = (k: keyof typeof emptyForm, v: string) => setForm(p => ({ ...p, [k]: v }))

  const handleCreate = async () => {
    setError('')
    if (!form.full_name || !form.phone || !form.email || !form.password) {
      setError("Ism, telefon, email va parol majburiy")
      return
    }
    setSaving(true)
    try {
      await api.post('/admin/mechanics', {
        full_name: form.full_name,
        phone: form.phone,
        email: form.email,
        password: form.password,
        workshop_name: form.workshop_name,
        workshop_address: form.workshop_address,
        work_hours: form.work_hours,
        specialization: form.specialization
          .split(',')
          .map(s => s.trim())
          .filter(Boolean),
      })
      setForm({ ...emptyForm })
      setShowForm(false)
      fetchMechanics()
    } catch (e: any) {
      setError(e?.response?.data?.error || 'Usta qo\'shishda xatolik')
    } finally {
      setSaving(false)
    }
  }

  const field = (label: string, key: keyof typeof emptyForm, opts?: { type?: string; placeholder?: string }) => (
    <div>
      <label className="block text-sm text-gray-400 mb-1.5">{label}</label>
      <input
        type={opts?.type || 'text'}
        value={form[key]}
        placeholder={opts?.placeholder}
        onChange={(e) => set(key, e.target.value)}
        className="w-full bg-dark-input border border-dark-border rounded-lg px-3 py-2.5 text-white focus:outline-none focus:border-primary"
      />
    </div>
  )

  return (
    <AdminLayout title="Tamirlash — ustalar">
      <div className="space-y-4">
        <div className="flex items-center">
          <span className="text-gray-400 text-sm">Jami ustalar: {total}</span>
          <button
            onClick={() => { setShowForm(s => !s); setError('') }}
            className="ml-auto px-4 py-2 rounded-lg text-sm bg-primary text-white font-semibold hover:bg-primary/90 transition-colors"
          >
            {showForm ? '✕ Yopish' : '+ Usta qo\'shish'}
          </button>
        </div>

        {showForm && (
          <div className="bg-dark-card rounded-xl border border-dark-border p-6">
            <h3 className="text-lg font-semibold mb-4">Yangi usta qo'shish</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {field('To\'liq ism *', 'full_name')}
              {field('Telefon *', 'phone', { placeholder: '+998 90 123 45 67' })}
              {field('Email *', 'email', { type: 'email' })}
              {field('Parol *', 'password', { type: 'text', placeholder: 'kamida 6 belgi' })}
              {field('Ustaxona nomi', 'workshop_name')}
              {field('Ustaxona manzili', 'workshop_address')}
              {field('Ish vaqti', 'work_hours', { placeholder: '9:00-18:00' })}
              {field('Yo\'nalishlar (vergul bilan)', 'specialization', { placeholder: 'Dvigatel, Xodovoy, Elektrika' })}
            </div>
            {error && <p className="text-red-400 text-sm mt-3">{error}</p>}
            <div className="flex gap-3 mt-5">
              <button onClick={() => { setShowForm(false); setForm({ ...emptyForm }) }} className="px-5 py-2.5 bg-dark-input rounded-lg text-sm text-gray-300">Bekor</button>
              <button onClick={handleCreate} disabled={saving} className="px-5 py-2.5 bg-primary text-white font-semibold rounded-lg text-sm disabled:opacity-50">
                {saving ? 'Saqlanmoqda...' : 'Saqlash'}
              </button>
            </div>
          </div>
        )}

        <div className="bg-dark-card rounded-xl border border-dark-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-dark-border text-gray-400">
                <th className="px-4 py-3 text-left">Ism</th>
                <th className="px-4 py-3 text-left">Ustaxona</th>
                <th className="px-4 py-3 text-left">Yo'nalishlar</th>
                <th className="px-4 py-3 text-left">Reyting</th>
                <th className="px-4 py-3 text-left">Status</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} className="text-center py-8 text-gray-400">Yuklanmoqda...</td></tr>
              ) : mechanics.length === 0 ? (
                <tr><td colSpan={5} className="text-center py-8 text-gray-400">Usta yo'q</td></tr>
              ) : mechanics.map((m) => (
                <tr key={m.id} className="border-b border-dark-border/50 hover:bg-dark-input/30 transition-colors">
                  <td className="px-4 py-3">
                    <div className="font-medium">{m.user?.full_name}</div>
                    <div className="text-gray-400 text-xs">{m.user?.phone}</div>
                  </td>
                  <td className="px-4 py-3">
                    <div>{m.workshop_name || '—'}</div>
                    <div className="text-gray-400 text-xs">{m.workshop_address}</div>
                  </td>
                  <td className="px-4 py-3 text-gray-300 text-xs max-w-xs">
                    {(m.specialization && m.specialization.length > 0) ? m.specialization.join(', ') : '—'}
                  </td>
                  <td className="px-4 py-3">{m.rating_avg?.toFixed(1)} ({m.total_services})</td>
                  <td className="px-4 py-3">
                    <span className={`status-${m.verification_status}`}>{STATUS_LABELS[m.verification_status] || m.verification_status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </AdminLayout>
  )
}
