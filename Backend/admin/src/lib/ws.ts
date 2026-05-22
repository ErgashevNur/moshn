// Admin WebSocket — real-time eventlar (SOS so'rovlari refreshsiz keladi).
export function connectAdminSocket(
  onEvent: (type: string, data: any) => void,
  onStatus?: (connected: boolean) => void,
): WebSocket | null {
  if (typeof window === 'undefined') return null
  const token = localStorage.getItem('access_token')
  if (!token) return null

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/v1'
  let base: string
  if (/^https?:\/\//.test(apiUrl)) {
    // To'liq URL: http(s):// -> ws(s)://, oxiridagi /v1 ni olib tashlaymiz
    base = apiUrl.replace(/^http/, 'ws').replace(/\/v1\/?$/, '')
  } else {
    // Nisbiy "/v1": joriy origin'dan ws(s):// quramiz
    const proto = window.location.protocol === 'https:' ? 'wss' : 'ws'
    base = `${proto}://${window.location.host}`
  }
  const wsUrl = `${base}/v1/ws?token=${encodeURIComponent(token)}`

  const ws = new WebSocket(wsUrl)
  ws.onopen = () => onStatus?.(true)
  ws.onclose = () => onStatus?.(false)
  ws.onmessage = (e) => {
    try {
      const m = JSON.parse(e.data)
      onEvent(m.type, m.data)
    } catch {
      /* ignore */
    }
  }
  return ws
}
