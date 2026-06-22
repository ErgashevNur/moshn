'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import Plate from '@/components/ui/Plate'
import Stars from '@/components/ui/Stars'
import partnerApi from '@/lib/partnerApi'

const SC: Record<string, {label:string; bg:string; clr:string; dot:string}> = {
  pending:     {label:'Ожидает',     bg:'var(--blueDim)',   clr:'var(--blue)',  dot:'var(--blue)'},
  confirmed:   {label:'Подтверждён', bg:'var(--amberDim)',  clr:'var(--amber)', dot:'var(--amber)'},
  in_progress: {label:'В процессе',  bg:'var(--amberDim)',  clr:'var(--amber)', dot:'var(--amber)'},
  completed:   {label:'Завершён',    bg:'var(--greenDim)',  clr:'var(--green)', dot:'var(--green)'},
  cancelled:   {label:'Отменён',     bg:'var(--redDim)',    clr:'var(--red)',   dot:'var(--surf3)'},
}

function fmt(n: number) { return n.toLocaleString('uz') }
function fmtTime(d: string) {
  return new Date(d).toLocaleTimeString('uz', { hour:'2-digit', minute:'2-digit' })
}
function isToday(d: string) {
  const t = new Date(d), n = new Date()
  return t.getDate() === n.getDate() && t.getMonth() === n.getMonth() && t.getFullYear() === n.getFullYear()
}

function normalize(b: any) {
  return {
    id:      b.id,
    name:    b.customer?.fullName || 'Неизвестно',
    phone:   b.customer?.phone || '',
    plate:   b.vehicle?.plate || '—',
    car:     b.vehicle ? `${b.vehicle.make || ''} ${b.vehicle.model || ''}`.trim() || b.vehicle.plate : '—',
    svcName: b.serviceType?.nameUz || '—',
    time:    fmtTime(b.scheduledAt),
    status:  b.status as string,
    paid:    b.payment?.status === 'paid',
    amt:     b.totalPrice || 0,
    vip:     false,
    rating:  null as number | null,
  }
}

type NB = ReturnType<typeof normalize>

