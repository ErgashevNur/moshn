'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import Plate from '@/components/ui/Plate'
import partnerApi from '@/lib/partnerApi'

function fmt(n: number) { return n.toLocaleString('ru-RU') }
function fmtTime(d: string) {
  return new Date(d).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })
}
function fmtDist(m: number) { return `${(m / 1000).toFixed(1)} км` }

const STATUS_LABEL: Record<string, string> = {
  accepted: 'Принят',
  on_the_way: 'В пути',
  arrived: 'На месте',
  completed: 'Завершён',
  cancelled: 'Отменён',
}
const NEXT_STATUS: Record<string, { next: string; label: string }> = {
  accepted: { next: 'on_the_way', label: 'Выехал к клиенту' },
  on_the_way: { next: 'arrived', label: 'Я на месте' },
  arrived: { next: 'completed', label: 'Завершить работу' },
}

export default function PartnerSosPage() {
  const router = useRouter()
  const [incoming, setIncoming] = useState<any[]>([])
  const [active, setActive]     = useState<any | null>(null)
  const [loading, setLoading]   = useState(true)
  const [acting, setActing]     = useState('')
  const [isMobile, setIsMobile] = useState(false)
  const [myUserId, setMyUserId] = useState('')
  const [messages, setMessages] = useState<any[]>([])
  const [chatText, setChatText] = useState('')
  const [priceText, setPriceText] = useState('')
  const [error, setError]       = useState('')
  const chatEndRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  const load = useCallback(() => {
    partnerApi.get('/service/sos-requests').then(r => {
      setIncoming(r.data.data || [])
    }).catch(() => {})
    partnerApi.get('/service/sos-requests/active').then(r => {
      setActive(r.data.data || null)
    }).catch(() => {}).finally(() => setLoading(false))
  }, [])

  const loadMessages = useCallback((sosId: string) => {
    partnerApi.get(`/sos/${sosId}/messages`).then(r => {
      setMessages(r.data.data || [])
    }).catch(() => {})
  }, [])

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    partnerApi.get('/profile').then(r => setMyUserId(r.data.data?.id || '')).catch(() => {})
    load()
    const t = setInterval(load, 5000)
    return () => clearInterval(t)
  }, [router, load])

  // Chat poll — faqat faol ish bo'lganda
  useEffect(() => {
    if (!active?.id || active.status === 'completed') return
    loadMessages(active.id)
    const t = setInterval(() => loadMessages(active.id), 4000)
    return () => clearInterval(t)
  }, [active?.id, active?.status, loadMessages])

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages.length])

  const flashError = (e: any, fallback: string) => {
    setError(e?.response?.data?.message || fallback)
    setTimeout(() => setError(''), 5000)
  }

  const onAccept = async (sosId: string) => {
    setActing(sosId)
    try {
      const r = await partnerApi.post(`/service/sos-requests/${sosId}/accept`)
      setActive(r.data.data)
      setIncoming(list => list.filter(i => i.sosRequestId !== sosId))
    } catch (e: any) {
      flashError(e, 'Не удалось принять вызов')
      load()
    } finally { setActing('') }
  }

  const onAdvance = async (next: string) => {
    if (!active) return
    setActing('advance')
    try {
      const r = await partnerApi.post(`/sos/${active.id}/status`, { status: next })
      setActive(r.data.data)
    } catch (e: any) {
      flashError(e, 'Не удалось обновить статус')
    } finally { setActing('') }
  }

  const onSend = async () => {
    const text = chatText.trim()
    if (!text || !active) return
    setChatText('')
    try {
      await partnerApi.post(`/sos/${active.id}/messages`, { body: text })
      loadMessages(active.id)
    } catch (e: any) { flashError(e, 'Сообщение не отправлено') }
  }

  const onSetPrice = async () => {
    const amount = parseInt(priceText.replace(/\D/g, ''), 10)
    if (!active || !amount || amount <= 0) { flashError(null, 'Введите корректную сумму'); return }
    setActing('price')
    try {
      const r = await partnerApi.post(`/sos/${active.id}/price`, { amount })
      setActive(r.data.data)
      setPriceText('')
    } catch (e: any) {
      flashError(e, 'Не удалось указать цену')
    } finally { setActing('') }
  }

  const activeDone = active?.status === 'completed'
  const activePaid = active?.payment?.status === 'paid'
  // To'lov to'langach faol kartani yashiramiz — ish to'liq yopilgan
  const showActive = active && active.status !== 'cancelled' && !(activeDone && activePaid)

  return (
    <PartnerShell>
      <div style={{flex:1,display:'flex',flexDirection:'column',minWidth:0,overflow:'hidden'}}>
        {/* Header */}
        <div style={{height:60,display:'flex',alignItems:'center',gap:14,padding:'0 18px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:10,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>PITGO PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--red)'}}>SOS-вызовы</div>
          </div>
          <button onClick={load} style={{width:34,height:34,borderRadius:9,background:'var(--surf2)',display:'grid',placeItems:'center',border:'none',cursor:'pointer',color:'var(--txt3)',flexShrink:0}}>
            <Icon n="refresh" s={16}/>
          </button>
        </div>

        <div style={{flex:1,overflowY:'auto',padding: isMobile ? '14px' : '20px 22px'}}>
          <div className="fade-in" style={{maxWidth:760}}>
            {error && (
              <div style={{marginBottom:14,padding:'10px 14px',borderRadius:10,background:'var(--redDim)',color:'var(--red)',fontSize:13,fontWeight:600}}>{error}</div>
            )}

            {/* ── Faol ish ── */}
            {showActive && (
              <div style={{marginBottom:24}}>
                <div className="slbl">Текущий вызов</div>
                <div className="scard" style={{border:'1.5px solid var(--red)'}}>
                  <div style={{display:'flex',alignItems:'flex-start',gap:12,marginBottom:12}}>
                    <div style={{width:44,height:44,borderRadius:12,background:'var(--redDim)',display:'grid',placeItems:'center',flexShrink:0}}>
                      <Icon n="bolt" s={22} col="var(--red)"/>
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:4,flexWrap:'wrap'}}>
                        <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>
                          {active.serviceType?.nameRu || active.serviceType?.nameUz || 'SOS'}
                        </span>
                        {active.vehicle?.plate && <Plate v={active.vehicle.plate} sm/>}
                      </div>
                      <div style={{fontSize:12.5,color:'var(--txt2)',marginBottom:2}}>
                        {[active.vehicle?.make, active.vehicle?.model].filter(Boolean).join(' ') || '—'}
                      </div>
                      <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
                        <span style={{fontSize:12,color:'var(--txt3)'}}>{active.customer?.fullName || 'Клиент'}</span>
                        {active.customer?.phone && (
                          <a href={`tel:${active.customer.phone}`}
                            style={{display:'inline-flex',alignItems:'center',gap:4,fontSize:12,fontWeight:600,color:'var(--blue)',textDecoration:'none',fontFamily:"'JetBrains Mono',monospace"}}>
                            <Icon n="phone" s={11} col="var(--blue)"/>{active.customer.phone}
                          </a>
                        )}
                      </div>
                    </div>
                    <div style={{flexShrink:0,padding:'4px 10px',borderRadius:999,background: activeDone ? 'var(--greenDim)' : 'var(--amberDim)',color: activeDone ? 'var(--green)' : 'var(--amber)',fontSize:11.5,fontWeight:700}}>
                      {STATUS_LABEL[active.status] || active.status}
                    </div>
                  </div>

                  {/* Status tugmasi */}
                  {NEXT_STATUS[active.status] && (
                    <button disabled={acting==='advance'} onClick={() => onAdvance(NEXT_STATUS[active.status].next)}
                      style={{width:'100%',height:42,borderRadius:999,background:'var(--red)',color:'#fff',fontSize:14,fontWeight:700,border:'none',cursor:'pointer',opacity:acting==='advance'?0.6:1,marginBottom:12}}>
                      {acting==='advance' ? '…' : NEXT_STATUS[active.status].label}
                    </button>
                  )}

                  {/* Narx kiritish / to'lov holati (completed) */}
                  {activeDone && !active.payment && (
                    <div style={{padding:'12px 14px',borderRadius:12,background:'var(--surf2)',marginBottom:12}}>
                      <div style={{fontSize:13,fontWeight:700,color:'var(--txt)',marginBottom:8}}>Укажите стоимость работы</div>
                      <div style={{display:'flex',gap:8}}>
                        <input value={priceText} onChange={e => setPriceText(e.target.value)}
                          placeholder="Напр. 150000" inputMode="numeric"
                          style={{flex:1,height:40,borderRadius:10,border:'1px solid var(--hair2)',background:'var(--bgE)',color:'var(--txt)',padding:'0 12px',fontSize:14,fontFamily:"'JetBrains Mono',monospace"}}/>
                        <button disabled={acting==='price'} onClick={onSetPrice}
                          style={{height:40,padding:'0 18px',borderRadius:10,background:'var(--green)',color:'#fff',fontSize:13,fontWeight:700,border:'none',cursor:'pointer',opacity:acting==='price'?0.6:1}}>
                          {acting==='price' ? '…' : 'Отправить'}
                        </button>
                      </div>
                    </div>
                  )}
                  {activeDone && active.payment && (
                    <div style={{display:'flex',alignItems:'center',gap:10,padding:'12px 14px',borderRadius:12,background: activePaid ? 'var(--greenDim)' : 'var(--surf2)',marginBottom:12}}>
                      <Icon n={activePaid ? 'check' : 'clock'} s={18} col={activePaid ? 'var(--green)' : 'var(--txt3)'}/>
                      <div style={{flex:1}}>
                        <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:15,fontWeight:700,color:'var(--txt)'}}>{fmt(active.payment.amount)} <span style={{fontSize:11,color:'var(--txt3)'}}>сум</span></div>
                        <div style={{fontSize:12,color:'var(--txt3)'}}>{activePaid ? 'Клиент оплатил' : 'Ожидается оплата клиента'}</div>
                      </div>
                    </div>
                  )}

                  {/* Chat */}
                  {!activeDone && (
                    <div style={{borderTop:'1px solid var(--hair)',paddingTop:12}}>
                      <div style={{fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--txt3)',marginBottom:8}}>Чат с клиентом</div>
                      <div style={{maxHeight:220,overflowY:'auto',display:'flex',flexDirection:'column',gap:6,marginBottom:10}}>
                        {messages.length === 0 && (
                          <div style={{fontSize:12.5,color:'var(--txt3)',padding:'8px 0'}}>Пока нет сообщений</div>
                        )}
                        {messages.map(m => {
                          const mine = m.senderUserId === myUserId
                          return (
                            <div key={m.id} style={{alignSelf: mine ? 'flex-end' : 'flex-start',maxWidth:'80%',padding:'8px 12px',borderRadius:12,
                              background: mine ? 'var(--inv)' : 'var(--surf2)',color: mine ? 'var(--invT)' : 'var(--txt)',fontSize:13.5}}>
                              {m.body}
                              <div style={{fontSize:10,opacity:.55,marginTop:2,textAlign:'right'}}>{fmtTime(m.createdAt)}</div>
                            </div>
                          )
                        })}
                        <div ref={chatEndRef}/>
                      </div>
                      <div style={{display:'flex',gap:8}}>
                        <input value={chatText} onChange={e => setChatText(e.target.value)}
                          onKeyDown={e => { if (e.key === 'Enter') onSend() }}
                          placeholder="Написать сообщение…"
                          style={{flex:1,height:40,borderRadius:999,border:'1px solid var(--hair2)',background:'var(--bgE)',color:'var(--txt)',padding:'0 16px',fontSize:13.5}}/>
                        <button onClick={onSend}
                          style={{width:40,height:40,borderRadius:999,background:'var(--inv)',color:'var(--invT)',display:'grid',placeItems:'center',border:'none',cursor:'pointer'}}>
                          <Icon n="send" s={16}/>
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* ── Kelayotgan so'rovlar ── */}
            <div className="slbl">Входящие вызовы ({incoming.length})</div>
            {loading ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>Загрузка…</div>
            ) : incoming.length === 0 ? (
              <div style={{textAlign:'center',padding:'50px 0',color:'var(--txt3)'}}>
                <Icon n="bolt" s={44}/>
                <p style={{marginTop:14,fontSize:14}}>Новых SOS-вызовов нет</p>
                <p style={{marginTop:4,fontSize:12}}>Вызовы поблизости появятся здесь автоматически</p>
              </div>
            ) : (
              <div style={{display:'flex',flexDirection:'column',gap:10}}>
                {incoming.map(item => {
                  const svcName = item.serviceType?.nameRu || item.serviceType?.nameUz || 'SOS'
                  const car = item.vehicle ? `${item.vehicle.make || ''} ${item.vehicle.model || ''}`.trim() : ''
                  return (
                    <div key={item.dispatchId} className="scard">
                      <div style={{display:'flex',alignItems:'flex-start',gap:12,marginBottom:12}}>
                        <div style={{width:44,height:44,borderRadius:12,background:'var(--redDim)',display:'grid',placeItems:'center',flexShrink:0}}>
                          <Icon n="bolt" s={22} col="var(--red)"/>
                        </div>
                        <div style={{flex:1,minWidth:0}}>
                          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:4,flexWrap:'wrap'}}>
                            <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>{svcName}</span>
                            {item.vehicle?.plate && <Plate v={item.vehicle.plate} sm/>}
                          </div>
                          {car && <div style={{fontSize:12.5,color:'var(--txt2)',marginBottom:2}}>{car}</div>}
                          <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
                            <span style={{fontSize:12,color:'var(--txt3)'}}>{item.customer?.fullName || 'Клиент'}</span>
                            <span style={{fontSize:12,color:'var(--txt3)',fontFamily:"'JetBrains Mono',monospace"}}>{fmtTime(item.sentAt)}</span>
                          </div>
                        </div>
                        <div style={{flexShrink:0,padding:'4px 10px',borderRadius:999,background:'var(--redDim)',color:'var(--red)',fontSize:11.5,fontWeight:700,fontFamily:"'JetBrains Mono',monospace"}}>
                          {fmtDist(item.distanceMeters)}
                        </div>
                      </div>
                      <div style={{display:'flex',justifyContent:'flex-end',paddingTop:12,borderTop:'1px solid var(--hair)'}}>
                        <button disabled={!!acting} onClick={() => onAccept(item.sosRequestId)}
                          style={{height:38,padding:'0 20px',borderRadius:999,background:'var(--red)',color:'#fff',fontSize:13,fontWeight:700,cursor:'pointer',display:'flex',alignItems:'center',gap:6,border:'none',opacity:acting?0.5:1}}>
                          <Icon n="check" s={14}/>{acting===item.sosRequestId?'…':'Принять вызов'}
                        </button>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </PartnerShell>
  )
}
