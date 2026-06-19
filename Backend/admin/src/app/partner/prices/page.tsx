'use client'
import { useEffect, useState, useCallback } from 'react'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import partnerApi from '@/lib/partnerApi'

interface ServiceType {
  id: string
  slug: string
  nameUz: string
  nameRu: string
}

interface PriceRow {
  serviceTypeId: string
  nameRu: string
  priceMin: string
  priceMax: string
  currency: string
  saved: boolean
}

const CURRENCIES = [
  { code: 'UZS', symbol: 'сўм', flag: '🇺🇿', placeholder: ['15 000', '40 000'] },
  { code: 'USD', symbol: '$',   flag: '🇺🇸', placeholder: ['5',      '20']     },
  { code: 'EUR', symbol: '€',   flag: '🇪🇺', placeholder: ['5',      '18']     },
  { code: 'RUB', symbol: '₽',   flag: '🇷🇺', placeholder: ['500',    '2 000']  },
  { code: 'GBP', symbol: '£',   flag: '🇬🇧', placeholder: ['4',      '15']     },
  { code: 'KZT', symbol: '₸',   flag: '🇰🇿', placeholder: ['2 500',  '9 000']  },
]

function getCur(code: string) {
  return CURRENCIES.find(c => c.code === code) ?? CURRENCIES[0]
}

function fmtNum(val: string, code: string) {
  const n = parseInt(val.replace(/\D/g, ''))
  if (isNaN(n)) return ''
  return code === 'UZS' || code === 'KZT' ? n.toLocaleString('ru') : String(n)
}

function parseNum(val: string) {
  return val.replace(/\D/g, '')
}

function priceLabel(row: PriceRow) {
  const cur  = getCur(row.currency)
  const fmt  = (v: string) => v.replace(/\B(?=(\d{3})+(?!\d))/g, ' ')
  const mn   = row.priceMin
  const mx   = row.priceMax
  if (mn && mx) return `${fmt(mn)} – ${fmt(mx)} ${cur.symbol}`
  if (mn)       return `от ${fmt(mn)} ${cur.symbol}`
  if (mx)       return `до ${fmt(mx)} ${cur.symbol}`
  return ''
}

