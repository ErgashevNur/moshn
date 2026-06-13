'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import Plate from '@/components/ui/Plate'
import Stars from '@/components/ui/Stars'
import partnerApi from '@/lib/partnerApi'

const SC: Record<string, {label:string; bg:string; clr:string; dot:string}> = {
  pending:     {label:'Kutilmoqda',   bg:'var(--blueDim)',   clr:'var(--blue)',  dot:'var(--blue)'},
  confirmed:   {label:'Tasdiqlangan', bg:'var(--amberDim)',  clr:'var(--amber)', dot:'var(--amber)'},
  in_progress: {label:'Jarayonda',    bg:'var(--amberDim)',  clr:'var(--amber)', dot:'var(--amber)'},
  completed:   {label:'Tugadi',       bg:'var(--greenDim)',  clr:'var(--green)', dot:'var(--green)'},
  cancelled:   {label:'Bekor',        bg:'var(--redDim)',    clr:'var(--red)',   dot:'var(--surf3)'},
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
    name:    b.customer?.fullName || 'Noma\'lum',
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

function DetailPanel({ item, onClose, onRate }: { item: NB | null; onClose: () => void; onRate: (id: string, r: number) => void }) {
  const [rating, setRating] = useState(0)
  const [rated, setRated]   = useState(false)

  if (!item) return (
    <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',color:'var(--txt3)',gap:12,padding:24,textAlign:'center'}}>
      <Icon n="list" s={42}/>
      <p style={{fontSize:13,marginTop:4,lineHeight:1.4}}>Buyurtmani tanlang</p>
    </div>
  )
  const s = SC[item.status] || SC.pending
  return (
    <>
      <div style={{padding:'17px 20px 13px',borderBottom:'1px solid var(--hair)',flexShrink:0,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
        <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>Buyurtma tafsiloti</span>
        <button onClick={onClose} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer'}}><Icon n="x" s={20}/></button>
      </div>
      <div style={{flex:1,overflowY:'auto',padding:'16px 20px 20px'}}>
        <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:16,flexWrap:'wrap'}}>
          <span className="chip" style={{background:s.bg,color:s.clr}}>{s.label}</span>
          {item.paid && <span className="chip" style={{background:'var(--greenDim)',color:'var(--green)'}}>To'langan</span>}
        </div>
        <div style={{marginBottom:18}}>
          <div style={{fontSize:21,fontWeight:700,marginBottom:4,color:'var(--txt)'}}>{item.name}</div>
          <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12.5,color:'var(--txt2)'}}>{item.phone}</div>
        </div>
        <div className="lcard" style={{marginBottom:16}}>
          {[
            ['Xizmat',   item.svcName],
            ['Vaqt',     item.time],
            ['Avtomobil',item.car],
            ['Davlat raqami', <Plate v={item.plate}/>],
            ['Narx',     `${fmt(item.amt)} so'm`],
            ["To'lov",   item.paid ? "To'langan" : 'Kutilmoqda'],
          ].map(([l,v],i) => (
            <div key={i} className="lrow">
              <span style={{fontSize:12.5,color:'var(--txt3)',flex:1}}>{l}</span>
              <span style={{fontSize:13.5,fontWeight:600,color:i===5?(item.paid?'var(--green)':'var(--txt2)'):'var(--txt)'}}>{v}</span>
            </div>
          ))}
        </div>
        {item.status === 'completed' && (
          <div style={{padding:'13px 15px',borderRadius:14,background:'var(--surf2)',marginBottom:14}}>
            <div style={{fontSize:13,fontWeight:600,marginBottom:9,color:'var(--txt)'}}>Mijozni baholang</div>
            {rated || item.rating ? (
              <div style={{display:'flex',alignItems:'center',gap:8}}><Stars v={item.rating||rating} sz={18}/><span style={{fontSize:12.5,color:'var(--txt2)'}}>Baholandi</span></div>
            ) : <>
              <Stars v={rating} sz={22} interactive onChange={setRating}/>
              {rating > 0 && <button onClick={() => { onRate(item.id, rating); setRated(true) }}
                style={{marginTop:11,width:'100%',height:38,borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:13,fontWeight:600,cursor:'pointer',border:'none'}}>Saqlash</button>}
            </>}
          </div>
        )}
        <button style={{width:'100%',height:44,borderRadius:999,background:'var(--surf2)',color:'var(--txt)',fontSize:14,fontWeight:600,cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center',gap:8,border:'none'}}>
          <Icon n="phone" s={18}/>Mijozga qo'ng'iroq
        </button>
      </div>
    </>
  )
}

function TodayView({ queue, sel, setSel, loading }: { queue: NB[]; sel: NB|null; setSel: (b:NB|null)=>void; loading: boolean }) {
  const done   = queue.filter(b => b.status === 'completed').length
  const active = queue.find(b => b.status === 'in_progress')
  const rev    = queue.filter(b => b.paid).reduce((s,b) => s+b.amt, 0)
  const today  = new Date().toLocaleDateString('uz', { day:'2-digit', month:'long', year:'numeric' })

  return (
    <div className="fade-in">
      <div className="g3" style={{marginBottom:18}}>
        {[
          {label:'Jami buyurtma',  val: loading ? '…' : String(queue.length),            icon:'cal'    as const, c:'var(--blue)'},
          {label:'Tugallangan',    val: loading ? '…' : `${done}/${queue.length}`,        icon:'check'  as const, c:'var(--green)'},
          {label:'Bugungi tushum', val: loading ? '…' : `${fmt(rev)} so'm`,              icon:'wallet' as const, c:'var(--gold)', mono:true},
        ].map((s,i) => (
          <div key={i} className="scard">
            <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:10}}>
              <span style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)'}}>{s.label}</span>
              <div style={{width:34,height:34,borderRadius:9,background:`color-mix(in srgb,${s.c} 14%,transparent)`,display:'grid',placeItems:'center',color:s.c}}><Icon n={s.icon} s={17} st={2}/></div>
            </div>
            <div style={{fontSize:s.mono?15:26,fontWeight:700,letterSpacing:'-.02em',fontFamily:s.mono?"'JetBrains Mono',monospace":'inherit',color:s.c}}>{s.val}</div>
          </div>
        ))}
      </div>

      {active && (
        <div style={{display:'flex',alignItems:'center',gap:12,padding:'11px 15px',borderRadius:13,background:'var(--amberDim)',border:'1px solid rgba(245,158,11,.3)',marginBottom:16}}>
          <div style={{width:8,height:8,borderRadius:'50%',background:'var(--amber)',flexShrink:0}}/>
          <span style={{fontSize:13.5,fontWeight:600,color:'var(--amber)'}}>Hozir jarayonda:</span>
          <span style={{fontSize:13.5,color:'var(--txt)'}}>{active.name} — {active.svcName}</span>
          <Plate v={active.plate}/>
          <div style={{marginLeft:'auto',fontFamily:"'JetBrains Mono',monospace",fontSize:13,fontWeight:700,color:'var(--txt)'}}>{active.time}</div>
        </div>
      )}

      <div className="slbl">Bugungi jadval — {today}</div>
      {loading ? (
        <div style={{textAlign:'center',padding:'40px 0',color:'var(--txt3)'}}>Yuklanmoqda…</div>
      ) : queue.length === 0 ? (
        <div style={{textAlign:'center',padding:'40px 0',color:'var(--txt3)'}}>
          <Icon n="cal" s={40}/>
          <p style={{marginTop:12,fontSize:13}}>Bugun buyurtma yo'q</p>
        </div>
      ) : (
        <div style={{display:'flex',flexDirection:'column',gap:3}}>
          {queue.map(b => {
            const s = SC[b.status] || SC.pending
            return (
              <button key={b.id} onClick={() => setSel(sel?.id===b.id?null:b)}
                style={{display:'flex',alignItems:'center',gap:11,padding:'10px 11px',borderRadius:12,cursor:'pointer',transition:'background .12s',width:'100%',background:sel?.id===b.id?'var(--surf)':'none',border:'none',textAlign:'left'}}>
                <span style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12,color:'var(--txt3)',fontWeight:600,width:40,flexShrink:0}}>{b.time}</span>
                <div style={{width:9,height:9,borderRadius:'50%',background:s.dot,flexShrink:0}}/>
                <div style={{flex:1,minWidth:0}}>
                  <div style={{fontSize:14,fontWeight:600,color:'var(--txt)'}}>{b.name}</div>
                  <div style={{fontSize:12,color:'var(--txt3)',whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis'}}>
                    {b.svcName} · <span style={{fontFamily:"'JetBrains Mono',monospace"}}>{b.plate}</span> · {b.car}
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
  const [queue, setQueue]     = useState<NB[]>([])
  const [loading, setLoading] = useState(true)
  const [sel, setSel]         = useState<NB|null>(null)

  const load = useCallback(() => {
    setLoading(true)
    partnerApi.get('/service/bookings?limit=100').then(r => {
      const all: NB[] = (r.data.data?.bookings || []).map(normalize)
      setQueue(all.filter(b => isToday(b.time ? '' : '') || true).filter((_,i,arr) => {
        const raw = r.data.data?.bookings[i]
        return raw && isToday(raw.scheduledAt)
      }))
    }).catch(() => {}).finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    // Re-fetch with raw data
    setLoading(true)
    partnerApi.get('/service/bookings?limit=100').then(r => {
      const all = (r.data.data?.bookings || [])
      setQueue(all.filter((b:any) => isToday(b.scheduledAt)).map(normalize))
    }).catch(() => {}).finally(() => setLoading(false))
  }, [router])

  const pending = queue.filter(b => b.status === 'pending').length
  const now = new Date()
  const timeStr = `${now.getHours().toString().padStart(2,'0')}:${now.getMinutes().toString().padStart(2,'0')}`

  return (
    <PartnerShell pendingCount={pending}>
      <div style={{flex:1,display:'flex',flexDirection:'column',minWidth:0,overflow:'hidden'}}>
        <div style={{height:60,display:'flex',alignItems:'center',gap:14,padding:'0 22px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>SHINA24 PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)'}}>Shinmaster Pro</div>
          </div>
          <div style={{display:'flex',alignItems:'center',gap:11}}>
            <div style={{display:'flex',alignItems:'center',gap:6,fontSize:13,color:'var(--txt2)'}}><div style={{width:7,height:7,borderRadius:'50%',background:'var(--green)'}}/>Onlayn</div>
            <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:13,color:'var(--txt3)',padding:'4px 10px',borderRadius:8,background:'var(--surf2)'}}>{timeStr}</div>
          </div>
        </div>
        <div style={{flex:1,overflowY:'auto',padding:'20px 22px'}}>
          <TodayView queue={queue} sel={sel} setSel={setSel} loading={loading}/>
        </div>
      </div>

      <div style={{width:336,background:'var(--bgE)',borderLeft:'1px solid var(--hair)',display:'flex',flexDirection:'column',flexShrink:0,overflow:'hidden'}}>
        <DetailPanel item={sel} onClose={() => setSel(null)}
          onRate={(id, r) => setQueue(q => q.map(b => b.id===id ? {...b, rating:r} : b))}/>
      </div>
    </PartnerShell>
  )
}