function DetailContent({ item, onClose, onRate, isMobile }: {
  item: NB | null
  onClose: () => void
  onRate: (id: string, r: number) => void
  isMobile?: boolean
}) {
  const [rating, setRating] = useState(0)
  const [rated, setRated]   = useState(false)

  if (!item) return (
    <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',color:'var(--txt3)',gap:12,padding:24,textAlign:'center'}}>
      <Icon n="list" s={42}/>
      <p style={{fontSize:13,marginTop:4,lineHeight:1.4}}>Выберите заказ</p>
    </div>
  )

  const s = SC[item.status] || SC.pending
  return (
    <>
      {isMobile && <div className="bsheet-handle"/>}
      <div style={{padding:'14px 20px 12px',borderBottom:'1px solid var(--hair)',flexShrink:0,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
        <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>Детали заказа</span>
        <button onClick={onClose} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer',padding:4}}><Icon n="x" s={20}/></button>
      </div>
      <div style={{flex:1,overflowY:'auto',padding:'16px 20px 20px'}}>
        <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:16,flexWrap:'wrap'}}>
          <span className="chip" style={{background:s.bg,color:s.clr}}>{s.label}</span>
          {item.paid && <span className="chip" style={{background:'var(--greenDim)',color:'var(--green)'}}>Оплачено</span>}
        </div>
        <div style={{marginBottom:18}}>
          <div style={{fontSize:21,fontWeight:700,marginBottom:4,color:'var(--txt)'}}>{item.name}</div>
          <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12.5,color:'var(--txt2)'}}>{item.phone}</div>
        </div>
        <div className="lcard" style={{marginBottom:16}}>
          {[
            ['Услуга',     item.svcName],
            ['Время',      item.time],
            ['Автомобиль', item.car],
            ['Госномер',   <Plate v={item.plate}/>],
            ['Цена',       `${fmt(item.amt)} сум`],
            ['Оплата',     item.paid ? 'Оплачено' : 'Ожидает'],
          ].map(([l,v],i) => (
            <div key={i} className="lrow">
              <span style={{fontSize:12.5,color:'var(--txt3)',flex:1}}>{l}</span>
              <span style={{fontSize:13.5,fontWeight:600,color:i===5?(item.paid?'var(--green)':'var(--txt2)'):'var(--txt)'}}>{v}</span>
            </div>
          ))}
        </div>
        {item.status === 'completed' && (
          <div style={{padding:'13px 15px',borderRadius:14,background:'var(--surf2)',marginBottom:14}}>
            <div style={{fontSize:13,fontWeight:600,marginBottom:9,color:'var(--txt)'}}>Оцените клиента</div>
            {rated || item.rating ? (
              <div style={{display:'flex',alignItems:'center',gap:8}}><Stars v={item.rating||rating} sz={18}/><span style={{fontSize:12.5,color:'var(--txt2)'}}>Оценено</span></div>
            ) : <>
              <Stars v={rating} sz={22} interactive onChange={setRating}/>
              {rating > 0 && <button onClick={() => { onRate(item.id, rating); setRated(true) }}
                style={{marginTop:11,width:'100%',height:38,borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:13,fontWeight:600,cursor:'pointer',border:'none'}}>Сохранить</button>}
            </>}
          </div>
        )}
        {/* Phone call — tel: link */}
        <a href={item.phone ? `tel:${item.phone}` : undefined}
          style={{
            display:'flex', alignItems:'center', justifyContent:'center', gap:8,
            width:'100%', height:44, borderRadius:999,
            background:'var(--surf2)', color:'var(--txt)',
            fontSize:14, fontWeight:600,
            textDecoration:'none',
            opacity: item.phone ? 1 : 0.4,
            pointerEvents: item.phone ? 'auto' : 'none',
          }}>
          <Icon n="phone" s={18}/>Позвонить клиенту
        </a>
      </div>
    </>
  )
}

