'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import Plate from '@/components/ui/Plate'
import partnerApi from '@/lib/partnerApi'

type Step = 'select' | 'nfc' | 'qr' | 'done'

function fmt(n: number) { return n.toLocaleString('uz') }
function fmtTime(d: string) {
  return new Date(d).toLocaleTimeString('uz', { hour:'2-digit', minute:'2-digit' })
}

export default function PartnerTerminalPage() {
  const router  = useRouter()
  const [step, setStep]       = useState<Step>('select')
  const [selB, setSelB]       = useState<any>(null)
  const [bookings, setBookings] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [paying, setPaying]   = useState(false)
  const [pendingCount, setPendingCount] = useState(0)

  const load = useCallback(() => {
    setLoading(true)
    Promise.all([
      partnerApi.get('/service/bookings?limit=50'),
      partnerApi.get('/service/bookings?status=pending&limit=1'),
    ]).then(([r, pR]) => {
      const all = r.data.data?.bookings || []
      const unpaid = all.filter((b: any) =>
        b.payment?.status !== 'paid' && b.status !== 'cancelled'
      )
      setBookings(unpaid)
      setPendingCount(pR.data.data?.total || 0)
    }).catch(() => {}).finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    load()
  }, [router, load])

  const pay = async (method: string) => {
    if (!selB) return
    setPaying(true)
    try {
      await partnerApi.post(`/payments/${selB.id}/pay`, { method })
      setStep('done')
    } catch {
      alert("To'lovda xatolik. Qayta urinib ko'ring.")
    } finally { setPaying(false) }
  }

  const getQr = async () => {
    if (!selB) return
    try {
      await partnerApi.post(`/payments/${selB.id}/qr`)
    } catch {}
    setStep('qr')
  }

  if (step === 'done') return (
    <PartnerShell pendingCount={pendingCount}>
      <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',textAlign:'center',padding:28}}>
        <div style={{position:'relative',display:'grid',placeItems:'center',marginBottom:24}}>
          <div style={{position:'absolute',width:120,height:120,borderRadius:'50%',background:'var(--greenDim)',animation:'pop-in .5s ease both'}}/>
          <div style={{width:90,height:90,borderRadius:'50%',background:'var(--green)',display:'grid',placeItems:'center',color:'#fff',position:'relative'}}>
            <Icon n="check" s={44} st={2.5}/>
          </div>
        </div>
        <div style={{fontSize:24,fontWeight:700,marginBottom:8,color:'var(--txt)'}}>To&apos;lov qabul qilindi!</div>
        {selB && <div style={{fontSize:16,color:'var(--txt2)',marginBottom:4}}>{selB.customer?.fullName || '—'}</div>}
        {selB && <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:26,fontWeight:700,color:'var(--green)',marginBottom:32}}>{fmt(selB.totalPrice || 0)} so&apos;m</div>}
        <button onClick={() => { setStep('select'); setSelB(null); load() }}
          style={{height:48,padding:'0 28px',borderRadius:999,background:'var(--surf2)',color:'var(--txt)',fontSize:15,fontWeight:600,cursor:'pointer',border:'none'}}>Yangi to&apos;lov</button>
      </div>
    </PartnerShell>
  )

  if (step === 'nfc') return (
    <PartnerShell pendingCount={pendingCount}>
      <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',textAlign:'center',padding:28}}>
        <div style={{position:'relative',display:'grid',placeItems:'center',marginBottom:32}}>
          {[0,1,2].map(i => <div key={i} style={{position:'absolute',width:180+i*60,height:180+i*60,borderRadius:'50%',border:'2px solid rgba(48,209,88,.3)',animation:`pulse-ring 2.4s ease-out infinite ${i*.8}s`}}/>)}
          <div style={{width:156,height:156,borderRadius:'50%',border:'2.5px solid var(--green)',display:'grid',placeItems:'center',position:'relative',zIndex:1}}>
            <Icon n="nfc" s={62} col="var(--green)" st={1.4}/>
          </div>
        </div>
        <div style={{fontSize:22,fontWeight:700,marginBottom:8,color:'var(--txt)'}}>Kartani yaqinlashtiring</div>
        <div style={{fontSize:14,color:'var(--txt2)',marginBottom:4}}>NFC · Contactless to'lov</div>
        {selB && <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:28,fontWeight:700,color:'var(--green)',margin:'12px 0 28px'}}>{fmt(selB.totalPrice || 0)} so'm</div>}
        <div style={{display:'flex',gap:12}}>
          <button onClick={() => setStep('select')} style={{height:46,padding:'0 20px',borderRadius:999,border:'1px solid var(--hair2)',color:'var(--txt2)',fontSize:14,fontWeight:600,cursor:'pointer',background:'none'}}>Orqaga</button>
          <button onClick={getQr} style={{height:46,padding:'0 20px',borderRadius:999,background:'var(--surf2)',color:'var(--txt)',fontSize:14,fontWeight:600,cursor:'pointer',display:'flex',alignItems:'center',gap:8,border:'none'}}><Icon n="qr" s={18}/>QR kod</button>
          <button disabled={paying} onClick={() => pay('card_nfc')} style={{height:46,padding:'0 20px',borderRadius:999,background:'var(--green)',color:'#fff',fontSize:14,fontWeight:600,cursor:'pointer',border:'none',opacity:paying?0.6:1}}>
            {paying ? '…' : 'Tasdiqlash ✓'}
          </button>
        </div>
      </div>
    </PartnerShell>
  )

  if (step === 'qr') return (
    <PartnerShell pendingCount={pendingCount}>
      <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',textAlign:'center',padding:28}}>
        <div style={{width:196,height:196,background:'#fff',borderRadius:16,display:'grid',placeItems:'center',padding:14,marginBottom:20}}>
          <svg viewBox="0 0 100 100" width="168" height="168">
            {Array.from({length:7},(_,r) => Array.from({length:7},(_,c) => {
              const v = Math.sin(r*7+c*3+r*c) > .15
              return <rect key={`${r}-${c}`} x={r*14+1} y={c*14+1} width={11} height={11} rx={2} fill={v?'#111':'none'}/>
            }))}
          </svg>
        </div>
        <div style={{fontSize:20,fontWeight:700,marginBottom:6,color:'var(--txt)'}}>QR kod orqali to'lash</div>
        {selB && <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:26,fontWeight:700,marginBottom:4,color:'var(--txt)'}}>{fmt(selB.totalPrice || 0)} so'm</div>}
        <div style={{fontSize:13,color:'var(--txt3)',marginBottom:28}}>Payme · Click · Uzum Bank</div>
        <div style={{display:'flex',gap:12}}>
          <button onClick={() => setStep('nfc')} style={{height:46,padding:'0 20px',borderRadius:999,border:'1px solid var(--hair2)',color:'var(--txt2)',fontSize:14,fontWeight:600,cursor:'pointer',background:'none'}}>NFC ga o'tish</button>
          <button disabled={paying} onClick={() => pay('card_qr')} style={{height:46,padding:'0 20px',borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:14,fontWeight:600,cursor:'pointer',border:'none',opacity:paying?0.6:1}}>
            {paying ? '…' : 'Tasdiqlash'}
          </button>
        </div>
      </div>
    </PartnerShell>
  )

  return (
    <PartnerShell pendingCount={pendingCount}>
      <div style={{flex:1,display:'flex',flexDirection:'column',minWidth:0,overflow:'hidden'}}>
        <div style={{height:60,display:'flex',alignItems:'center',padding:'0 22px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>SHINA24 PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)'}}>Terminal — To'lov</div>
          </div>
        </div>
        <div style={{flex:1,overflowY:'auto',padding:'20px 22px'}}>
          <div className="fade-in">
            <div className="slbl">Qaysi buyurtma uchun to'lov?</div>

            {loading ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>Yuklanmoqda…</div>
            ) : bookings.length === 0 ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>
                <Icon n="card" s={42}/>
                <p style={{marginTop:14,fontSize:14}}>To'lanmagan buyurtma yo'q</p>
              </div>
            ) : (
              <div style={{display:'flex',flexDirection:'column',gap:10,marginBottom:20}}>
                {bookings.map(b => (
                  <div key={b.id} className="scard" onClick={() => setSelB(b)}
                    style={{cursor:'pointer',borderColor:selB?.id===b.id?'var(--txt3)':'var(--hair)'}}>
                    <div style={{display:'flex',alignItems:'center',gap:12}}>
                      <div style={{width:42,height:42,borderRadius:12,background:'var(--surf2)',display:'grid',placeItems:'center',flexShrink:0}}><Icon n="car" s={22}/></div>
                      <div style={{flex:1}}>
                        <div style={{fontSize:15,fontWeight:600,color:'var(--txt)'}}>{b.customer?.fullName || '—'}</div>
                        <div style={{fontSize:13,color:'var(--txt2)'}}>{b.serviceType?.nameUz || '—'} · {fmtTime(b.scheduledAt)}</div>
                      </div>
                      <div style={{textAlign:'right'}}>
                        <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:17,fontWeight:700,color:'var(--txt)'}}>{fmt(b.totalPrice || 0)}</div>
                        <Plate v={b.vehicle?.plate || '—'}/>
                      </div>
                      <div style={{width:22,height:22,borderRadius:'50%',border:`2px solid ${selB?.id===b.id?'var(--txt)':'var(--hair2)'}`,display:'grid',placeItems:'center',flexShrink:0}}>
                        {selB?.id===b.id && <div style={{width:11,height:11,borderRadius:'50%',background:'var(--txt)'}}/>}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div style={{display:'flex',gap:11}}>
              {[['nfc',"Karta / NFC",'nfc'],['qr','QR kod','qr']] .map(([k,l,ic]) => (
                <button key={k} disabled={!selB} onClick={() => k === 'qr' ? getQr() : setStep('nfc')}
                  style={{flex:1,height:52,borderRadius:999,background:selB?'var(--inv)':'var(--surf2)',color:selB?'var(--invT)':'var(--txt3)',fontSize:15,fontWeight:600,cursor:selB?'pointer':'default',display:'flex',alignItems:'center',justifyContent:'center',gap:9,border:'none'}}>
                  <Icon n={ic as any} s={20}/>{l}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </PartnerShell>
  )
}