export default function PricesPage() {
  const [rows, setRows]       = useState<PriceRow[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving]   = useState(false)
  const [saved, setSaved]     = useState(false)
  const [err, setErr]         = useState('')
  const [isMobile, setIsMobile] = useState(false)

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [typesRes, pricesRes] = await Promise.all([
        partnerApi.get('/service-types'),
        partnerApi.get('/service/prices'),
      ])
      const types: ServiceType[] = typesRes.data.data || []
      const existing: any[]      = pricesRes.data.data || []

      setRows(types.map(t => {
        const ex = existing.find((p: any) =>
          (p.serviceTypeId ?? p.service_type_id) === t.id
        )
        const mn  = ex ? (ex.priceMin ?? ex.price_min ?? 0) : 0
        const mx  = ex ? (ex.priceMax ?? ex.price_max ?? 0) : 0
        const cur = ex?.currency ?? 'UZS'
        return {
          serviceTypeId: t.id,
          nameRu:   t.nameRu || t.nameUz,
          priceMin: mn > 0 ? String(mn) : '',
          priceMax: mx > 0 ? String(mx) : '',
          currency: cur,
          saved:    mn > 0 || mx > 0,
        }
      }))
    } catch {
      setErr('Не удалось загрузить данные')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const update = (id: string, field: keyof PriceRow, val: string) => {
    setSaved(false); setErr('')
    setRows(prev => prev.map(r =>
      r.serviceTypeId === id ? { ...r, [field]: val } : r
    ))
  }

  const handleSave = async () => {
    setErr(''); setSaved(false)
    const filled = rows.filter(r => r.priceMin || r.priceMax)
    if (!filled.length) {
      setErr('Укажите цену хотя бы для одной услуги')
      return
    }
    for (const r of filled) {
      const mn = Number(r.priceMin || 0)
      const mx = Number(r.priceMax || 0)
      if (mn > 0 && mx > 0 && mn > mx) {
        setErr(`«${r.nameRu}» — минимальная цена не должна превышать максимальную`)
        return
      }
    }
    setSaving(true)
    try {
      await partnerApi.put('/service/prices', {
        prices: filled.map(r => ({
          serviceTypeId: r.serviceTypeId,
          priceMin:  Number(r.priceMin  || 0),
          priceMax:  Number(r.priceMax  || 0),
          currency:  r.currency,
        }))
      })
      setSaved(true)
      setRows(prev => prev.map(r => ({
        ...r,
        saved: !!(r.priceMin || r.priceMax),
      })))
    } catch (e: any) {
      setErr(e.response?.data?.message || 'Ошибка при сохранении')
    } finally {
      setSaving(false)
    }
  }

  const filledCount = rows.filter(r => r.priceMin || r.priceMax).length

  return (
    <PartnerShell>
      <div style={{ flex:1, display:'flex', flexDirection:'column', minWidth:0, overflow:'hidden' }}>

        {/* ── Шапка ── */}
        <div style={{
          height:60, display:'flex', alignItems:'center',
          padding: isMobile ? '0 14px' : '0 22px', borderBottom:'1px solid var(--hair)',
          flexShrink:0, background:'var(--bgE)',
          justifyContent:'space-between', gap: isMobile ? 8 : 12,
        }}>
          <div style={{ minWidth:0 }}>
            <div style={{ fontSize:10.5, fontWeight:700, textTransform:'uppercase', letterSpacing:'.08em', color:'var(--txt3)' }}>
              SHINA24 PARTNER
            </div>
            <div style={{ fontSize: isMobile ? 14.5 : 16, fontWeight:700, letterSpacing:'-.02em', color:'var(--txt)', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>
              Цены на услуги
            </div>
          </div>

          <button
            onClick={handleSave}
            disabled={saving || loading}
            style={{
              height:36, padding: isMobile ? '0 13px' : '0 18px', borderRadius:999,
              background: saved ? 'var(--greenDim)' : 'var(--inv)',
              color:      saved ? 'var(--green)'    : 'var(--invT)',
              fontSize: isMobile ? 12.5 : 13, fontWeight:700, border:'none',
              cursor: saving || loading ? 'not-allowed' : 'pointer',
              opacity: saving || loading ? 0.6 : 1,
              display:'flex', alignItems:'center', gap:6,
              transition:'all .2s', flexShrink:0, whiteSpace:'nowrap',
            }}>
            {saving
              ? '…'
              : saved
              ? <><Icon n="check" s={14} col="var(--green)"/>Сохранено</>
              : <><Icon n="check" s={14}/>Сохранить{filledCount > 0 ? ` (${filledCount})` : ''}</>
            }
          </button>
        </div>

        {/* ── Прокручиваемое тело ── */}
        <div style={{ flex:1, overflowY:'auto', padding: isMobile ? '14px' : '20px 22px' }}>
          {loading ? (
            <div style={{ textAlign:'center', padding:'60px 0', color:'var(--txt3)' }}>
              Загрузка…
            </div>
          ) : (
            <div className="fade-in">

              {/* Информационный баннер */}
              <div style={{
                background:'var(--blueDim)', border:'1px solid var(--blue)',
                borderRadius:12, padding: isMobile ? '11px 13px' : '12px 16px', marginBottom: isMobile ? 14 : 20,
                display:'flex', alignItems:'flex-start', gap:10,
              }}>
                <Icon n="bolt" s={16} col="var(--blue)" style={{ flexShrink:0, marginTop:1 }}/>
                <p style={{ fontSize: isMobile ? 12.5 : 13, color:'var(--blue)', margin:0, lineHeight:1.55 }}>
                  Цена зависит от размера шин. Укажите диапазон и выберите валюту для каждой услуги —
                  клиенты увидят это в приложении.
                </p>
              </div>

              {isMobile ? (
                /* ── Мобильный список карточек (без горизонтального скролла) ── */
                <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
                  {rows.map(row => {
                    const hasMn  = !!row.priceMin
                    const hasMx  = !!row.priceMax
                    const active = hasMn || hasMx
                    const cur    = getCur(row.currency)
                    const label  = priceLabel(row)

                    return (
                      <div key={row.serviceTypeId} style={{
                        background: active ? 'var(--surf)' : 'var(--bgE)',
                        border:`1.5px solid ${active ? 'var(--blue)' : 'var(--hair)'}`,
                        borderRadius:14, padding:13,
                        transition:'border-color .2s, background .2s',
                      }}>
                        {/* Услуга */}
                        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
                          <div style={{
                            width:32, height:32, borderRadius:9, flexShrink:0,
                            background: active ? 'var(--blueDim)' : 'var(--surf2)',
                            display:'grid', placeItems:'center',
                            color: active ? 'var(--blue)' : 'var(--txt3)',
                            transition:'all .2s',
                          }}>
                            <Icon n="disc" s={15}/>
                          </div>
                          <div style={{ minWidth:0, flex:1 }}>
                            <div style={{ fontSize:14, fontWeight:700, color:'var(--txt)', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>
                              {row.nameRu}
                            </div>
                            {active && label && (
                              <div style={{ fontSize:11.5, fontWeight:700, color:'var(--blue)', marginTop:2, whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>
                                {label}
                              </div>
                            )}
                          </div>
                        </div>

                        {/* Цены */}
                        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:9, marginBottom:9 }}>
                          <div>
                            <label style={{ display:'block', fontSize:10, fontWeight:700, textTransform:'uppercase', letterSpacing:'.05em', color:'var(--txt3)', marginBottom:5 }}>
                              Мин. цена
                            </label>
                            <input
                              type="text" inputMode="numeric"
                              placeholder={cur.placeholder[0]}
                              value={row.priceMin ? fmtNum(row.priceMin, row.currency) : ''}
                              onChange={e => update(row.serviceTypeId, 'priceMin', parseNum(e.target.value))}
                              style={{
                                width:'100%', boxSizing:'border-box',
                                padding:'9px 8px', borderRadius:10, textAlign:'center',
                                border:`1.5px solid ${hasMn ? 'var(--blue)' : 'var(--hair)'}`,
                                background:'var(--surf2)', color:'var(--txt)',
                                fontSize:13.5, outline:'none', fontFamily:'inherit',
                                transition:'border-color .15s',
                              }}
                            />
                          </div>
                          <div>
                            <label style={{ display:'block', fontSize:10, fontWeight:700, textTransform:'uppercase', letterSpacing:'.05em', color:'var(--txt3)', marginBottom:5 }}>
                              Макс. цена
                            </label>
                            <input
                              type="text" inputMode="numeric"
                              placeholder={cur.placeholder[1]}
                              value={row.priceMax ? fmtNum(row.priceMax, row.currency) : ''}
                              onChange={e => update(row.serviceTypeId, 'priceMax', parseNum(e.target.value))}
                              style={{
                                width:'100%', boxSizing:'border-box',
                                padding:'9px 8px', borderRadius:10, textAlign:'center',
                                border:`1.5px solid ${hasMx ? 'var(--blue)' : 'var(--hair)'}`,
                                background:'var(--surf2)', color:'var(--txt)',
                                fontSize:13.5, outline:'none', fontFamily:'inherit',
                                transition:'border-color .15s',
                              }}
                            />
                          </div>
                        </div>

                        {/* Валюта — select на всю ширину */}
                        <div style={{ position:'relative' }}>
                          <select
                            value={row.currency}
                            onChange={e => update(row.serviceTypeId, 'currency', e.target.value)}
                            style={{
                              width:'100%', appearance:'none', WebkitAppearance:'none',
                              padding:'9px 30px 9px 12px', borderRadius:10,
                              border:`1.5px solid ${active ? 'var(--blue)' : 'var(--hair)'}`,
                              background:'var(--surf2)', color:'var(--txt)',
                              fontSize:13, fontWeight:600, outline:'none',
                              cursor:'pointer', transition:'border-color .15s',
                            }}>
                            {CURRENCIES.map(c => (
                              <option key={c.code} value={c.code}>
                                {c.flag} {c.code} — {c.symbol}
                              </option>
                            ))}
                          </select>
                          <div style={{
                            position:'absolute', right:11, top:'50%',
                            transform:'translateY(-50%)', pointerEvents:'none',
                            color:'var(--txt3)', fontSize:10,
                          }}>▼</div>
                        </div>
                      </div>
                    )
                  })}
                </div>
              ) : (
                /* ── Таблица цен (десктоп) ── */
                <div style={{
                  background:'var(--bgE)', borderRadius:14,
                  border:'1px solid var(--hair)', overflow:'hidden',
                }}>
                  {/* Заголовок */}
                  <div style={{
                    display:'grid',
                    gridTemplateColumns:'1fr 140px 140px 108px',
                    padding:'10px 18px', background:'var(--surf2)',
                    borderBottom:'1px solid var(--hair)', gap:10,
                  }}>
                    {['Услуга', 'Мин. цена', 'Макс. цена', 'Валюта'].map(h => (
                      <span key={h} style={{
                        fontSize:11.5, fontWeight:700, color:'var(--txt3)',
                        textTransform:'uppercase', letterSpacing:'.06em',
                        textAlign: h === 'Услуга' ? 'left' : 'center',
                      }}>{h}</span>
                    ))}
                  </div>

                  {/* Строки */}
                  {rows.map((row, i) => {
                    const isLast = i === rows.length - 1
                    const hasMn  = !!row.priceMin
                    const hasMx  = !!row.priceMax
                    const active = hasMn || hasMx
                    const cur    = getCur(row.currency)
                    const label  = priceLabel(row)

                    return (
                      <div key={row.serviceTypeId} style={{
                        display:'grid',
                        gridTemplateColumns:'1fr 140px 140px 108px',
                        padding:'12px 18px', alignItems:'center',
                        borderBottom: isLast ? 'none' : '1px solid var(--hair)',
                        background: active ? 'var(--surf)' : 'transparent',
                        transition:'background .2s', gap:10,
                      }}>

                        {/* Услуга */}
                        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
                          <div style={{
                            width:34, height:34, borderRadius:9, flexShrink:0,
                            background: active ? 'var(--blueDim)' : 'var(--surf2)',
                            display:'grid', placeItems:'center',
                            color: active ? 'var(--blue)' : 'var(--txt3)',
                            transition:'all .2s',
                          }}>
                            <Icon n="disc" s={16}/>
                          </div>
                          <div style={{ minWidth:0 }}>
                            <div style={{ fontSize:14, fontWeight:600, color:'var(--txt)', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis' }}>
                              {row.nameRu}
                            </div>
                            {active && label && (
                              <div style={{ fontSize:11.5, fontWeight:700, color:'var(--blue)', marginTop:2 }}>
                                {label}
                              </div>
                            )}
                          </div>
                        </div>

                        {/* Мин */}
                        <input
                          type="text" inputMode="numeric"
                          placeholder={cur.placeholder[0]}
                          value={row.priceMin ? fmtNum(row.priceMin, row.currency) : ''}
                          onChange={e => update(row.serviceTypeId, 'priceMin', parseNum(e.target.value))}
                          style={{
                            width:'100%', boxSizing:'border-box',
                            padding:'8px 10px', borderRadius:9, textAlign:'center',
                            border:`1.5px solid ${hasMn ? 'var(--blue)' : 'var(--hair)'}`,
                            background:'var(--surf2)', color:'var(--txt)',
                            fontSize:13, outline:'none', fontFamily:'inherit',
                            transition:'border-color .15s',
                          }}
                        />

                        {/* Макс */}
                        <input
                          type="text" inputMode="numeric"
                          placeholder={cur.placeholder[1]}
                          value={row.priceMax ? fmtNum(row.priceMax, row.currency) : ''}
                          onChange={e => update(row.serviceTypeId, 'priceMax', parseNum(e.target.value))}
                          style={{
                            width:'100%', boxSizing:'border-box',
                            padding:'8px 10px', borderRadius:9, textAlign:'center',
                            border:`1.5px solid ${hasMx ? 'var(--blue)' : 'var(--hair)'}`,
                            background:'var(--surf2)', color:'var(--txt)',
                            fontSize:13, outline:'none', fontFamily:'inherit',
                            transition:'border-color .15s',
                          }}
                        />

                        {/* Валюта — select */}
                        <div style={{ position:'relative' }}>
                          <select
                            value={row.currency}
                            onChange={e => update(row.serviceTypeId, 'currency', e.target.value)}
                            style={{
                              width:'100%', appearance:'none', WebkitAppearance:'none',
                              padding:'8px 28px 8px 10px', borderRadius:9, textAlign:'center',
                              border:`1.5px solid ${active ? 'var(--blue)' : 'var(--hair)'}`,
                              background:'var(--surf2)', color:'var(--txt)',
                              fontSize:13, fontWeight:600, outline:'none',
                              cursor:'pointer', transition:'border-color .15s',
                            }}>
                            {CURRENCIES.map(c => (
                              <option key={c.code} value={c.code}>
                                {c.flag} {c.code}
                              </option>
                            ))}
                          </select>
                          {/* Стрелка вниз */}
                          <div style={{
                            position:'absolute', right:8, top:'50%',
                            transform:'translateY(-50%)', pointerEvents:'none',
                            color:'var(--txt3)', fontSize:10,
                          }}>▼</div>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}

              {/* Ошибка */}
              {err && (
                <div style={{
                  marginTop:14, padding:'10px 14px', borderRadius:10,
                  background:'var(--redDim)', color:'var(--red)',
                  fontSize:13, fontWeight:500,
                }}>
                  {err}
                </div>
              )}

              <div style={{ height:16 }}/>
            </div>
          )}
        </div>
      </div>
    </PartnerShell>
  )
}
