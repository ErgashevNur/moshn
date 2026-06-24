'use client'
import { useEffect, useRef } from 'react'
import axios from 'axios'

// Admin WebSocket — хук подключения для событий в реальном времени.
// Та же логика, что и в usePartnerWS партнёрской панели: при обычном
// разрыве — retry, при истечении токена (close code 1008) сначала
// вызывается /auth/refresh для переподключения, если не помогло — /login.
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
        // Полный URL: http(s):// -> ws(s)://, отбрасываем конечный /v1
        base = apiUrl.replace(/^http/, 'ws').replace(/\/v1\/?$/, '')
      } else {
        // Относительный "/v1": строим ws(s):// из текущего origin
        const proto = window.location.protocol === 'https:' ? 'wss' : 'ws'
        base = `${proto}://${window.location.host}`
      }
      return `${base}/v1/ws?token=${encodeURIComponent(token)}`
    }

    // При истечении токена — получаем новый и переподключаемся;
    // если и refresh не сработал — переходим на страницу входа.
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

      // Если соединение уже есть — новое не открываем
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
          // 1008 — backend отклонил подключение: токен отсутствует/недействителен (ws.gateway.ts)
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
  }, [])   // запускается один раз
}
