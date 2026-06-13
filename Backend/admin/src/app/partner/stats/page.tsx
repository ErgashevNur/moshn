'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import partnerApi from '@/lib/partnerApi'

function fmt(n: number) { return n.toLocaleString('uz') }

const DAYS = ['Du','Se','Ch','Pa','Ju','Sh','Ya']

export default function PartnerStatsPage() {
  const router  = useRouter()
  const [bookings, setBookings] = useState<any[]>([])
  const [loading, setLoading]   = useState(true)
  const [pendingCount, setPendingCount] = useState(0)

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    Promise.all([
      partnerApi.get('/service/bookings?limit=200'),
      partnerApi.get('/service/bookings?status=pending&limit=1'),
    ]).then(([r, pR]) => {
      setBookings(r.data.data?.bookings || [])
      setPendingCount(pR.data.data?.total || 0)
    }).catch(() => {}).finally(() => setLoading(false))
  }, [router])

  // Compute stats
  const completed = bookings.filter(b => b.status === 'completed')
  const totalRev  = completed.reduce((s, b) => s + (b.totalPrice || 0), 0)

  // Weekly revenue (last 7 days)
  const now = new Date()
  const dayRevs = Array(7).fill(0)
  completed.forEach(b => {
    const d  = new Date(b.scheduledAt)
    const diff = Math.floor((now.getTime() - d.getTime()) / 86400000)
    if (diff >= 0 && diff < 7) dayRevs[6 - diff] += b.totalPrice || 0
  })
  const maxR = Math.max(...dayRevs, 1)

  // Service type breakdown
  const svcMap: Record<string, {name:string; cnt:number}> = {}
  bookings.forEach(b => {
    const k = b.serviceType?.nameUz || 'Boshqa'
    if (!svcMap[k]) svcMap[k] = { name: k, cnt: 0 }
    svcMap[k].cnt++
  })
  const svcList = Object.values(svcMap).sort((a,b) => b.cnt - a.cnt)
  const maxCnt  = svcList[0]?.cnt || 1

  const weekTotal = dayRevs.reduce((s, v) => s + v, 0)

  return (
    <PartnerShell pendingCount={pendingCount}>
      <div style={{flex:1,display:'flex',flexDirection:'column',minWidth:0,overflow:'hidden'}}>
        <div style={{height:60,display:'flex',alignItems:'center',padding:'0 22px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>SHINA24 PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)'}}>Hisobot</div>
          </div>
        </div>

        <div style={{flex:1,overflowY:'auto',padding:'20px 22px'}}>
          {loading ? (
            <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>Yuklanmoqda…</div>
          ) : (
            <div className="fade-in">
              <div className="g2" style={{marginBottom:14}}>
                <div className="scard">
                  <div className="slbl" style={{marginBottom:14}}>So'nggi 7 kunlik tushum</div>
                  <div style={{display:'flex',alignItems:'flex-end',gap:7,height:90,marginBottom:8}}>
                    {dayRevs.map((r,i) => (
                      <div key={i} style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',gap:5}}>
                        <div style={{width:'100%',borderRadius:6,background:i===6?'var(--inv)':'var(--surf2)',height:`${Math.max(2, Math.round((r/maxR)*84))}px`,minHeight:2,transition:'height .6s ease'}}/>
                        <span style={{fontSize:10,color:i===6?'var(--txt)':'var(--txt3)',fontWeight:700}}>{DAYS[i]}</span>
                      </div>
                    ))}
                  </div>
                  <div style={{display:'flex',justifyContent:'space-between',paddingTop:12,borderTop:'1px solid var(--hair)'}}>
                    <span style={{fontSize:12.5,color:'var(--txt3)'}}>Haftalik jami</span>
                    <span style={{fontFamily:"'JetBrains Mono',monospace",fontSize:14,fontWeight:700,color:'var(--txt)'}}>{fmt(weekTotal)} so'm</span>
                  </div>
                </div>

                <div className="scard">
                  <div className="slbl" style={{marginBottom:14}}>Xizmat tahlili</div>
                  {svcList.length === 0 ? (
                    <div style={{color:'var(--txt3)',fontSize:13}}>Ma'lumot yo'q</div>
                  ) : (
                    <div style={{display:'flex',flexDirection:'column',gap:11}}>
                      {svcList.map(s => (
                        <div key={s.name}>
                          <div style={{display:'flex',justifyContent:'space-between',marginBottom:6}}>
                            <span style={{fontSize:13.5,fontWeight:500,color:'var(--txt)'}}>{s.name}</span>
                            <span style={{fontSize:12.5,color:'var(--txt3)'}}>{s.cnt} ta</span>
                          </div>
                          <div className="rbar"><div className="rbar-f" style={{width:`${(s.cnt/maxCnt)*100}%`,background:'var(--inv)'}}/></div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              <div className="g4">
                {[
                  {l:"Jami tushum",         v: `${fmt(totalRev)} so'm`,         c:'var(--green)'},
                  {l:'Tugallangan buyurtma', v: String(completed.length),         c:'var(--blue)'},
                  {l:'Jami buyurtma',        v: String(bookings.length),          c:'var(--gold)'},
                  {l:"Bekor qilingan",       v: String(bookings.filter(b=>b.status==='cancelled').length), c:'var(--red)'},
                ].map((s,i) => (
                  <div key={i} className="scard" style={{textAlign:'center'}}>
                    <div style={{fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--txt3)',marginBottom:10}}>{s.l}</div>
                    <div style={{fontSize:18,fontWeight:700,color:s.c,fontFamily:"'JetBrains Mono',monospace"}}>{s.v}</div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </PartnerShell>
  )
}
