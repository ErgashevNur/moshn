'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import api from '@/lib/api'
import Brand from '@/components/ui/Brand'

export default function LoginPage() {
  const [identifier, setIdentifier] = useState('')
  const [password, setPassword]     = useState('')
  const [loading, setLoading]       = useState(false)
  const [error, setError]           = useState('')
  const router = useRouter()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await api.post('/auth/login', { email: identifier, password })
      const { access_token, refresh_token, user } = res.data.data

      if (user?.role === 'admin') {
        localStorage.setItem('access_token', access_token)
        localStorage.setItem('refresh_token', refresh_token)
        router.push('/dashboard')

      } else if (user?.role === 'service') {
        localStorage.setItem('partner_access_token', access_token)
        localStorage.setItem('partner_refresh_token', refresh_token)
        localStorage.setItem('partner_user', JSON.stringify(user))
        router.push('/partner')

      } else {
        setError('У вас нет прав доступа')
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.response?.data?.error || 'Неверный логин или пароль')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{minHeight:'100vh',background:'var(--bg)',display:'flex',alignItems:'center',justifyContent:'center',padding:16}}>
      <div style={{width:'100%',maxWidth:360}}>
        <div style={{textAlign:'center',marginBottom:32}}>
          <div style={{display:'inline-flex',alignItems:'center',justifyContent:'center',width:56,height:56,borderRadius:16,background:'var(--inv)',color:'var(--invT)',marginBottom:16}}>
            <Brand s={30}/>
          </div>
          <p style={{color:'var(--txt)',fontWeight:700,fontSize:24,letterSpacing:'-.03em'}}>Shina24</p>
          <p style={{color:'var(--txt3)',fontSize:11,fontFamily:"'JetBrains Mono',monospace",marginTop:5,textTransform:'uppercase',letterSpacing:'.12em'}}>Панель управления</p>
        </div>

        <div className="card" style={{padding:28}}>
          <form onSubmit={handleLogin} style={{display:'flex',flexDirection:'column',gap:16}}>
            <div>
              <label style={{display:'block',fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)',marginBottom:7}}>
                Email или телефон
              </label>
              <input
                type="text"
                value={identifier}
                onChange={e => setIdentifier(e.target.value)}
                placeholder="example@gmail.com"
                className="inp"
                required
                autoComplete="username"
                autoFocus
              />
            </div>
            <div>
              <label style={{display:'block',fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)',marginBottom:7}}>
                Пароль
              </label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                className="inp"
                required
                autoComplete="current-password"
              />
            </div>

            {error && (
              <div style={{background:'var(--redDim)',border:'1px solid rgba(229,56,43,.25)',borderRadius:11,padding:'11px 14px',color:'var(--red)',fontSize:13,lineHeight:1.4}}>
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              style={{width:'100%',height:48,borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:15,fontWeight:600,cursor:loading?'default':'pointer',border:'none',marginTop:2,opacity:loading?0.65:1,transition:'opacity .15s'}}>
              {loading ? 'Вход…' : 'Войти'}
            </button>
          </form>


        </div>
      </div>
    </div>
  )
}
