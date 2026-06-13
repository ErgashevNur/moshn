'use client'
import { useEffect, useState } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import api from '@/lib/api'

function fmt(n: number) { return n.toLocaleString('uz') }
function fmtDate(d: string) {
  return new Date(d).toLocaleDateString('uz', { day:'2-digit', month:'2-digit', year:'2-digit', hour:'2-digit', minute:'2-digit' })
}

const MN = ['Yan','Fev','Mar','Apr','May','Iyn','Iyl','Avg','Sen','Okt','Noy','Dek']

export default function FinancePage() {
  const [stats, setStats]       = useState<any>(null)
  const [txns, setTxns]         = useState<any[]>([])
  const [loading, setLoading]   = useState(true)

  useEffect(() => {
    Promise.all([
      api.get('/admin/stats'),
      api.get('/admin/bookings?status=completed&limit=50'),
    ]).then(([s, b]) => {
      setStats(s.data.data)
      setTxns(b.data.data?.bookings || [])
    }).finally(() => setLoading(false))
  }, [])

  // Compute monthly revenue from completed bookings
  const monthlyRevs = Array(12).fill(0)
  txns.forEach(b => {
    const m = new Date(b.scheduledAt).getMonth()
    monthlyRevs[m] += b.totalPrice || 0
  })
  const maxM = Math.max(...monthlyRevs, 1)
  const curMonth = new Date().getMonth()

  // Top shops by revenue
  const shopRevs: Record<string, {name:string; rev:number}> = {}
  txns.forEach(b => {
    const id = b.shop?.id || 'unknown'
    if (!shopRevs[id]) shopRevs[id] = { name: b.shop?.shopName || '—', rev: 0 }
    shopRevs[id].rev += b.totalPrice || 0
  })
  const topShops = Object.values(shopRevs).sort((a,b) => b.rev - a.rev).slice(0, 6)
  const maxRev = topShops[0]?.rev || 1

  const totalRevenue = txns.reduce((s, b) => s + (b.totalPrice || 0), 0)

  return (
    <AdminShell title="Moliya">
      <div className="fade-in">
        <div className="g3" style={{marginBottom:18}}>
          {[
            {l:'Tasdiqlangan buyurtmalar',v: loading ? '…' : String(stats?.bookings ?? 0),         c:'var(--gold)'},
            {l:'Faol servislar',          v: loading ? '…' : String(stats?.active_shops ?? 0),      c:'var(--blue)'},
            {l:'Jami tushum (tugadi)',     v: loading ? '…' : `${fmt(totalRevenue)} so'm`,           c:'var(--green)'},
          ].map((s,i) => (
            <div key={i} className="kpi">
              <div style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',marginBottom:12}}>{s.l}</div>
              <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:18,fontWeight:700,marginBottom:8,color:'var(--txt)'}}>{s.v}</div>
              <span style={{fontSize:12.5,fontWeight:600,color:s.c}}>Haqiqiy ma'lumot</span>
            </div>
          ))}
        </div>

        <div className="g2" style={{marginBottom:18}}>
          <div className="card">
            <div style={{fontSize:15,fontWeight:700,marginBottom:18,color:'var(--txt)'}}>Oylik buyurtmalar tushumi</div>
            <div style={{display:'flex',alignItems:'stretch',gap:5,height:96,marginBottom:8}}>
              {monthlyRevs.map((r,i) => (
                <div key={i} className="cbar-wrap" style={{height:96}}>
                  <div style={{flex:1,display:'flex',alignItems:'flex-end',width:'100%'}}>
                    <div className="cbar" style={{height:`${r > 0 ? Math.max(4, Math.round((r/maxM)*100)) : 2}%`,background:i===curMonth?'var(--inv)':'var(--surf2)'}}/>
                  </div>
                  <span style={{fontSize:9.5,color:i===curMonth?'var(--txt)':'var(--txt3)',fontWeight:700}}>{MN[i]}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="card">
            <div style={{fontSize:15,fontWeight:700,marginBottom:14,color:'var(--txt)'}}>
              {topShops.length > 0 ? `Top ${topShops.length} servis (tushum)` : 'Servislar topilmadi'}
            </div>
            {topShops.length === 0 ? (
              <div style={{color:'var(--txt3)',fontSize:13}}>Tugallangan buyurtmalar yo'q</div>
            ) : (
              <div style={{display:'flex',flexDirection:'column',gap:11}}>
                {topShops.map((s,i) => (
                  <div key={i}>
                    <div style={{display:'flex',justifyContent:'space-between',marginBottom:5}}>
                      <span style={{fontSize:13,fontWeight:500,flex:1,marginRight:8,whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis',color:'var(--txt)'}}>{s.name}</span>
                      <span style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12.5,fontWeight:600,flexShrink:0,color:'var(--txt)'}}>{fmt(s.rev)}</span>
                    </div>
                    <div className="rbar"><div className="rbar-f" style={{width:`${(s.rev/maxRev)*100}%`,background:i===0?'var(--inv)':'var(--surf3)'}}/></div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="card" style={{padding:0,overflow:'hidden'}}>
          <div style={{padding:'14px 20px',borderBottom:'1px solid var(--hair)'}}>
            <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>So'nggi tugallangan buyurtmalar</span>
          </div>
          <table className="tbl">
            <thead><tr><th>Mijoz</th><th>Servis</th><th>Xizmat</th><th>Sana</th><th>Summa</th><th>Komissiya (30%)</th><th>Holat</th></tr></thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={7} style={{textAlign:'center',padding:24,color:'var(--txt3)'}}>Yuklanmoqda…</td></tr>
              ) : txns.length === 0 ? (
                <tr><td colSpan={7} style={{textAlign:'center',padding:24,color:'var(--txt3)'}}>Tugallangan buyurtmalar yo'q</td></tr>
              ) : txns.map(b => (
                <tr key={b.id}>
                  <td style={{fontWeight:600,color:'var(--txt)'}}>{b.customer?.fullName || '—'}</td>
                  <td style={{color:'var(--txt2)'}}>{b.shop?.shopName || '—'}</td>
                  <td style={{color:'var(--txt2)'}}>{b.serviceType?.nameUz || '—'}</td>
                  <td style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12.5,color:'var(--txt)'}}>{fmtDate(b.scheduledAt)}</td>
                  <td><span style={{fontFamily:"'JetBrains Mono',monospace",fontWeight:600,color:'var(--txt)'}}>{fmt(b.totalPrice)}</span></td>
                  <td style={{color:'var(--green)',fontFamily:"'JetBrains Mono',monospace",fontWeight:600}}>+{fmt(Math.round(b.totalPrice * 0.3))}</td>
                  <td><span className="badge b-green">Tugadi</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </AdminShell>
  )
}
