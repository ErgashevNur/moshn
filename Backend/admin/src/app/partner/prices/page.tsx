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
  icon: string
  basePrice: number
}

interface PriceRow {
  serviceTypeId: string
  priceMin: number | ''
  priceMax: number | ''
}

function fmt(n: number) {
  return n.toLocaleString('ru') + ' сум'
}

const inp: React.CSSProperties = {
  width: '100%', boxSizing: 'border-box', padding: '10px 14px',
  borderRadius: 10, border: '1.5px solid var(--hair)',
  background: 'var(--surf2)', color: 'var(--txt)',
  fontSize: 14, outline: 'none', fontFamily: 'inherit',
}

export default function PricesPage() {
  const [serviceTypes, setServiceTypes] = useState<ServiceType[]>([])
  const [rows, setRows]                 = useState<PriceRow[]>([])
  const [loading, setLoading]           = useState(true)
  const [saving, setSaving]             = useState(false)
  const [msg, setMsg]                   = useState<{type:'ok'|'err'; text:string} | null>(null)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [typesRes, pricesRes] = await Promise.all([
        partnerApi.get('/service-types'),
        partnerApi.get('/service/prices'),
      ])
      const types: ServiceType[] = typesRes.data.data || []
      const existing: {serviceTypeId:string; priceMin:number; priceMax:number}[] =
        (pricesRes.data.data || []).map((p: any) => ({
          serviceTypeId: p.serviceTypeId ?? p.service_type_id,
          priceMin:      p.priceMin ?? p.price_min ?? 0,
          priceMax:      p.priceMax ?? p.price_max ?? 0,
        }))

      setServiceTypes(types)
      setRows(types.map(t => {
        const ex = existing.find(e => e.serviceTypeId === t.id)
        return {
          serviceTypeId: t.id,
          priceMin: ex ? ex.priceMin : '',
          priceMax: ex ? ex.priceMax : '',
        }
      }))
    } catch (e: any) {
      setMsg({ type: 'err', text: 'Не удалось загрузить данные' })
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const updateRow = (id: string, field: 'priceMin' | 'priceMax', val: string) => {
    const n = val === '' ? '' : Math.max(0, parseInt(val.replace(/\D/g, '')) || 0)
    setRows(prev => prev.map(r => r.serviceTypeId === id ? { ...r, [field]: n } : r))
  }

  const handleSave = async () => {
    const filled = rows.filter(r => r.priceMin !== '' || r.priceMax !== '')
    if (filled.length === 0) {
      setMsg({ type: 'err', text: 'Камида биtta хизмат учун нарх киритинг' }); return
    }
    for (const r of filled) {
      const mn = Number(r.priceMin || 0)
      const mx = Number(r.priceMax || 0)
      if (mx > 0 && mn > mx) {
        const t = serviceTypes.find(s => s.id === r.serviceTypeId)
        setMsg({ type: 'err', text: `"${t?.nameUz}" — минимал нарх максималдан катта бўлмасин` })
        return
      }
    }

    setSaving(true); setMsg(null)
    try {
      await partnerApi.put('/service/prices', {
        prices: filled.map(r => ({
          serviceTypeId: r.serviceTypeId,
          priceMin: Number(r.priceMin || 0),
          priceMax: Number(r.priceMax || 0),
        })),
      })
      setMsg({ type: 'ok', text: 'Нархлар муваффақиятли сақланди ✓' })
    } catch (e: any) {
      setMsg({ type: 'err', text: e.response?.data?.message || 'Сақлашда хатолик' })
    } finally {
      setSaving(false)
    }
  }

  const hasPrice = (r: PriceRow) => r.priceMin !== '' || r.priceMax !== ''

  return (
    <PartnerShell>
      <div className="fade-in" style={{ maxWidth: 680, margin: '0 auto' }}>
        <div style={{ marginBottom: 24 }}>
          <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--txt)', margin: 0 }}>
            Хизмат нархлари
          </h2>
          <p style={{ fontSize: 13, color: 'var(--txt3)', marginTop: 6, lineHeight: 1.5 }}>
            Ҳар бир хизмат учун минимал ва максимал нарх белгиланг.
            Нарх баллон ўлчамига қараб ўзгаради — шунинг учун дапазон кўрсатасиз.
          </p>
        </div>

        {loading ? (
          <div style={{ padding: 60, textAlign: 'center', color: 'var(--txt3)' }}>Загрузка…</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {rows.map((row, i) => {
              const svc = serviceTypes.find(t => t.id === row.serviceTypeId)
              if (!svc) return null
              const active = hasPrice(row)
              return (
                <div key={row.serviceTypeId}
                  style={{
                    background: 'var(--surf)',
                    border: `1.5px solid ${active ? 'var(--blue)' : 'var(--hair)'}`,
                    borderRadius: 14, padding: '16px 18px',
                    transition: 'border-color .2s',
                  }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div style={{
                        width: 36, height: 36, borderRadius: 10,
                        background: active ? 'var(--blueDim)' : 'var(--surf2)',
                        display: 'grid', placeItems: 'center',
                        color: active ? 'var(--blue)' : 'var(--txt3)',
                        transition: 'all .2s',
                      }}>
                        <Icon n="disc" s={18}/>
                      </div>
                      <div>
                        <div style={{ fontWeight: 600, fontSize: 14, color: 'var(--txt)' }}>{svc.nameUz}</div>
                        <div style={{ fontSize: 11.5, color: 'var(--txt3)', marginTop: 1 }}>{svc.nameRu}</div>
                      </div>
                    </div>
                    {active && (
                      <div style={{ fontSize: 12, color: 'var(--blue)', fontWeight: 600 }}>
                        {row.priceMin && row.priceMax
                          ? `${Number(row.priceMin).toLocaleString()} – ${Number(row.priceMax).toLocaleString()} сум`
                          : row.priceMin
                          ? `от ${Number(row.priceMin).toLocaleString()} сум`
                          : `до ${Number(row.priceMax).toLocaleString()} сум`}
                      </div>
                    )}
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
                    <div>
                      <div style={{ fontSize: 11.5, color: 'var(--txt3)', marginBottom: 5, fontWeight: 600 }}>
                        Минимал нарх (сум)
                      </div>
                      <input
                        style={inp}
                        type="number"
                        min={0}
                        placeholder="масалан: 15 000"
                        value={row.priceMin}
                        onChange={e => updateRow(row.serviceTypeId, 'priceMin', e.target.value)}
                      />
                    </div>
                    <div>
                      <div style={{ fontSize: 11.5, color: 'var(--txt3)', marginBottom: 5, fontWeight: 600 }}>
                        Максимал нарх (сум)
                      </div>
                      <input
                        style={inp}
                        type="number"
                        min={0}
                        placeholder="масалан: 40 000"
                        value={row.priceMax}
                        onChange={e => updateRow(row.serviceTypeId, 'priceMax', e.target.value)}
                      />
                    </div>
                  </div>
                </div>
              )
            })}

            {msg && (
              <div style={{
                padding: '10px 14px', borderRadius: 10, fontSize: 13, fontWeight: 500,
                background: msg.type === 'ok' ? 'var(--greenDim)' : 'var(--redDim)',
                color: msg.type === 'ok' ? 'var(--green)' : 'var(--red)',
              }}>
                {msg.text}
              </div>
            )}

            <button
              onClick={handleSave}
              disabled={saving}
              style={{
                height: 48, borderRadius: 12, background: 'var(--inv)', color: 'var(--invT)',
                fontSize: 15, fontWeight: 700, cursor: saving ? 'not-allowed' : 'pointer',
                border: 'none', opacity: saving ? 0.6 : 1, marginTop: 4,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              }}>
              {saving ? 'Сақланмоқда…' : <><Icon n="check" s={18} col="currentColor"/>Нархларни сақлаш</>}
            </button>
          </div>
        )}
      </div>
    </PartnerShell>
  )
}
