'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import PartnerSidebar from './PartnerSidebar'
import Icon from '../ui/Icon'

// ── WebSocket toast notification ─────────────────────────────────────────────
interface WSToast {
  id: number
  type: string
  title: string
  body: string
  booking?: any
}

function Toast({ t, onClose }: { t: WSToast; onClose: () => void }) {
  useEffect(() => {
    const timer = setTimeout(onClose, 7000)
    return () => clearTimeout(timer)
  }, [onClose])

  const isNew = t.type === 'new_booking'

  return (
    <div style={{
      display:'flex', alignItems:'flex-start', gap:12,
      padding:'14px 16px', borderRadius:14,
      background: isNew ? 'var(--bgE)' : 'var(--bgE)',
      border: `1.5px solid ${isNew ? 'var(--blue)' : 'var(--hair2)'}`,
      boxShadow:'0 8px 32px rgba(0,0,0,.45)',
      animation:'rise .25s ease',
      maxWidth: 340, width:'100%',
      position:'relative',
    }}>
      {/* colored left stripe */}
      <div style={{
        position:'absolute', left:0, top:10, bottom:10, width:3,
        borderRadius:3, background: isNew ? 'var(--blue)' : 'var(--amber)',
      }}/>

      <div style={{
        width:38, height:38, borderRadius:10, flexShrink:0,
        background: isNew ? 'var(--blueDim)' : 'var(--amberDim)',
        display:'grid', placeItems:'center',
        color: isNew ? 'var(--blue)' : 'var(--amber)',
      }}>
        <Icon n={isNew ? 'bell' : 'refresh'} s={20}/>
      </div>

      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:13.5, fontWeight:700, color:'var(--txt)', marginBottom:3}}>{t.title}</div>
        <div style={{fontSize:12.5, color:'var(--txt2)', lineHeight:1.4}}>{t.body}</div>
        {t.booking && (
          <div style={{display:'flex', gap:8, marginTop:8, flexWrap:'wrap'}}>
            {t.booking.customer?.fullName && (
              <span style={{fontSize:11.5, background:'var(--surf2)', color:'var(--txt2)', padding:'2px 8px', borderRadius:6}}>
                {t.booking.customer.fullName}
              </span>
            )}
            {t.booking.serviceType?.nameUz && (
              <span style={{fontSize:11.5, background:'var(--surf2)', color:'var(--txt2)', padding:'2px 8px', borderRadius:6}}>
                {t.booking.serviceType.nameUz}
              </span>
            )}
            {t.booking.totalPrice > 0 && (
              <span style={{fontSize:11.5, background:'var(--surf2)', color:'var(--green)', padding:'2px 8px', borderRadius:6, fontFamily:"'JetBrains Mono',monospace", fontWeight:700}}>
                {t.booking.totalPrice.toLocaleString('uz')} so'm
              </span>
            )}
          </div>
        )}
      </div>

      <button onClick={onClose} style={{
        background:'none', border:'none', color:'var(--txt3)',
        cursor:'pointer', padding:2, flexShrink:0,
      }}>
        <Icon n="x" s={16}/>
      </button>
    </div>
  )
}

