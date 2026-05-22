'use client'
import { useState } from 'react'
import AdminLayout from '@/components/AdminLayout'
import api from '@/lib/api'

export default function NotificationsPage() {
  const [target, setTarget] = useState('all')
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
    <AdminLayout title="Bildirishnomalar yuborish">
      <div className="max-w-xl">
        <div className="bg-dark-card rounded-xl p-6 border border-dark-border">
          <form onSubmit={handleSend} className="space-y-5">
            <div>
              <label className="block text-sm text-gray-400 mb-2">Yuborish manzili</label>
              <div className="flex gap-3">
                <label className={`flex-1 flex items-center gap-2 px-4 py-3 rounded-lg cursor-pointer border transition-colors ${
                  target === 'all' ? 'border-primary bg-primary/10' : 'border-dark-border bg-dark-input'
                }`}>
                  <input
                    type="radio"
                    value="all"
                    checked={target === 'all'}
                    onChange={() => setTarget('all')}
                    className="accent-primary"
                  />
                  <span className="text-sm">Barcha foydalanuvchilar</span>
                </label>
                <label className={`flex-1 flex items-center gap-2 px-4 py-3 rounded-lg cursor-pointer border transition-colors ${
                  target === 'specific' ? 'border-primary bg-primary/10' : 'border-dark-border bg-dark-input'
                }`}>
                  <input
                    type="radio"
                    value="specific"
                    checked={target === 'specific'}
                    onChange={() => setTarget('specific')}
                    className="accent-primary"
                  />
                  <span className="text-sm">Tanlangan</span>
                </label>
              </div>
            </div>

            {target === 'specific' && (
              <div>
                <label className="block text-sm text-gray-400 mb-1.5">Telefon raqam</label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+998901234567"
                  className="w-full bg-dark-input border border-dark-border rounded-lg px-4 py-2.5 text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                  required
                />
              </div>
            )}

            <div>
              <label className="block text-sm text-gray-400 mb-1.5">Sarlavha</label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Bildirishnoma sarlavhasi"
                className="w-full bg-dark-input border border-dark-border rounded-lg px-4 py-2.5 text-white placeholder-gray-500 focus:outline-none focus:border-primary"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-gray-400 mb-1.5">Matn</label>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Bildirishnoma matni..."
                rows={4}
                className="w-full bg-dark-input border border-dark-border rounded-lg px-4 py-2.5 text-white placeholder-gray-500 focus:outline-none focus:border-primary resize-none"
                required
              />
            </div>

            {success && (
              <div className="bg-green-500/10 border border-green-500/20 rounded-lg px-4 py-3 text-green-400 text-sm">
                ✓ Bildirishnoma muvaffaqiyatli yuborildi
              </div>
            )}

            {error && (
              <div className="bg-red-500/10 border border-red-500/20 rounded-lg px-4 py-3 text-red-400 text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-primary text-white font-semibold rounded-lg hover:bg-primary/90 disabled:bg-primary/50 transition-colors"
            >
              {loading ? 'Yuborilmoqda...' : 'Yuborish 🔔'}
            </button>
          </form>
        </div>
      </div>
    </AdminLayout>
  )
}
