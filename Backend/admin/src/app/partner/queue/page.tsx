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
        <div style={{height:60,display:'flex',alignItems:'center',gap:14,padding:'0 22px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>SHINA24 PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)'}}>Navbat</div>
          </div>
          <button onClick={load} style={{width:34,height:34,borderRadius:9,background:'var(--surf2)',display:'grid',placeItems:'center',border:'none',cursor:'pointer',color:'var(--txt3)'}}>
            <Icon n="refresh" s={16}/>
          </button>
        </div>

        <div style={{flex:1,overflowY:'auto',padding:'20px 22px'}}>
          <div className="fade-in">
            <div className="slbl">Tasdiqlash kutilmoqda ({pendingCount})</div>

            {loading ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>Yuklanmoqda…</div>
            ) : pendingCount === 0 ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>
                <Icon n="check" s={44}/>
                <p style={{marginTop:14,fontSize:14}}>Barcha so'rovlar ko'rib chiqildi</p>
              </div>
            ) : (
              <div style={{display:'flex',flexDirection:'column',gap:11}}>
                {bookings.map(b => {
                  const name    = b.customer?.fullName || 'Noma\'lum'
                  const svcName = b.serviceType?.nameUz || '—'
                  const car     = b.vehicle ? `${b.vehicle.make || ''} ${b.vehicle.model || ''}`.trim() || b.vehicle.plate : '—'
                  const plate   = b.vehicle?.plate || '—'
                  const time    = fmtTime(b.scheduledAt)
                  const amt     = b.totalPrice || 0

                  return (
                    <div key={b.id} className="scard">
                      <div style={{display:'flex',alignItems:'center',gap:13,marginBottom:13}}>
                        <div style={{width:46,height:46,borderRadius:13,background:'var(--surf2)',display:'grid',placeItems:'center',flexShrink:0}}>
                          <Icon n="car" s={24}/>
                        </div>
                        <div style={{flex:1}}>
                          <div style={{fontSize:16,fontWeight:600,color:'var(--txt)',marginBottom:3}}>{name}</div>
                          <div style={{fontSize:13,color:'var(--txt2)'}}>{svcName} · {car}</div>
                        </div>
                        <div style={{textAlign:'right'}}>
                          <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:17,fontWeight:700,color:'var(--txt)'}}>{fmt(amt)}</div>
                          <div style={{fontSize:12.5,color:'var(--txt3)',marginTop:2,fontFamily:"'JetBrains Mono',monospace"}}>{time}</div>
                        </div>
                      </div>
                      <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',paddingTop:13,borderTop:'1px solid var(--hair)'}}>
                        <Plate v={plate}/>
                        <div style={{display:'flex',gap:9}}>
                          <button disabled={!!acting} onClick={() => onDecline(b.id)}
                            style={{height:38,padding:'0 16px',borderRadius:999,border:'1.5px solid rgba(229,56,43,.4)',color:'var(--red)',fontSize:13,fontWeight:600,background:'transparent',cursor:'pointer',display:'flex',alignItems:'center',gap:6,opacity:acting?0.5:1}}>
                            <Icon n="x" s={15}/>{acting===b.id+'_dec'?'…':'Rad'}
                          </button>
                          <button disabled={!!acting} onClick={() => onAccept(b.id)}
                            style={{height:38,padding:'0 18px',borderRadius:999,background:'var(--green)',color:'#fff',fontSize:13,fontWeight:600,cursor:'pointer',display:'flex',alignItems:'center',gap:6,border:'none',opacity:acting?0.5:1}}>
                            <Icon n="check" s={15}/>{acting===b.id+'_acc'?'…':'Qabul'}
                          </button>
                        </div>
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