function TodayView({ queue, sel, setSel, loading, isMobile }: {
  queue: NB[]
  sel: NB|null
  setSel: (b:NB|null) => void
  loading: boolean
  isMobile: boolean
}) {
  const done   = queue.filter(b => b.status === 'completed').length
  const active = queue.find(b => b.status === 'in_progress')
  const rev    = queue.filter(b => b.paid).reduce((s,b) => s+b.amt, 0)
  const today  = new Date().toLocaleDateString('ru', { day:'2-digit', month:'long', year:'numeric' })

  return (
    <div className="fade-in">
      <div className="g3" style={{marginBottom:18}}>
        {[
          {label:'Всего заказов',  val: loading ? '…' : String(queue.length),       icon:'cal'    as const, c:'var(--blue)'},
          {label:'Завершено',      val: loading ? '…' : `${done}/${queue.length}`,  icon:'check'  as const, c:'var(--green)'},
          {label:'Выручка',        val: loading ? '…' : `${fmt(rev)}`,              icon:'wallet' as const, c:'var(--gold)', mono:true},
        ].map((s,i) => (
          <div key={i} className="scard">
            <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:8}}>
              <span style={{fontSize:10,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)'}}>{s.label}</span>
              <div style={{width:30,height:30,borderRadius:9,background:`color-mix(in srgb,${s.c} 14%,transparent)`,display:'grid',placeItems:'center',color:s.c}}><Icon n={s.icon} s={15} st={2}/></div>
            </div>
            <div style={{fontSize:s.mono?14:22,fontWeight:700,letterSpacing:'-.02em',fontFamily:s.mono?"'JetBrains Mono',monospace":'inherit',color:s.c}}>{s.val}</div>
          </div>
        ))}
      </div>

      {active && (
        <div style={{display:'flex',alignItems:'center',gap:10,padding:'10px 14px',borderRadius:13,background:'var(--amberDim)',border:'1px solid rgba(245,158,11,.3)',marginBottom:14,flexWrap:'wrap'}}>
          <div style={{width:8,height:8,borderRadius:'50%',background:'var(--amber)',flexShrink:0}}/>
          <span style={{fontSize:13,fontWeight:600,color:'var(--amber)'}}>Сейчас в процессе:</span>
          <span style={{fontSize:13,color:'var(--txt)',flex:1,minWidth:0,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{active.name} — {active.svcName}</span>
          <Plate v={active.plate}/>
          <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:13,fontWeight:700,color:'var(--txt)'}}>{active.time}</div>
        </div>
      )}

      <div className="slbl">Расписание на сегодня — {today}</div>
      {loading ? (
        <div style={{textAlign:'center',padding:'40px 0',color:'var(--txt3)'}}>Загрузка…</div>
      ) : queue.length === 0 ? (
        <div style={{textAlign:'center',padding:'40px 0',color:'var(--txt3)'}}>
          <Icon n="cal" s={40}/>
          <p style={{marginTop:12,fontSize:13}}>Сегодня нет заказов</p>
        </div>
      ) : (
        <div style={{display:'flex',flexDirection:'column',gap:3}}>
          {queue.map(b => {
            const s = SC[b.status] || SC.pending
            const isActive = sel?.id === b.id
            return (
              <button key={b.id} onClick={() => setSel(isActive ? null : b)}
                style={{display:'flex',alignItems:'center',gap:11,padding:'11px 12px',borderRadius:12,cursor:'pointer',transition:'background .12s',width:'100%',background:isActive?'var(--surf)':'none',border:'none',textAlign:'left'}}>
                <span style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12,color:'var(--txt3)',fontWeight:600,width:38,flexShrink:0}}>{b.time}</span>
                <div style={{width:9,height:9,borderRadius:'50%',background:s.dot,flexShrink:0}}/>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontSize:14,fontWeight:600,color:'var(--txt)'}}>{b.name}</div>
                  <div style={{fontSize:12,color:'var(--txt3)',whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis'}}>
                    {b.svcName} · <span style={{fontFamily:"'JetBrains Mono',monospace"}}>{b.plate}</span>
                  </div>
                </div>
                <div style={{textAlign:'right',flexShrink:0}}>
                  <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:13,fontWeight:600,color:'var(--txt)'}}>{fmt(b.amt)}</div>
                  <span className="chip" style={{background:s.bg,color:s.clr,marginTop:3}}>{s.label}</span>
                </div>
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}

export default function PartnerTodayPage() {
  const router  = useRouter()
  const [queue, setQueue]       = useState<NB[]>([])
  const [loading, setLoading]   = useState(true)
  const [sel, setSel]           = useState<NB|null>(null)
  const [isMobile, setIsMobile] = useState(false)
  const [burgerOpen, setBurgerOpen] = useState(false)
  const [shopName, setShopName] = useState('Shinomontaj')

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    setLoading(true)
    partnerApi.get('/service/bookings?limit=100').then(r => {
      const all = (r.data.data?.bookings || [])
      setQueue(all.filter((b:any) => isToday(b.scheduledAt)).map(normalize))
    }).catch(() => {}).finally(() => setLoading(false))
    partnerApi.get('/service/profile').then(r => {
      const name = r.data?.data?.shopName || r.data?.shopName
      if (name) setShopName(name)
    }).catch(() => {})
  }, [router])

  const pending = queue.filter(b => b.status === 'pending').length

  const handleRate = (id: string, r: number) =>
    setQueue(q => q.map(b => b.id === id ? {...b, rating:r} : b))

  const logout = () => {
    localStorage.removeItem('partner_access_token')
    localStorage.removeItem('partner_refresh_token')
    router.push('/partner/login')
  }

  return (
    <PartnerShell pendingCount={pending}>
      {/* ── Main area ──────────────────────────────────────────────────────── */}
      <div style={{flex:1,display:'flex',flexDirection:'column',minWidth:0,overflow:'hidden'}}>
        <div style={{height:60,display:'flex',alignItems:'center',gap:14,padding:'0 18px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)',position:'relative'}}>
          <div style={{flex:1,minWidth:0}}>
            <div style={{fontSize:10,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>SHINA24 PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}}>{shopName}</div>
          </div>
          {/* Burger button — only on mobile (desktop uses sidebar) */}
          {isMobile && (
            <>
              <button
                onClick={() => setBurgerOpen(o => !o)}
                style={{width:38,height:38,borderRadius:10,background:'var(--surf2)',border:'none',display:'grid',placeItems:'center',cursor:'pointer',color:'var(--txt)',flexShrink:0}}>
                <svg width="18" height="14" viewBox="0 0 18 14" fill="none">
                  <rect y="0"  width="18" height="2" rx="1" fill="currentColor"/>
                  <rect y="6"  width="18" height="2" rx="1" fill="currentColor"/>
                  <rect y="12" width="18" height="2" rx="1" fill="currentColor"/>
                </svg>
              </button>
              {burgerOpen && (
                <>
                  <div onClick={() => setBurgerOpen(false)} style={{position:'fixed',inset:0,zIndex:200}}/>
                  <div style={{
                    position:'absolute', top:52, right:16, zIndex:201,
                    background:'var(--surf)', border:'1px solid var(--hair2)',
                    borderRadius:16, minWidth:180, overflow:'hidden',
                    boxShadow:'0 8px 32px rgba(0,0,0,.45)',
                    animation:'fade .15s ease',
                  }}>
                    {[
                      {icon:'chart',  label:'Hisobot', href:'/partner/stats'},
                      {icon:'wallet', label:'Narxlar', href:'/partner/prices'},
                    ].map((item, i) => (
                      <button key={i} onClick={() => { setBurgerOpen(false); router.push(item.href) }}
                        style={{display:'flex',alignItems:'center',gap:11,width:'100%',padding:'13px 16px',background:'none',border:'none',cursor:'pointer',color:'var(--txt)',fontSize:14,fontWeight:600,textAlign:'left',borderBottom:'1px solid var(--hair)'}}>
                        <Icon n={item.icon as any} s={18}/>
                        {item.label}
                      </button>
                    ))}
                    <button onClick={() => { setBurgerOpen(false); logout() }}
                      style={{display:'flex',alignItems:'center',gap:11,width:'100%',padding:'13px 16px',background:'none',border:'none',cursor:'pointer',color:'var(--red)',fontSize:14,fontWeight:600,textAlign:'left'}}>
                      <Icon n="logout" s={18} col="var(--red)"/>
                      Chiqish
                    </button>
                  </div>
                </>
              )}
            </>
          )}
        </div>
        <div style={{flex:1,overflowY:'auto',padding: isMobile ? '16px' : '20px 22px'}}>
          <TodayView queue={queue} sel={sel} setSel={setSel} loading={loading} isMobile={isMobile}/>
        </div>
      </div>

      {/* ── Desktop side panel ─────────────────────────────────────────────── */}
      {!isMobile && (
        <div style={{width:320,background:'var(--bgE)',borderLeft:'1px solid var(--hair)',display:'flex',flexDirection:'column',flexShrink:0,overflow:'hidden'}}>
          <DetailContent item={sel} onClose={() => setSel(null)} onRate={handleRate}/>
        </div>
      )}

      {/* ── Mobile bottom sheet ────────────────────────────────────────────── */}
      {isMobile && sel && (
        <>
          <div className="bsheet-backdrop" onClick={() => setSel(null)}/>
          <div className="bsheet" style={{bottom:64}}>
            <DetailContent item={sel} onClose={() => setSel(null)} onRate={handleRate} isMobile/>
          </div>
        </>
      )}
    </PartnerShell>
  )
}
