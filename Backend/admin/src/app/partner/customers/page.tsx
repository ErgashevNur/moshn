'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import Toggle from '@/components/ui/Toggle'
import partnerApi from '@/lib/partnerApi'

function fmt(n: number) { return n.toLocaleString('ru-RU') }
function fmtDate(d?: string | null) {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('ru', { day:'2-digit', month:'2-digit', year:'numeric' })
}

function CustomerDetail({ sel, onClose, onToggleVip, isMobile }: {
  sel: any
  onClose: () => void
  onToggleVip: (card: any) => void
  isMobile?: boolean
}) {
  if (!sel) return null
  const name  = sel.customer?.fullName || 'Неизвестно'
  const phone = sel.customer?.phone || ''

  return (
    <>
      {isMobile && <div className="bsheet-handle"/>}
      <div style={{padding:'14px 20px 12px',borderBottom:'1px solid var(--hair)',flexShrink:0,display:'flex',alignItems:'center',justifyContent:'space-between'}}>
        <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>Профиль клиента</span>
        <button onClick={onClose} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer',padding:4}}><Icon n="x" s={20}/></button>
      </div>
      <div style={{flex:1,overflowY:'auto',padding:'16px 20px 20px'}}>
        <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:20}}>
          <div style={{width:54,height:54,borderRadius:'50%',background:'var(--surf2)',display:'grid',placeItems:'center',fontSize:20,fontWeight:700,color:'var(--txt2)',flexShrink:0}}>{name[0]}</div>
          <div style={{flex:1,minWidth:0}}>
            <div style={{display:'flex',alignItems:'center',gap:8,flexWrap:'wrap'}}>
              <span style={{fontSize:17,fontWeight:700,color:'var(--txt)'}}>{name}</span>
              {sel.isVip && <span className="vip"><Icon n="crown" s={11}/>VIP</span>}
            </div>
            <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12.5,color:'var(--txt2)',marginTop:2}}>{phone}</div>
          </div>
        </div>
        <div className="lcard" style={{marginBottom:16}}>
          {[
            ['Посещения',           `${sel.visitCount}`],
            ['Последнее посещение', fmtDate(sel.lastVisitAt)],
            ['VIP статус',          sel.isVip ? 'Да' : 'Нет'],
            ['Заметки',             sel.notes || '—'],
          ].map(([l,v],i) => (
            <div key={i} className="lrow">
              <span style={{fontSize:12.5,color:'var(--txt3)',flex:1}}>{l}</span>
              <span style={{fontSize:13.5,fontWeight:600,color:'var(--txt)'}}>{v}</span>
            </div>
          ))}
        </div>
        <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',padding:'12px 15px',borderRadius:12,background:'var(--surf2)',marginBottom:12}}>
          <span style={{fontSize:14,fontWeight:600,color:'var(--txt)'}}>VIP клиент</span>
          <Toggle on={sel.isVip} onChange={() => onToggleVip(sel)}/>
        </div>
        {/* Phone call — tel: link */}
        <a href={phone ? `tel:${phone}` : undefined}
          style={{
            display:'flex', alignItems:'center', justifyContent:'center', gap:8,
            width:'100%', height:44, borderRadius:999,
            background:'var(--surf2)', color:'var(--txt)',
            fontSize:14, fontWeight:600,
            textDecoration:'none',
            opacity: phone ? 1 : 0.4,
            pointerEvents: phone ? 'auto' : 'none',
          }}>
          <Icon n="phone" s={18}/>Позвонить клиенту
        </a>
      </div>
    </>
  )
}

