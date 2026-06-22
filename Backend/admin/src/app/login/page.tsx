'use client'
import { useEffect, useRef, useState } from 'react'
import { useRouter } from 'next/navigation'
import api from '@/lib/api'
import Brand from '@/components/ui/Brand'

// ── Phone formatter: (XX) XXX-XX-XX ─────────────────────────────────────────
function fmtPhone(raw: string) {
  const d = raw.replace(/\D/g, '').slice(0, 9)
  let out = ''
  for (let i = 0; i < d.length; i++) {
    if (i === 0) out += '('
    if (i === 2) out += ') '
    if (i === 5) out += '-'
    if (i === 7) out += '-'
    out += d[i]
  }
  return out
}
function rawDigits(v: string) { return v.replace(/\D/g, '') }

// ── OTP Boxes ─────────────────────────────────────────────────────────────────
function OtpBoxes({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  const containerRef = useRef<HTMLDivElement>(null)

  const focus = (i: number) => {
    const el = containerRef.current?.querySelectorAll('input')[i] as HTMLInputElement | undefined
    el?.focus()
  }

  const handleKey = (i: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace') {
      e.preventDefault()
      const next = value.slice(0, i) + value.slice(i + 1)
      onChange(next)
      setTimeout(() => focus(Math.max(0, i - 1)), 0)
    }
  }

  const handleChange = (i: number, e: React.ChangeEvent<HTMLInputElement>) => {
    const ch = e.target.value.replace(/\D/g, '').slice(-1)
    if (!ch) return
    const arr = (value + '      ').slice(0, 6).split('')
    arr[i] = ch
    const next = arr.join('').trimEnd().slice(0, 6)
    onChange(next)
    if (i < 5) setTimeout(() => focus(i + 1), 0)
  }

  const handlePaste = (e: React.ClipboardEvent) => {
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6)
    if (pasted) { onChange(pasted); setTimeout(() => focus(Math.min(pasted.length, 5)), 0) }
    e.preventDefault()
  }

  useEffect(() => { setTimeout(() => focus(0), 50) }, [])

  return (
    <div ref={containerRef} style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
      {Array.from({ length: 6 }).map((_, i) => {
        const filled = i < value.length
        return (
          <input
            key={i}
            type="text"
            inputMode="numeric"
            maxLength={1}
            value={filled ? value[i] : ''}
            onChange={e => handleChange(i, e)}
            onKeyDown={e => handleKey(i, e)}
            onPaste={handlePaste}
            onFocus={e => e.target.select()}
            style={{
              width: 44, height: 52, borderRadius: 12, border: '1.5px solid',
              borderColor: filled ? 'var(--inv)' : 'var(--hair2)',
              background: 'var(--surf)', color: 'var(--txt)',
              fontSize: 22, fontWeight: 700, textAlign: 'center',
              fontFamily: "'JetBrains Mono',monospace", outline: 'none',
              transition: 'border-color .15s',
            }}
            onFocusCapture={e => (e.target.style.borderColor = 'var(--inv)')}
            onBlurCapture={e => (e.target.style.borderColor = filled ? 'var(--inv)' : 'var(--hair2)')}
          />
        )
      })}
    </div>
  )
}

// ── Countdown ─────────────────────────────────────────────────────────────────
function useCountdown(secs: number) {
  const [left, setLeft] = useState(secs)
  useEffect(() => {
    setLeft(secs)
    const t = setInterval(() => setLeft(p => (p > 0 ? p - 1 : 0)), 1000)
    return () => clearInterval(t)
  }, [secs])
  return left
}

// ── Main ──────────────────────────────────────────────────────────────────────
type Step = 'phone' | 'otp' | 'password'