// ── WebSocket hook ───────────────────────────────────────────────────────────
function usePartnerWS(onMessage: (data: any) => void) {
  const wsRef      = useRef<WebSocket | null>(null)
  const retryRef   = useRef<ReturnType<typeof setTimeout> | null>(null)
  const mountedRef = useRef(false)
  const onMsgRef   = useRef(onMessage)

  // onMessage ref ni har render yangilab turadi — WS qayta ulanmaydi
  useEffect(() => { onMsgRef.current = onMessage })

  useEffect(() => {
    if (mountedRef.current) return   // StrictMode ikkinchi chaqiruvini bloklash
    mountedRef.current = true

    const connect = () => {
      const token = localStorage.getItem('partner_access_token')
      if (!token) return

      // Agar ulanish allaqachon mavjud bo'lsa — yangi ochmaymiz
      const s = wsRef.current?.readyState
      if (s === WebSocket.OPEN || s === WebSocket.CONNECTING) return

      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/v1'
      const wsBase = apiUrl.replace(/^https/, 'wss').replace(/^http/, 'ws')
      const url    = `${wsBase}/ws?token=${token}`

      try {
        const ws = new WebSocket(url)
        wsRef.current = ws

        ws.onopen = () => console.log('[WS] ulandi')

        ws.onmessage = (e) => {
          try { onMsgRef.current(JSON.parse(e.data)) } catch {}
        }

        ws.onclose = () => {
          if (!mountedRef.current) return
          retryRef.current = setTimeout(connect, 5000)
        }

        ws.onerror = () => ws.close()
      } catch {}
    }

    connect()

    return () => {
      mountedRef.current = false
      if (retryRef.current) clearTimeout(retryRef.current)
      wsRef.current?.close()
      wsRef.current = null
    }
  }, [])   // bir marta ishga tushadi
}

// ── Shell ────────────────────────────────────────────────────────────────────
interface Props {
  children: React.ReactNode
  pendingCount?: number
}

let toastId = 0

export default function PartnerShell({ children, pendingCount = 0 }: Props) {
  const [isMobile, setMobile] = useState(false)
  const [toasts, setToasts]   = useState<WSToast[]>([])

  useEffect(() => {
    const check = () => setMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  const removeToast = useCallback((id: number) => {
    setToasts(ts => ts.filter(t => t.id !== id))
  }, [])

  const handleWS = useCallback((data: any) => {
    const type = data.type || data.event || ''

    let title = ''
    let body  = ''

    if (type === 'new_booking' || type === 'booking_created') {
      title = '🔔 Yangi buyurtma!'
      body  = data.booking?.customer?.fullName
        ? `${data.booking.customer.fullName} — ${data.booking.serviceType?.nameUz || 'Xizmat'}`
        : 'Yangi bron keldi'
    } else if (type === 'booking_cancelled') {
      title = 'Buyurtma bekor qilindi'
      body  = data.booking?.customer?.fullName || 'Mijoz buyurtmani bekor qildi'
    } else if (type === 'booking_updated') {
      title = 'Buyurtma yangilandi'
      body  = data.booking?.customer?.fullName || 'Buyurtma holati o\'zgardi'
    } else if (data.title || data.message) {
      title = data.title || 'Bildirishnoma'
      body  = data.message || data.body || ''
    } else {
      return // noma'lum xabar — ko'rsatma
    }

    const toast: WSToast = {
      id: ++toastId,
      type,
      title,
      body,
      booking: data.booking,
    }
    setToasts(ts => [toast, ...ts].slice(0, 5))

    // Audio signal (agar brauzer ruxsat bersa)
    try {
      const ctx = new (window.AudioContext || (window as any).webkitAudioContext)()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain); gain.connect(ctx.destination)
      osc.frequency.value = 880
      gain.gain.setValueAtTime(0.15, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4)
      osc.start(); osc.stop(ctx.currentTime + 0.4)
    } catch {}
  }, [])

  usePartnerWS(handleWS)

  return (
    <div style={{
      display:'flex', height:'100vh',
      background:'var(--bg)', color:'var(--txt)',
      overflow:'hidden',
    }}>
      <PartnerSidebar pendingCount={pendingCount}/>
      <div style={{
        flex:1, display:'flex', minWidth:0, overflow:'hidden',
        paddingBottom: isMobile ? 64 : 0,
      }}>
        {children}
      </div>

      {/* Toast container */}
      {toasts.length > 0 && (
        <div style={{
          position:'fixed',
          top: isMobile ? 12 : 20,
          right: isMobile ? 12 : 20,
          left: isMobile ? 12 : 'auto',
          zIndex:500,
          display:'flex', flexDirection:'column', gap:10,
          pointerEvents:'none',
        }}>
          {toasts.map(t => (
            <div key={t.id} style={{pointerEvents:'all'}}>
              <Toast t={t} onClose={() => removeToast(t.id)}/>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
