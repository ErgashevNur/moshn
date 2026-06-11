'use client'
import { useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

export default function NotificationsPage() {
  const [target, setTarget] = useState<'all' | 'specific'>('all')
  const [phone, setPhone] = useState('')
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setSuccess(false)
    setError('')
    try {
      await api.post('/admin/notifications/broadcast', {
        target: target === 'all' ? 'all' : phone,
        title,
        body,
      })
      setSuccess(true)
      setTitle('')
      setBody('')
      setPhone('')
    } catch (err: any) {
      setError(err.response?.data?.error || 'Xato yuz berdi')
    } finally {
      setLoading(false)
    }
  }

  return (
    <AdminLayout title="Bildirishnoma yuborish">
      <div className="max-w-lg">
        <div className="card p-6">
          <form onSubmit={handleSend} className="space-y-5">
            {/* Target */}
            <div>
              <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-2">Kimga</label>
              <div className="grid grid-cols-2 gap-2">
                {(['all', 'specific'] as const).map((t) => (
                  <button
                    key={t}
                    type="button"
                    onClick={() => setTarget(t)}
                    className={`py-2.5 rounded-md text-sm font-medium border transition-colors ${
                      target === t
                        ? 'border-text/30 bg-text/10 text-text'
                        : 'border-border bg-surface2 text-text3 hover:text-text2'
                    }`}
                  >
                    {t === 'all' ? 'Barcha foydalanuvchilar' : 'Tanlangan'}
                  </button>
                ))}
              </div>
            </div>

            {target === 'specific' && (
              <div>
                <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1.5">Telefon raqam</label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+998901234567"
                  className="inp"
                  required
                />
              </div>
            )}

            <div>
              <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1.5">Sarlavha</label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Bildirishnoma sarlavhasi"
                className="inp"
                required
              />
            </div>

            <div>
              <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1.5">Matn</label>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Bildirishnoma matni..."
                rows={4}
                className="inp resize-none"
                required
              />
            </div>

            {success && (
              <div className="bg-success-dim border border-success/20 rounded-md px-4 py-3 text-success text-sm">
                ✓ Bildirishnoma muvaffaqiyatli yuborildi
              </div>
            )}
            {error && (
              <div className="bg-danger-dim border border-danger/20 rounded-md px-4 py-3 text-danger text-sm">
                {error}
              </div>
            )}

            <button type="submit" disabled={loading} className="btn-primary w-full py-3">
              {loading ? 'Yuborilmoqda...' : 'Yuborish'}
            </button>
          </form>
        </div>
      </div>
    </AdminLayout>
  )
}
