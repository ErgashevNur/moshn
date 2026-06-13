'use client'
import { useEffect, useState } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import Icon from '@/components/ui/Icon'
import api from '@/lib/api'

const DAYS = ['Du','Se','Ch','Pa','Ju','Sh','Ya']
const WEEK = [8400000,9200000,7600000,11000000,9800000,13200000,8000000]
const maxW = Math.max(...WEEK)
function fmtM(n: number) { return (n/1_000_000).toFixed(1).replace('.0','') }

export default function DashboardPage() {
  const [stats, setStats] = useState<any>(null)
  const [shops, setShops] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.get('/admin/stats'),
      api.get('/admin/shops?limit=5'),
    ]).then(([s, sh]) => {
      setStats(s.data.data)
      setShops(sh.data.data?.shops || [])
    }).finally(() => setLoading(false))
  }, [])

  const kpis = stats ? [
    {l:'Foydalanuvchilar', v: String(stats.users ?? 0),        d:8.1,  ic:'users'  as const, c:'var(--gold)'},
    {l:'Faol servislar',   v: String(stats.active_shops ?? 0), d:4.3,  ic:'store'  as const, c:'var(--blue)'},
    {l:'Jami buyurtmalar', v: String(stats.bookings ?? 0),     d:12.3, ic:'list'   as const, c:'var(--amber)'},
    {l:'Avtomobillar',     v: String(stats.vehicles ?? 0),     d:6.2,  ic:'car'    as const, c:'var(--green)'},
  ] : [
    {l:'Foydalanuvchilar',v:'—',d:0,ic:'users'  as const,c:'var(--gold)'},
    {l:'Faol servislar',  v:'—',d:0,ic:'store'  as const,c:'var(--blue)'},
    {l:'Jami buyurtmalar',v:'—',d:0,ic:'list'   as const,c:'var(--amber)'},
    {l:'Avtomobillar',    v:'—',d:0,ic:'car'    as const,c:'var(--green)'},
  ]

  const activity = [
    {ic:'store'  as const,c:'var(--blue)',  txt:"Express Tire ro'yxatdan o'tdi",t:'12 daq'},
    {ic:'check'  as const,c:'var(--green)', txt:'Bugungi buyurtmalar bajarilmoqda',t:'30 daq'},
    {ic:'crown'  as const,c:'var(--gold)',  txt:'Yangi VIP mijozlar qo\'shildi',t:'1 soat'},
    {ic:'bell'   as const,c:'var(--purple)',txt:'Sezon eslatmasi yuborildi',t:'4 soat'},
  ]

  return (
    <AdminShell title="Dashboard">
      <div className="fade-in">
        <div className="g4" style={{marginBottom:18}}>
          {kpis.map((s,i) => (
            <div key={i} className="kpi">
              <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:12}}>
                <span style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)'}}>{s.l}</span>
                <div style={{width:34,height:34,borderRadius:9,background:`color-mix(in srgb,${s.c} 14%,transparent)`,display:'grid',placeItems:'center',color:s.c}}>
                  <Icon n={s.ic} s={17} st={2}/>
                </div>
              </div>
              <div style={{fontSize:26,fontWeight:700,letterSpacing:'-.02em',marginBottom:8,color:'var(--txt)'}}>
                {loading ? <span style={{color:'var(--txt3)'}}>…</span> : s.v}
              </div>
              {!loading && s.d !== 0 && (
                <div style={{display:'flex',alignItems:'center',gap:5}}>
                  <span style={{color:s.d>0?'var(--green)':'var(--red)',fontWeight:600,fontSize:12.5}}>{s.d>0?'+':''}{s.d}%</span>
                  <span style={{color:'var(--txt3)',fontSize:12}}>o'tgan haftaga</span>
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="g2" style={{marginBottom:18}}>
          <div className="card">
            <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:18}}>
              <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>Haftalik tushum (taxminiy)</span>
              <span style={{fontFamily:"'JetBrains Mono',monospace",fontSize:14,fontWeight:700,color:'var(--green)'}}>{fmtM(WEEK.reduce((s,v)=>s+v,0))} mln so'm</span>
            </div>
            <div style={{display:'flex',alignItems:'stretch',gap:7,height:96,marginBottom:8}}>
              {WEEK.map((r,i) => (
                <div key={i} className="cbar-wrap" style={{height:96}}>
                  <div style={{flex:1,display:'flex',alignItems:'flex-end',width:'100%'}}>
                    <div className="cbar" style={{height:`${Math.round((r/maxW)*100)}%`,background:i===6?'var(--inv)':'var(--surf2)'}}/>
                  </div>
                  <span style={{fontSize:10,color:i===6?'var(--txt)':'var(--txt3)',fontWeight:700}}>{DAYS[i]}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="card">
            <div style={{fontSize:15,fontWeight:700,marginBottom:14,color:'var(--txt)'}}>So'nggi faollik</div>
            {activity.map((a,i) => (
              <div key={i} style={{display:'flex',alignItems:'center',gap:11,padding:'9px 0',borderBottom:i<activity.length-1?'1px solid var(--hair)':'none'}}>
                <div style={{width:32,height:32,borderRadius:8,background:`color-mix(in srgb,${a.c} 14%,transparent)`,display:'grid',placeItems:'center',color:a.c,flexShrink:0}}>
                  <Icon n={a.ic} s={15}/>
                </div>
                <div style={{flex:1,fontSize:13,color:'var(--txt)'}}>{a.txt}</div>
                <span style={{fontSize:11.5,color:'var(--txt3)',flexShrink:0}}>{a.t}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="card" style={{padding:0,overflow:'hidden'}}>
          <div style={{padding:'14px 20px',borderBottom:'1px solid var(--hair)'}}>
            <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>Top servislar (buyurtmalar bo'yicha)</span>
          </div>
          <table className="tbl">
            <thead><tr><th>#</th><th>Servis</th><th>Manzil</th><th>Reyting</th><th>Buyurtmalar</th><th>Holat</th></tr></thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} style={{textAlign:'center',padding:24,color:'var(--txt3)'}}>Yuklanmoqda…</td></tr>
              ) : shops.length === 0 ? (
                <tr><td colSpan={6} style={{textAlign:'center',padding:24,color:'var(--txt3)'}}>Ma'lumot yo'q</td></tr>
              ) : [...shops].sort((a,b)=>(b.totalBookings||0)-(a.totalBookings||0)).slice(0,5).map((s,i) => (
                <tr key={s.id}>
                  <td style={{color:'var(--txt3)',fontWeight:600,fontSize:12}}>{i+1}</td>
                  <td style={{fontWeight:600,color:'var(--txt)'}}>{s.shopName || '—'}</td>
                  <td><div style={{display:'flex',alignItems:'center',gap:5,color:'var(--txt2)'}}><Icon n="pin" s={13}/>{s.address || '—'}</div></td>
                  <td>
                    {s.ratingAvg > 0
                      ? <span style={{display:'flex',alignItems:'center',gap:4,color:'var(--gold)',fontWeight:700,fontSize:13}}><Icon n="starF" s={13}/>{s.ratingAvg.toFixed(1)}</span>
                      : <span style={{color:'var(--txt3)'}}>—</span>}
                  </td>
                  <td style={{color:'var(--txt2)'}}>{s.totalBookings ?? 0}</td>
                  <td>
                    <span className={`badge ${s.verificationStatus==='verified'?'b-green':s.verificationStatus==='pending'?'b-amber':'b-red'}`}>
                      {s.verificationStatus==='verified'?'Faol':s.verificationStatus==='pending'?'Tekshiruv':'Bloklangan'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </AdminShell>
  )
}
