'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import Plate from '@/components/ui/Plate'
import partnerApi from '@/lib/partnerApi'

function fmt(n: number) { return n.toLocaleString('uz') }
function fmtTime(d: string) {
  return new Date(d).toLocaleTimeString('uz', { hour:'2-digit', minute:'2-digit' })
}

export default function PartnerQueuePage() {
  const router = useRouter()
  const [bookings, setBookings] = useState<any[]>([])
  const [loading, setLoading]   = useState(true)
  const [acting, setActing]     = useState('')
  const [isMobile, setIsMobile] = useState(false)

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  const load = useCallback(() => {
    setLoading(true)
    partnerApi.get('/service/bookings?status=pending&limit=50').then(r => {
      setBookings(r.data.data?.bookings || [])
    }).catch(() => {}).finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    load()
  }, [router, load])

  const onAccept = async (id: string) => {
    setActing(id + '_acc')
    try {
      await partnerApi.put(`/service/bookings/${id}/confirm`)
      setBookings(bs => bs.filter(b => b.id !== id))
    } finally { setActing('') }
  }

  const onDecline = async (id: string) => {
    setActing(id + '_dec')
    try {
      await partnerApi.put(`/service/bookings/${id}/cancel`)
      setBookings(bs => bs.filter(b => b.id !== id))
    } finally { setActing('') }
  }

  const pendingCount = bookings.length

  return (
    <PartnerShell pendingCount={pendingCount}>
      <div style={{flex:1,display:'flex',flexDirection:'column',minWidth:0,overflow:'hidden'}}>
        {/* Header */}
        <div style={{height:60,display:'flex',alignItems:'center',gap:14,padding:'0 18px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:10,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>SHINA24 PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)'}}>Очередь</div>
          </div>
          <button onClick={load} style={{width:34,height:34,borderRadius:9,background:'var(--surf2)',display:'grid',placeItems:'center',border:'none',cursor:'pointer',color:'var(--txt3)',flexShrink:0}}>
            <Icon n="refresh" s={16}/>
          </button>
        </div>

        <div style={{flex:1,overflowY:'auto',padding: isMobile ? '14px' : '20px 22px'}}>
          <div className="fade-in">
            <div className="slbl">Ожидают подтверждения ({pendingCount})</div>

            {loading ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>Загрузка…</div>
            ) : pendingCount === 0 ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>
                <Icon n="check" s={44}/>
                <p style={{marginTop:14,fontSize:14}}>Все заявки рассмотрены</p>
              </div>
            ) : (
              <div style={{display:'flex',flexDirection:'column',gap:10}}>
                {bookings.map(b => {
                  const name    = b.customer?.fullName || 'Неизвестно'
                  const phone   = b.customer?.phone || ''
                  const svcName = b.serviceType?.nameUz || '—'
                  const car     = b.vehicle ? `${b.vehicle.make || ''} ${b.vehicle.model || ''}`.trim() || b.vehicle.plate : '—'
                  const plate   = b.vehicle?.plate || '—'
                  const time    = fmtTime(b.scheduledAt)
                  const amt     = b.totalPrice || 0

                  return (
                    <div key={b.id} className="scard">
                      {/* Top row: car icon + car+plate + amount */}
                      <div style={{display:'flex',alignItems:'flex-start',gap:12,marginBottom:12}}>
                        <div style={{width:44,height:44,borderRadius:12,background:'var(--surf2)',display:'grid',placeItems:'center',flexShrink:0}}>
                          <Icon n="car" s={22}/>
                        </div>
                        <div style={{flex:1,minWidth:0}}>
                          {/* Mashina markasi + raqami (asosiy) */}
                          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:4,flexWrap:'wrap'}}>
                            <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>{car}</span>
                            <Plate v={plate} sm/>
                          </div>
                          {/* Xizmat turi */}
                          <div style={{fontSize:12.5,color:'var(--txt2)',marginBottom:2}}>{svcName}</div>
                          {/* Mijoz ismi va telefon raqami (ikkinchi darajali) */}
                          <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
                            <span style={{fontSize:12,color:'var(--txt3)'}}>{name}</span>
                            {phone && (
                              <a href={`tel:${phone}`} onClick={e => e.stopPropagation()}
                                style={{display:'inline-flex',alignItems:'center',gap:4,fontSize:12,fontWeight:600,color:'var(--blue)',textDecoration:'none',fontFamily:"'JetBrains Mono',monospace"}}>
                                <Icon n="phone" s={11} col="var(--blue)"/>{phone}
                              </a>
                            )}
                          </div>
                        </div>
                        <div style={{textAlign:'right',flexShrink:0}}>
                          <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:16,fontWeight:700,color:'var(--txt)'}}>{fmt(amt)} <span style={{fontSize:11,fontWeight:500,color:'var(--txt3)'}}>so'm</span></div>
                          <div style={{fontSize:12,color:'var(--txt3)',fontFamily:"'JetBrains Mono',monospace",marginTop:2}}>{time}</div>
                        </div>
                      </div>

                      {/* Bottom row: tugmalar */}
                      <div style={{display:'flex',alignItems:'center',justifyContent:'flex-end',paddingTop:12,borderTop:'1px solid var(--hair)',gap:8}}>
                        <button disabled={!!acting} onClick={() => onDecline(b.id)}
                          style={{height:38,padding:'0 14px',borderRadius:999,border:'1.5px solid rgba(229,56,43,.4)',color:'var(--red)',fontSize:13,fontWeight:600,background:'transparent',cursor:'pointer',display:'flex',alignItems:'center',gap:5,opacity:acting?0.5:1,whiteSpace:'nowrap'}}>
                          <Icon n="x" s={14}/>{acting===b.id+'_dec'?'…':'Отказ'}
                        </button>
                        <button disabled={!!acting} onClick={() => onAccept(b.id)}
                          style={{height:38,padding:'0 16px',borderRadius:999,background:'var(--green)',color:'#fff',fontSize:13,fontWeight:600,cursor:'pointer',display:'flex',alignItems:'center',gap:5,border:'none',opacity:acting?0.5:1,whiteSpace:'nowrap'}}>
                          <Icon n="check" s={14}/>{acting===b.id+'_acc'?'…':'Принять'}
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