export default function LoginPage() {
  const router = useRouter()

  const [step, setStep]       = useState<Step>('phone')
  const [phone, setPhone]     = useState('')          // formatted
  const [otp, setOtp]         = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError]     = useState('')
  const [resendKey, setResendKey] = useState(0)

  const countdown = useCountdown(resendKey === 0 ? 0 : 59)
  const phoneRef  = useRef<HTMLInputElement>(null)
  const passRef   = useRef<HTMLInputElement>(null)

  // Tokens from OTP step (needed for admin password step)
  const tokensRef = useRef<{ access: string; refresh: string; user: any } | null>(null)

  useEffect(() => { phoneRef.current?.focus() }, [])

  // ── Step 1: Send OTP ───────────────────────────────────────────────────────
  const sendOtp = async () => {
    const digits = rawDigits(phone)
    if (digits.length !== 9) { setError('To\'liq telefon raqamini kiriting'); return }
    setLoading(true); setError('')
    try {
      await api.post('/auth/send-otp', { phone: `+998${digits}` })
      setOtp('')
      setStep('otp')
      setResendKey(k => k + 1)
    } catch (e: any) {
      setError(e?.response?.data?.message || 'OTP yuborishda xatolik')
    } finally { setLoading(false) }
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────────────────
  const verifyOtp = async () => {
    if (otp.length !== 6) { setError('6 raqamli kodni kiriting'); return }
    setLoading(true); setError('')
    try {
      const digits = rawDigits(phone)
      const r = await api.post('/auth/verify-otp', { phone: `+998${digits}`, code: otp })
      const { access_token, refresh_token, user } = r.data.data
      tokensRef.current = { access: access_token, refresh: refresh_token, user }

      if (user?.role === 'admin') {
        setStep('password')
        setTimeout(() => passRef.current?.focus(), 80)
      } else if (user?.role === 'service') {
        localStorage.setItem('partner_access_token', access_token)
        localStorage.setItem('partner_refresh_token', refresh_token)
        localStorage.setItem('partner_user', JSON.stringify(user))
        router.push('/partner')
      } else {
        setError('Bu raqam uchun kirish huquqi yo\'q')
        tokensRef.current = null
      }
    } catch (e: any) {
      setError(e?.response?.data?.message || 'Kod noto\'g\'ri')
    } finally { setLoading(false) }
  }

  // ── Step 3: Admin password ─────────────────────────────────────────────────
  const checkPassword = () => {
    if (password !== 'Admin123!') { setError('Parol noto\'g\'ri'); return }
    const t = tokensRef.current!
    localStorage.setItem('access_token', t.access)
    localStorage.setItem('refresh_token', t.refresh)
    router.push('/dashboard')
  }

  const resend = async () => {
    setLoading(true); setError('')
    try {
      await api.post('/auth/send-otp', { phone: `+998${rawDigits(phone)}` })
      setOtp(''); setResendKey(k => k + 1)
    } catch { /* silent */ } finally { setLoading(false) }
  }

  const back = () => {
    setError('')
    if (step === 'otp') { setStep('phone'); setOtp('') }
    if (step === 'password') { setStep('otp'); setPassword(''); tokensRef.current = null }
  }

  // ── Shared styles ──────────────────────────────────────────────────────────
  const card: React.CSSProperties = {
    background: 'var(--bgE)', borderRadius: 20, padding: 28,
    border: '1px solid var(--hair)', boxShadow: '0 8px 40px rgba(0,0,0,.28)',
  }
  const label: React.CSSProperties = {
    display: 'block', fontSize: 10.5, fontWeight: 700,
    textTransform: 'uppercase', letterSpacing: '.08em',
    color: 'var(--txt3)', marginBottom: 7,
  }
  const btn = (primary = true): React.CSSProperties => ({
    width: '100%', height: 48, borderRadius: 999,
    background: primary ? 'var(--inv)' : 'var(--surf)',
    color: primary ? 'var(--invT)' : 'var(--txt2)',
    border: primary ? 'none' : '1px solid var(--hair2)',
    fontSize: 15, fontWeight: 600,
    cursor: loading ? 'default' : 'pointer',
    opacity: loading ? 0.65 : 1, transition: 'opacity .15s',
  })

  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div style={{ width: '100%', maxWidth: 360 }}>

        {/* Brand */}
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 56, height: 56, borderRadius: 16, background: 'var(--inv)', color: 'var(--invT)', marginBottom: 12 }}>
            <Brand s={30} />
          </div>
          <p style={{ color: 'var(--txt)', fontWeight: 700, fontSize: 22, letterSpacing: '-.03em' }}>Shina24</p>
          <p style={{ color: 'var(--txt3)', fontSize: 11, fontFamily: "'JetBrains Mono',monospace", marginTop: 4, textTransform: 'uppercase', letterSpacing: '.12em' }}>
            {step === 'phone' ? 'Kirish' : step === 'otp' ? 'Tasdiqlash' : 'Admin paroli'}
          </p>
        </div>

        {/* Step indicator */}
        <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginBottom: 20 }}>
          {(['phone', 'otp', 'password'] as Step[]).map((s, i) => (
            <div key={s} style={{
              height: 3, borderRadius: 99, transition: 'all .3s',
              background: step === s ? 'var(--inv)' : i < ['phone','otp','password'].indexOf(step) ? 'var(--txt3)' : 'var(--hair2)',
              width: step === s ? 24 : 10,
            }} />
          ))}
        </div>

        <div style={card}>

          {/* ── STEP 1: Phone ── */}
          {step === 'phone' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
              <div>
                <label style={label}>Telefon raqam</label>
                <div style={{ display: 'flex', gap: 8 }}>
                  <div style={{ height: 48, width: 80, borderRadius: 12, background: 'var(--surf)', border: '1px solid var(--hair2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, fontWeight: 700, color: 'var(--txt)', fontFamily: "'JetBrains Mono',monospace", flexShrink: 0 }}>
                    +998
                  </div>
                  <input
                    ref={phoneRef}
                    type="tel"
                    value={phone}
                    onChange={e => { setPhone(fmtPhone(e.target.value)); setError('') }}
                    onKeyDown={e => e.key === 'Enter' && sendOtp()}
                    placeholder="(__) ___-__-__"
                    style={{ flex: 1, height: 48, borderRadius: 12, border: '1px solid var(--hair2)', background: 'var(--surf)', color: 'var(--txt)', fontSize: 15, fontFamily: "'JetBrains Mono',monospace", padding: '0 14px', outline: 'none' }}
                    onFocus={e => (e.target.style.borderColor = 'var(--inv)')}
                    onBlur={e => (e.target.style.borderColor = 'var(--hair2)')}
                  />
                </div>
              </div>

              {error && <div style={{ background: 'var(--redDim)', border: '1px solid rgba(229,56,43,.25)', borderRadius: 11, padding: '11px 14px', color: 'var(--red)', fontSize: 13 }}>{error}</div>}

              <button onClick={sendOtp} disabled={loading || rawDigits(phone).length !== 9} style={{ ...btn(), opacity: (loading || rawDigits(phone).length !== 9) ? 0.5 : 1 }}>
                {loading ? 'Yuborilmoqda…' : 'SMS kod yuborish'}
              </button>
            </div>
          )}

          {/* ── STEP 2: OTP ── */}
          {step === 'otp' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              <div style={{ textAlign: 'center' }}>
                <p style={{ fontSize: 13.5, color: 'var(--txt2)', marginBottom: 4 }}>Kod yuborildi:</p>
                <p style={{ fontSize: 15, fontWeight: 700, color: 'var(--txt)', fontFamily: "'JetBrains Mono',monospace" }}>
                  +998 {phone}
                </p>
              </div>

              <OtpBoxes value={otp} onChange={v => { setOtp(v); setError('') }} />

              {error && <div style={{ background: 'var(--redDim)', border: '1px solid rgba(229,56,43,.25)', borderRadius: 11, padding: '10px 14px', color: 'var(--red)', fontSize: 13, textAlign: 'center' }}>{error}</div>}

              <div style={{ textAlign: 'center', fontSize: 13, color: 'var(--txt3)' }}>
                {countdown > 0 ? (
                  <span>Qayta yuborish: 0:{String(countdown).padStart(2, '0')}</span>
                ) : (
                  <button onClick={resend} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--txt)', fontSize: 13, fontWeight: 600, textDecoration: 'underline' }}>
                    Qayta yuborish
                  </button>
                )}
              </div>

              <button onClick={verifyOtp} disabled={loading || otp.length !== 6} style={{ ...btn(), opacity: (loading || otp.length !== 6) ? 0.5 : 1 }}>
                {loading ? 'Tekshirilmoqda…' : 'Tasdiqlash'}
              </button>

              <button onClick={back} style={btn(false)}>← Orqaga</button>
            </div>
          )}

          {/* ── STEP 3: Admin password ── */}
          {step === 'password' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
              <div style={{ textAlign: 'center', padding: '4px 0 8px' }}>
                <div style={{ width: 44, height: 44, borderRadius: 12, background: 'var(--surf2)', display: 'inline-grid', placeItems: 'center', marginBottom: 10 }}>
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--txt2)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="3"/><path d="M7 11V7a5 5 0 0110 0v4"/>
                  </svg>
                </div>
                <p style={{ fontSize: 13.5, color: 'var(--txt2)' }}>Admin parolini kiriting</p>
              </div>

              <div>
                <label style={label}>Parol</label>
                <div style={{ position: 'relative' }}>
                  <input
                    ref={passRef}
                    type={showPass ? 'text' : 'password'}
                    value={password}
                    onChange={e => { setPassword(e.target.value); setError('') }}
                    onKeyDown={e => e.key === 'Enter' && checkPassword()}
                    placeholder="Admin123!"
                    style={{ width: '100%', height: 48, borderRadius: 12, border: '1px solid var(--hair2)', background: 'var(--surf)', color: 'var(--txt)', fontSize: 15, padding: '0 44px 0 14px', outline: 'none', boxSizing: 'border-box' }}
                    onFocus={e => (e.target.style.borderColor = 'var(--inv)')}
                    onBlur={e => (e.target.style.borderColor = 'var(--hair2)')}
                  />
                  <button onClick={() => setShowPass(p => !p)}
                    style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--txt3)', padding: 0 }}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
                      {showPass
                        ? <><path d="M17.9 17.9A10 10 0 0112 19C6 19 2 12 2 12a17 17 0 014.1-5.1M9.9 4.2A10 10 0 0122 12a17 17 0 01-2.4 4M3 3l18 18"/></>
                        : <><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></>}
                    </svg>
                  </button>
                </div>
              </div>

              {error && <div style={{ background: 'var(--redDim)', border: '1px solid rgba(229,56,43,.25)', borderRadius: 11, padding: '10px 14px', color: 'var(--red)', fontSize: 13 }}>{error}</div>}

              <button onClick={checkPassword} disabled={!password} style={{ ...btn(), opacity: !password ? 0.5 : 1 }}>
                Kirish
              </button>

              <button onClick={back} style={btn(false)}>← Orqaga</button>
            </div>
          )}

        </div>

        <p style={{ textAlign: 'center', marginTop: 16, fontSize: 11.5, color: 'var(--txt3)', fontFamily: "'JetBrains Mono',monospace" }}>
          000000 — test OTP kodi
        </p>
      </div>
    </div>
  )
}