export default function PartnerCustomersPage() {
  const router  = useRouter()
  const [cards, setCards]       = useState<any[]>([])
  const [loading, setLoading]   = useState(true)
  const [sel, setSel]           = useState<any>(null)
  const [q, setQ]               = useState('')
  const [toggling, setToggling] = useState('')
  const [isMobile, setIsMobile] = useState(false)
  const [pendingCount, setPendingCount] = useState(0)

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  const load = useCallback(() => {
    setLoading(true)
    partnerApi.get('/service/customers?limit=100').then(r => {
      setCards(r.data.data?.customers || [])
    }).catch(() => {}).finally(() => setLoading(false))
  }, [])

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    load()
    partnerApi.get('/service/bookings?status=pending&limit=1').then(r => {
      setPendingCount(r.data.data?.total || 0)
    }).catch(() => {})
  }, [router, load])

  const toggleVip = async (card: any) => {
    setToggling(card.id)
    try {
      const updated = await partnerApi.put(`/service/customers/${card.customerId}`, { is_vip: !card.isVip })
      const newVip = updated.data.data?.isVip ?? !card.isVip
      setCards(cs => cs.map(c => c.id === card.id ? { ...c, isVip: newVip } : c))
      if (sel?.id === card.id) setSel((s: any) => ({ ...s, isVip: newVip }))
    } finally { setToggling('') }
  }

  const list = cards.filter(c =>
    !q ||
    (c.customer?.fullName || '').toLowerCase().includes(q.toLowerCase()) ||
    (c.customer?.phone || '').includes(q)
  )

  return (
    <PartnerShell pendingCount={pendingCount}>
      {/* ── Main list ──────────────────────────────────────────────────────── */}
      <div style={{flex:1,display:'flex',flexDirection:'column',minWidth:0,overflow:'hidden'}}>
        <div style={{height:60,display:'flex',alignItems:'center',padding:'0 18px',borderBottom:'1px solid var(--hair)',flexShrink:0,background:'var(--bgE)'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:10,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)'}}>SHINA24 PARTNER</div>
            <div style={{fontSize:16,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)'}}>База клиентов</div>
          </div>
        </div>

        <div style={{flex:1,overflowY:'auto',padding: isMobile ? '14px' : '20px 22px'}}>
          <div className="fade-in">
            <div className="srch" style={{marginBottom:14}}>
              <Icon n="search" s={17} col="var(--txt3)"/>
              <input value={q} onChange={e => setQ(e.target.value)} placeholder="Имя клиента или телефон…"
                style={{border:'none',background:'none',fontSize:14,color:'var(--txt)',outline:'none',flex:1,fontFamily:'inherit'}}/>
              {q && <button onClick={() => setQ('')} style={{color:'var(--txt3)',background:'none',border:'none',cursor:'pointer'}}><Icon n="x" s={16}/></button>}
            </div>

            {loading ? (
              <div style={{textAlign:'center',padding:'60px 0',color:'var(--txt3)'}}>Загрузка…</div>
            ) : (
              <>
                <div className="slbl">{list.length} клиентов</div>
                <div style={{display:'flex',flexDirection:'column',gap:2}}>
                  {list.map(c => {
                    const name  = c.customer?.fullName || 'Неизвестно'
                    const phone = c.customer?.phone || ''
                    const totalSpend = c.totalSpend || 0
                    const isSelected = sel?.id === c.id
                    return (
                      <div key={c.id} onClick={() => setSel(isSelected ? null : c)}
                        style={{display:'flex',alignItems:'center',gap:12,padding:'11px 12px',borderRadius:12,cursor:'pointer',transition:'background .12s',background:isSelected?'var(--surf)':'none'}}>
                        <div style={{width:42,height:42,borderRadius:'50%',background:'var(--surf2)',display:'grid',placeItems:'center',fontSize:16,fontWeight:700,color:'var(--txt2)',flexShrink:0}}>{name[0]}</div>
                        <div style={{flex:1,minWidth:0}}>
                          <div style={{display:'flex',alignItems:'center',gap:6,flexWrap:'wrap'}}>
                            <span style={{fontSize:14,fontWeight:600,color:'var(--txt)'}}>{name}</span>
                            {c.isVip && <span className="vip"><Icon n="crown" s={11}/>VIP</span>}
                          </div>
                          <div style={{fontSize:12,color:'var(--txt3)',fontFamily:"'JetBrains Mono',monospace",marginTop:1}}>{phone}</div>
                        </div>
                        <div style={{textAlign:'right',flexShrink:0}}>
                          {totalSpend > 0 && (
                            <div style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12.5,fontWeight:700,color:'var(--txt)'}}>{fmt(totalSpend)}</div>
                          )}
                          <div style={{fontSize:11,color:'var(--txt3)'}}>{c.visitCount} посещ.</div>
                        </div>
                        <div onClick={e => e.stopPropagation()}>
                          <Toggle on={c.isVip} onChange={() => toggleVip(c)}/>
                        </div>
                      </div>
                    )
                  })}
                  {list.length === 0 && (
                    <div style={{textAlign:'center',padding:'40px 0',color:'var(--txt3)'}}>
                      <Icon n="users" s={40}/>
                      <p style={{marginTop:12,fontSize:13}}>{q ? 'Не найдено' : 'Нет клиентов'}</p>
                    </div>
                  )}
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* ── Desktop side panel ─────────────────────────────────────────────── */}
      {!isMobile && (
        <div style={{width:320,background:'var(--bgE)',borderLeft:'1px solid var(--hair)',display:'flex',flexDirection:'column',flexShrink:0,overflow:'hidden'}}>
          {sel ? (
            <CustomerDetail sel={sel} onClose={() => setSel(null)} onToggleVip={toggleVip}/>
          ) : (
            <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',color:'var(--txt3)',gap:12,padding:24,textAlign:'center'}}>
              <Icon n="users" s={42}/>
              <p style={{fontSize:13,marginTop:4,lineHeight:1.4}}>Выберите клиента</p>
            </div>
          )}
        </div>
      )}

      {/* ── Mobile bottom sheet ────────────────────────────────────────────── */}
      {isMobile && sel && (
        <>
          <div className="bsheet-backdrop" onClick={() => setSel(null)}/>
          <div className="bsheet" style={{bottom:64}}>
            <CustomerDetail sel={sel} onClose={() => setSel(null)} onToggleVip={toggleVip} isMobile/>
          </div>
        </>
      )}
    </PartnerShell>
  )
}
