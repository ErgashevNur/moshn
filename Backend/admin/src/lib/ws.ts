'use client'
import { useEffect, useRef } from 'react'
import axios from 'axios'

// Admin WebSocket — real-vaqt eventlar uchun ulanish hook'i.
// Partner panel'dagi usePartnerWS bilan bir xil mantiq: oddiy uzilishda
// retry, token muddati tugaganda (close code 1008) avval /auth/refresh
// chaqirib qayta ulanadi, u ham ishlamasa /login'ga chiqaradi.
export function useAdminSocket(
  onEvent: (type: string, data: any) => void,
  onStatus?: (connected: boolean) => void,
) {
  const wsRef       = useRef<WebSocket | null>(null)
  const retryRef    = useRef<ReturnType<typeof setTimeout> | null>(null)
  const mountedRef  = useRef(false)
  const onEventRef  = useRef(onEvent)
  const onStatusRef = useRef(onStatus)

  useEffect(() => { onEventRef.current = onEvent })
  useEffect(() => { onStatusRef.current = onStatus })

  useEffect(() => {
    if (mountedRef.current) return   // StrictMode ikkinchi chaqiruvini bloklash
    mountedRef.current = true

    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/v1'

    const buildWsUrl = (token: string) => {
      let base: string
      if (/^https?:\/\//.test(apiUrl)) {
        // To'liq URL: http(s):// -> ws(s)://, oxiridagi /v1 ni olib tashlaymiz
        base = apiUrl.replace(/^http/, 'ws').replace(/\/v1\/?$/, '')
      } else {
        // Nisbiy "/v1": joriy origin'dan ws(s):// quramiz
        const proto = window.location.protocol === 'https:' ? 'wss' : 'ws'
        base = `${proto}://${window.location.host}`
      }
      return `${base}/v1/ws?token=${encodeURIComponent(token)}`
    }

    // Token muddati tugaganda — yangi token olib qayta ulanamiz;
    // refresh ham ishlamasa — login sahifasiga chiqaramiz.
    const refreshAndReconnect = async () => {
      const refreshToken = localStorage.getItem('refresh_token')
      if (!refreshToken) { window.location.href = '/login'; return }
      try {
        const res = await axios.post(`${apiUrl}/auth/refresh`, { refresh_token: refreshToken })
        const { access_token, refresh_token } = res.data.data
        localStorage.setItem('access_token', access_token)
        localStorage.setItem('refresh_token', refresh_token)
        if (mountedRef.current) connect()
      } catch {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        window.location.href = '/login'
      }
    }

    const connect = () => {
      const token = localStorage.getItem('access_token')
      if (!token) return

      // Agar ulanish allaqachon mavjud bo'lsa — yangi ochmaymiz
      const s = wsRef.current?.readyState
      if (s === WebSocket.OPEN || s === WebSocket.CONNECTING) return

      try {
        const ws = new WebSocket(buildWsUrl(token))
        wsRef.current = ws

        ws.onopen = () => onStatusRef.current?.(true)

        ws.onmessage = (e) => {
          try {
            const m = JSON.parse(e.data)
            onEventRef.current(m.type, m.data)
          } catch { /* ignore */ }
        }

        ws.onclose = (ev) => {
          onStatusRef.current?.(false)
          if (!mountedRef.current) return
          // 1008 — backend token yo'q/yaroqsiz deb ulanishni rad etdi (ws.gateway.ts)
          if (ev.code === 1008) {
            refreshAndReconnect()
          } else {
            retryRef.current = setTimeout(connect, 5000)
          }
        }

        ws.onerror = () => ws.close()
      } catch { /* ignore */ }
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
