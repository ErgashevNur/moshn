'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import api from '@/lib/api'

export default function LoginPage() {
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await api.post('/auth/login', { phone, password })
      const { access_token, refresh_token } = res.data.data
      localStorage.setItem('access_token', access_token)
      localStorage.setItem('refresh_token', refresh_token)
      router.push('/dashboard')
    } catch (err: any) {
      setError(err.response?.data?.error || 'Kirish xatosi')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-dark-bg flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center text-center">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo-cream.png" alt="Moshn" className="h-28 w-auto" />
          <p className="mono-label text-ink-soft mt-4">§ Admin boshqaruv paneli</p>
        </div>

        <div className="bg-dark-card p-8 border border-dark-border">
          <h2 className="font-display text-xl font-semibold mb-6 text-ink">Kirish</h2>

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block mono-label text-ink-soft mb-2">Telefon raqam</label>
              <input
                type="text"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+998901234567"
                className="w-full bg-dark-input border border-dark-border px-4 py-3 text-ink placeholder-ink-soft focus:outline-none focus:border-accent transition-colors"
                required
              />
            </div>

            <div>
              <label className="block mono-label text-ink-soft mb-2">Parol</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-dark-input border border-dark-border px-4 py-3 text-ink placeholder-ink-soft focus:outline-none focus:border-accent transition-colors"
                required
              />
            </div>

            {error && (
              <div className="bg-danger/10 border border-danger/20 px-4 py-3 text-danger text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-accent hover:bg-accent-deep disabled:opacity-50 text-white font-semibold py-3 transition-colors"
            >
              {loading ? 'Kirilmoqda...' : 'Kirish →'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
