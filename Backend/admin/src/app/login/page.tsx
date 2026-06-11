'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import api from '@/lib/api'

export default function LoginPage() {
  const [identifier, setIdentifier] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await api.post('/auth/login', { email: identifier, password })
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
    <div className="min-h-screen bg-bg flex items-center justify-center p-4">
      <div className="w-full max-w-sm">
        {/* Brand */}
        <div className="text-center mb-8">
          <p className="text-text font-bold text-2xl tracking-tight">Shina24</p>
          <p className="text-text3 text-xs font-mono mt-1 uppercase tracking-widest">Admin panel</p>
        </div>

        {/* Form */}
        <div className="card p-6 space-y-5">
          <h2 className="text-text font-semibold text-base">Kirish</h2>

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1.5">
                Telefon yoki email
              </label>
              <input
                type="text"
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                placeholder="+998901234567"
                className="inp"
                required
                autoComplete="username"
              />
            </div>

            <div>
              <label className="block text-text3 text-xs font-mono uppercase tracking-widest mb-1.5">
                Parol
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="inp"
                required
                autoComplete="current-password"
              />
            </div>

            {error && (
              <div className="bg-danger-dim border border-danger/20 rounded-md px-4 py-3 text-danger text-sm">
                {error}
              </div>
            )}

            <button type="submit" disabled={loading} className="btn-primary w-full py-3">
              {loading ? 'Kirilmoqda...' : 'Kirish'}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
