'use client'
import { useEffect, useState, useRef } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import Icon from '@/components/ui/Icon'
import Toggle from '@/components/ui/Toggle'
import api from '@/lib/api'

// ── Types ─────────────────────────────────────────────────────────────────────
type Promo = {
  id: string
  badgeUz: string
  badgeRu: string
  titleUz: string
  titleRu: string
  isActive: boolean
  startDate: string | null
  endDate: string | null
  views?: number
  clicks?: number
  createdAt: string
}

// ── Helpers ───────────────────────────────────────────────────────────────────
const fmtDate = (d: string | null) => {
  if (!d) return '∞'
  const dt = new Date(d)
  return `${dt.getFullYear()}-${String(dt.getMonth()+1).padStart(2,'0')}-${String(dt.getDate()).padStart(2,'0')}`
}
const toInput = (d: string | null) => {
  if (!d) return ''
  return fmtDate(d)
}
const fmtNum = (n?: number) => !n ? '0' : n >= 1000 ? (n / 1000).toFixed(1) + 'K' : String(n)
const calcCTR = (v?: number, c?: number) => v && v > 0 ? (((c||0) / v) * 100).toFixed(1) + '%' : '—'

// ── Banner Preview ────────────────────────────────────────────────────────────
function BannerPreview({ p, size = 'sm' }: { p: Partial<Promo>; size?: 'sm' | 'lg' }) {
  const sm = size === 'sm'
  return (
    <div style={{
      width: sm ? 160 : '100%', height: sm ? 104 : 172,
      borderRadius: 13, overflow: 'hidden', flexShrink: 0,
      background: 'linear-gradient(135deg,#1e1e24 0%,#2a2a32 100%)',
      position: 'relative',
      display: 'flex', flexDirection: 'column',
      justifyContent: 'space-between',
      padding: sm ? '10px 12px' : '15px 18px',
    }}>
      {/* watermark */}
      <div style={{
        position: 'absolute', right: sm ? -10 : -20, bottom: sm ? -10 : -20,
        fontSize: sm ? 72 : 136, opacity: .08, lineHeight: 1,
        pointerEvents: 'none', userSelect: 'none', color: '#fff',
      }}>✦</div>

      {/* badge chip */}
      {(p.badgeUz) && (
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 4,
          padding: sm ? '2px 7px' : '4px 10px',
          borderRadius: 6, background: 'rgba(255,255,255,.15)',
          backdropFilter: 'blur(4px)',
          fontSize: sm ? 8 : 10.5, fontWeight: 700,
          letterSpacing: '.05em', textTransform: 'uppercase', color: '#fff',
          width: 'fit-content',
        }}>
          {p.badgeUz}
        </div>
      )}

      {/* title */}
      <div style={{
        fontSize: sm ? 10.5 : 17, fontWeight: 700,
        color: '#fff', lineHeight: 1.25, position: 'relative', zIndex: 1,
      }}>
        {p.titleUz || 'Banner sarlavhasi'}
      </div>
    </div>
  )
}

// ── Banner Form (create / edit) ───────────────────────────────────────────────
function BannerForm({ initial, onSave, onClose, onDelete }: {
  initial?: Promo
  onSave: (p: Promo) => void
  onClose: () => void
  onDelete?: () => void
}) {
  const [titleUz,   setTitleUz]   = useState(initial?.titleUz || '')
  const [titleRu,   setTitleRu]   = useState(initial?.titleRu || '')
  const [badgeUz,   setBadgeUz]   = useState(initial?.badgeUz || '')
  const [badgeRu,   setBadgeRu]   = useState(initial?.badgeRu || '')
  const [startDate, setStartDate] = useState(toInput(initial?.startDate ?? null))
  const [endDate,   setEndDate]   = useState(toInput(initial?.endDate ?? null))
  const [isActive,  setIsActive]  = useState(initial?.isActive ?? true)
  const [saving,    setSaving]    = useState(false)
  const [deleting,  setDeleting]  = useState(false)

  const isEdit = !!initial
  const canSave = titleUz.trim().length > 0

  const inp: React.CSSProperties = {
    width: '100%', background: 'var(--surf2)', border: '1px solid var(--hair)',
    borderRadius: 11, padding: '10px 13px', fontSize: 14, color: 'var(--txt)',
    fontFamily: 'inherit', outline: 'none',
  }
  const lbl: React.CSSProperties = {
    display: 'block', fontSize: 11, fontWeight: 700,
    textTransform: 'uppercase', letterSpacing: '.07em',
    color: 'var(--txt3)', marginBottom: 6,
  }

  const submit = async () => {
    if (!canSave) return
    setSaving(true)
    try {
      const payload = {
        titleUz: titleUz.trim(),
        titleRu: titleRu.trim() || undefined,
        badgeUz: badgeUz.trim() || undefined,
        badgeRu: badgeRu.trim() || undefined,
        isActive,
        startDate: startDate ? new Date(startDate).toISOString() : null,
        endDate:   endDate   ? new Date(endDate).toISOString()   : null,
      }
      const r = isEdit
        ? await api.put(`/admin/promos/${initial.id}`, payload)
        : await api.post('/admin/promos', payload)
      onSave(r.data.data)
    } catch { alert('Xatolik yuz berdi') }
    finally { setSaving(false) }
  }

  const handleDelete = async () => {
    if (!onDelete || !confirm("Bannerni o'chirasizmi?")) return
    setDeleting(true)
    try {
      await api.delete(`/admin/promos/${initial!.id}`)
      onDelete()
    } catch { alert("O'chirishda xatolik") }
    finally { setDeleting(false) }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
        <span style={{ fontSize: 15.5, fontWeight: 700, color: 'var(--txt)' }}>
          {isEdit ? 'Bannerni tahrirlash' : 'Yangi banner'}
        </span>
        <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--txt3)', cursor: 'pointer' }}>
          <Icon n="x" s={20}/>
        </button>
      </div>

      {/* live preview */}
      <div style={{ marginBottom: 18 }}>
        <label style={lbl}>Ko'rinish</label>
        <BannerPreview p={{ titleUz, badgeUz }} size="lg"/>
      </div>

      {/* fields */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 13, flex: 1, overflowY: 'auto', paddingRight: 2 }}>

        {/* titleUz */}
        <div>
          <label style={lbl}>Sarlavha (O'zbekcha) *</label>
          <input value={titleUz} onChange={e => setTitleUz(e.target.value)}
            placeholder="Mavsum keldi! Shina almashtirishda chegirma" style={inp}/>
        </div>

        {/* titleRu */}
        <div>
          <label style={lbl}>Sarlavha (Ruscha)</label>
          <input value={titleRu} onChange={e => setTitleRu(e.target.value)}
            placeholder="Сезон пришёл! Скидка на замену шин" style={inp}/>
        </div>

        {/* badge row */}
        <div style={{ display: 'flex', gap: 12 }}>
          <div style={{ flex: 1 }}>
            <label style={lbl}>Badge (O'zbekcha)</label>
            <input value={badgeUz} onChange={e => setBadgeUz(e.target.value)}
              placeholder="-20%" style={inp}/>
          </div>
          <div style={{ flex: 1 }}>
            <label style={lbl}>Badge (Ruscha)</label>
            <input value={badgeRu} onChange={e => setBadgeRu(e.target.value)}
              placeholder="-20%" style={inp}/>
          </div>
        </div>

        {/* dates */}
        <div style={{ display: 'flex', gap: 12 }}>
          <div style={{ flex: 1 }}>
            <label style={lbl}>Boshlanish</label>
            <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)}
              style={{ ...inp, colorScheme: 'dark' }}/>
            <p style={{ fontSize: 11, color: 'var(--txt3)', marginTop: 4 }}>Bo'sh = muddatsiz</p>
          </div>
          <div style={{ flex: 1 }}>
            <label style={lbl}>Tugash</label>
            <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)}
              style={{ ...inp, colorScheme: 'dark' }}/>
            <p style={{ fontSize: 11, color: 'var(--txt3)', marginTop: 4 }}>Bo'sh = muddatsiz</p>
          </div>
        </div>

        {/* active toggle */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '11px 14px', background: 'var(--surf2)', borderRadius: 12 }}>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--txt)' }}>Faol holat</div>
            <div style={{ fontSize: 11.5, color: 'var(--txt3)', marginTop: 2 }}>Ilovada ko'rinadi</div>
          </div>
          <Toggle on={isActive} onChange={() => setIsActive(v => !v)}/>
        </div>
      </div>

      {/* footer */}
      <div style={{ paddingTop: 14, display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button onClick={submit} disabled={!canSave || saving}
          style={{
            height: 46, borderRadius: 999,
            background: canSave ? 'var(--inv)' : 'var(--surf2)',
            color: canSave ? 'var(--invT)' : 'var(--txt3)',
            fontSize: 14, fontWeight: 600, border: 'none',
            cursor: canSave ? 'pointer' : 'default',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
          {saving
            ? <><span style={{ width: 15, height: 15, borderRadius: '50%', border: '2px solid rgba(0,0,0,.2)', borderTopColor: '#000', animation: 'spin .7s linear infinite', display: 'inline-block' }}/>Saqlanmoqda…</>
            : isEdit ? "O'zgarishlarni saqlash" : 'Banner yaratish'
          }
        </button>
        {isEdit && (
          <button onClick={handleDelete} disabled={deleting}
            style={{
              height: 40, borderRadius: 999, background: 'var(--redDim)', color: 'var(--red)',
              fontSize: 13, fontWeight: 600, cursor: 'pointer', border: 'none',
              opacity: deleting ? 0.5 : 1,
            }}>
            {deleting ? "O'chirilmoqda…" : "Bannerni o'chirish"}
          </button>
        )}
      </div>
    </div>
  )
}

// ── Banner List Card ──────────────────────────────────────────────────────────
function BannerCard({ promo, selected, onClick, onToggle, onDelete }: {
  promo: Promo
  selected: boolean
  onClick: () => void
  onToggle: () => void
  onDelete: () => void
}) {
  return (
    <div onClick={onClick} style={{
      background: 'var(--surf)', borderRadius: 16, cursor: 'pointer',
      border: `1.5px solid ${selected ? 'var(--hair2)' : 'var(--hair)'}`,
      boxShadow: selected ? '0 0 0 3px rgba(244,244,242,.06)' : 'none',
      transition: 'border-color .15s, box-shadow .15s',
      padding: 14,
    }}>
      {/* top row */}
      <div style={{ display: 'flex', gap: 14, marginBottom: 12 }}>
        <BannerPreview p={promo} size="sm"/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8, marginBottom: 6 }}>
            <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--txt)', lineHeight: 1.3 }}>
              {promo.titleUz}
            </span>
            <span className={`badge ${promo.isActive ? 'b-green' : 'b-gray'}`}>
              {promo.isActive ? 'Faol' : 'Yashirin'}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 11.5, color: 'var(--txt3)' }}>
            <Icon n="cal" s={11}/>
            <span style={{ fontFamily: "'JetBrains Mono',monospace" }}>
              {fmtDate(promo.startDate)} → {fmtDate(promo.endDate)}
            </span>
          </div>
          {promo.badgeUz && (
            <div style={{ marginTop: 5 }}>
              <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--gold)', background: 'var(--goldDim)', padding: '2px 7px', borderRadius: 5 }}>
                {promo.badgeUz}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* stats */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 12 }}>
        {([
          { label: "Ko'rishlar", val: fmtNum(promo.views),  col: 'var(--blue)'  },
          { label: 'Bosishlar',  val: fmtNum(promo.clicks), col: 'var(--green)' },
          { label: 'CTR',        val: calcCTR(promo.views, promo.clicks), col: 'var(--gold)' },
        ] as const).map(s => (
          <div key={s.label} style={{ background: 'var(--surf2)', borderRadius: 10, padding: '9px 8px', textAlign: 'center' }}>
            <div style={{ fontSize: 9.5, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.06em', color: 'var(--txt3)', marginBottom: 4 }}>
              {s.label}
            </div>
            <div style={{ fontSize: 16, fontWeight: 700, color: s.col, fontFamily: "'JetBrains Mono',monospace" }}>
              {s.val}
            </div>
          </div>
        ))}
      </div>

      {/* actions */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }} onClick={e => e.stopPropagation()}>
        <button onClick={onClick}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            height: 34, padding: '0 12px', borderRadius: 999,
            background: 'var(--surf2)', color: 'var(--txt2)',
            fontSize: 12.5, fontWeight: 600, cursor: 'pointer', border: 'none',
          }}>
          <Icon n="edit" s={13}/>Tahrirlash
        </button>
        <Toggle on={promo.isActive} onChange={onToggle}/>
        <div style={{ flex: 1 }}/>
        <button onClick={onDelete}
          style={{
            width: 32, height: 32, borderRadius: '50%',
            background: 'var(--surf2)', color: 'var(--txt3)',
            border: 'none', cursor: 'pointer',
            display: 'grid', placeItems: 'center',
          }}>
          <Icon n="x" s={14}/>
        </button>
      </div>
    </div>
  )
}

// ── App Config ────────────────────────────────────────────────────────────────
const CONFIG_KEY = 'shina24_app_config'
const DEFAULT_CONFIG = [
  { key: 'slot_hold',   label: "Slot ushlab turish vaqti",    value: '5 daqiqa',    unit: 'daqiqa' },
  { key: 'pay_later',   label: '"Keyinroq to\'lash" muddati', value: '14 kun',      unit: 'kun'    },
  { key: 'installment', label: "Bo'lib to'lash muddati",      value: '3–6 oy',      unit: 'oy'     },
  { key: 'vip_min',     label: "VIP miqyosi",                 value: '5 ta tashrif',unit: 'tashrif'},
]
function loadConfig() {
  if (typeof window === 'undefined') return DEFAULT_CONFIG
  try {
    const s = JSON.parse(localStorage.getItem(CONFIG_KEY) || 'null')
    if (!s) return DEFAULT_CONFIG
    return DEFAULT_CONFIG.map(d => ({ ...d, value: s[d.key] ?? d.value }))
  } catch { return DEFAULT_CONFIG }
}
function saveConfig(key: string, value: string) {
  try {
    const s = JSON.parse(localStorage.getItem(CONFIG_KEY) || '{}')
    localStorage.setItem(CONFIG_KEY, JSON.stringify({ ...s, [key]: value }))
  } catch {}
}

// ── Edit Config Modal ─────────────────────────────────────────────────────────
function EditModal({ item, onSave, onClose }: {
  item: typeof DEFAULT_CONFIG[0]
  onSave: (v: string) => void
  onClose: () => void
}) {
  const [val, setVal] = useState(item.value)
  const ref = useRef<HTMLInputElement>(null)
  useEffect(() => { ref.current?.focus() }, [])
  return (
    <div className="mbg" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 380 }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
          <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--txt)' }}>{item.label}</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--txt3)', cursor: 'pointer' }}><Icon n="x" s={20}/></button>
        </div>
        <label style={{ display: 'block', fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.07em', color: 'var(--txt3)', marginBottom: 7 }}>Yangi qiymat</label>
        <input ref={ref} value={val} onChange={e => setVal(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && onSave(val)}
          style={{ width: '100%', background: 'var(--surf2)', border: '1px solid var(--hair)', borderRadius: 11, padding: '11px 14px', fontSize: 15, color: 'var(--txt)', fontFamily: 'inherit', outline: 'none', marginBottom: 18 }}/>
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={onClose} style={{ flex: 1, height: 44, borderRadius: 999, background: 'var(--surf2)', color: 'var(--txt2)', fontSize: 14, fontWeight: 600, cursor: 'pointer', border: 'none' }}>Bekor</button>
          <button onClick={() => onSave(val)} style={{ flex: 1, height: 44, borderRadius: 999, background: 'var(--inv)', color: 'var(--invT)', fontSize: 14, fontWeight: 600, cursor: 'pointer', border: 'none' }}>Saqlash</button>
        </div>
      </div>
    </div>
  )
}

// ── Seasonal Rule Modal ───────────────────────────────────────────────────────
function RuleModal({ onSave, onClose }: { onSave: (r: any) => void; onClose: () => void }) {
  const [name,  setName]  = useState('')
  const [month, setMonth] = useState('10')
  const [day,   setDay]   = useState('1')
  const [msgUz, setMsgUz] = useState('')
  const [msgRu, setMsgRu] = useState('')
  const [saving, setSaving] = useState(false)
  const months = ['Yanvar','Fevral','Mart','Aprel','May','Iyun','Iyul','Avgust','Sentabr','Oktabr','Noyabr','Dekabr']

  const submit = async () => {
    if (!name.trim() || !msgUz.trim()) return
    setSaving(true)
    try {
      const r = await api.post('/admin/seasonal-rules', {
        name: name.trim(), sendMonth: Number(month), sendDay: Number(day),
        messageUz: msgUz.trim(), messageRu: msgRu.trim() || msgUz.trim(),
      })
      onSave(r.data.data)
    } finally { setSaving(false) }
  }

  const si: React.CSSProperties = { width: '100%', background: 'var(--surf2)', border: '1px solid var(--hair)', borderRadius: 11, padding: '10px 13px', fontSize: 14, color: 'var(--txt)', fontFamily: 'inherit', outline: 'none' }
  const sl: React.CSSProperties = { display: 'block', fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.07em', color: 'var(--txt3)', marginBottom: 6 }

  return (
    <div className="mbg" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--txt)' }}>Yangi mavsum qoidasi</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--txt3)', cursor: 'pointer' }}><Icon n="x" s={20}/></button>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {([
            { l: "Qoida nomi",               v: name,  s: setName,  p: "Qish shinasi eslatmasi" },
            { l: "O'zbek tili xabari",        v: msgUz, s: setMsgUz, p: "Qishki g'ildiraklarga o'tish vaqti keldi!" },
            { l: "Rus tili xabari (ixtiyoriy)", v: msgRu, s: setMsgRu, p: "Время перейти на зимние шины!" },
          ] as const).map(({ l, v, s, p }) => (
            <div key={l}>
              <label style={sl}>{l}</label>
              <input value={v} onChange={e => s(e.target.value)} placeholder={p} style={si}/>
            </div>
          ))}
          <div style={{ display: 'flex', gap: 12 }}>
            <div style={{ flex: 1 }}>
              <label style={sl}>Oy</label>
              <select value={month} onChange={e => setMonth(e.target.value)} style={{ ...si, cursor: 'pointer' }}>
                {months.map((m, i) => <option key={i+1} value={String(i+1)}>{m}</option>)}
              </select>
            </div>
            <div style={{ flex: 1 }}>
              <label style={sl}>Kun</label>
              <select value={day} onChange={e => setDay(e.target.value)} style={{ ...si, cursor: 'pointer' }}>
                {Array.from({ length: 28 }, (_, i) => <option key={i+1} value={String(i+1)}>{i+1}</option>)}
              </select>
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
          <button onClick={onClose} style={{ flex: 1, height: 44, borderRadius: 999, background: 'var(--surf2)', color: 'var(--txt2)', fontSize: 14, fontWeight: 600, cursor: 'pointer', border: 'none' }}>Bekor</button>
          <button onClick={submit} disabled={!name.trim() || !msgUz.trim() || saving}
            style={{ flex: 1, height: 44, borderRadius: 999, background: 'var(--inv)', color: 'var(--invT)', fontSize: 14, fontWeight: 600, cursor: 'pointer', border: 'none', opacity: (!name.trim() || !msgUz.trim() || saving) ? 0.5 : 1 }}>
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Tabs config ───────────────────────────────────────────────────────────────
const TABS = [
  { k: 'banners',  l: 'Bannerlar',     icon: 'bolt'     as const },
  { k: 'push',     l: 'Push xabarlar', icon: 'send'     as const },
  { k: 'seasonal', l: 'Mavsumiy',      icon: 'snow'     as const },
  { k: 'settings', l: 'Sozlamalar',    icon: 'settings' as const },
]

const SEGS = [
  { k: 'all',      l: 'Hammasi'       },
  { k: 'vip',      l: 'VIP'           },
  { k: 'recent',   l: "So'nggi 30 kun"},
  { k: 'inactive', l: 'Faol emas'     },
]

// ── Main Page ─────────────────────────────────────────────────────────────────
export default function MarketingPage() {
  const [tab, setTab] = useState('banners')

  // banners
  const [promos,        setPromos]        = useState<Promo[]>([])
  const [promosLoading, setPromosLoading] = useState(true)
  const [selectedPromo, setSelectedPromo] = useState<Promo | null>(null)
  const [showNew,       setShowNew]       = useState(false)

  // push
  const [pushTitle, setPushTitle] = useState('')
  const [pushMsg,   setPushMsg]   = useState('')
  const [sending,   setSending]   = useState(false)
  const [sent,      setSent]      = useState(false)
  const [seg,       setSeg]       = useState('all')

  // seasonal
  const [rules,        setRules]        = useState<any[]>([])
  const [rulesLoading, setRulesLoading] = useState(true)
  const [showRule,     setShowRule]     = useState(false)
  const [rToggling,    setRToggling]    = useState('')

  // config
  const [config,    setConfig]    = useState(DEFAULT_CONFIG)
  const [editItem,  setEditItem]  = useState<typeof DEFAULT_CONFIG[0] | null>(null)

  useEffect(() => { setConfig(loadConfig()) }, [])

  useEffect(() => {
    api.get('/admin/promos')
      .then(r => setPromos(r.data.data || []))
      .finally(() => setPromosLoading(false))
  }, [])

  useEffect(() => {
    api.get('/admin/seasonal-rules')
      .then(r => setRules(r.data.data || []))
      .finally(() => setRulesLoading(false))
  }, [])

  const togglePromo = async (promo: Promo) => {
    try {
      const r = await api.put(`/admin/promos/${promo.id}`, { isActive: !promo.isActive })
      const updated = r.data.data
      setPromos(ps => ps.map(p => p.id === promo.id ? updated : p))
      if (selectedPromo?.id === promo.id) setSelectedPromo(updated)
    } catch {}
  }

  const deletePromo = async (promo: Promo) => {
    if (!confirm(`"${promo.titleUz}" bannerni o'chirasizmi?`)) return
    try {
      await api.delete(`/admin/promos/${promo.id}`)
      setPromos(ps => ps.filter(p => p.id !== promo.id))
      if (selectedPromo?.id === promo.id) setSelectedPromo(null)
    } catch { alert("O'chirishda xatolik") }
  }

  const onPromoSaved = (promo: Promo) => {
    setPromos(ps => ps.find(p => p.id === promo.id)
      ? ps.map(p => p.id === promo.id ? promo : p)
      : [promo, ...ps]
    )
    setSelectedPromo(promo)
    setShowNew(false)
  }

  const handleSend = async () => {
    if (!pushMsg.trim()) return
    setSending(true)
    try {
      await api.post('/admin/notifications/broadcast', {
        title: pushTitle.trim() || 'Shina24',
        body: pushMsg.trim(),
      })
      setSent(true); setPushMsg(''); setPushTitle('')
      setTimeout(() => setSent(false), 3500)
    } catch { alert("Xabar yuborishda xatolik.") }
    finally { setSending(false) }
  }

  const toggleRule = async (rule: any) => {
    setRToggling(rule.id)
    try {
      const r = await api.put(`/admin/seasonal-rules/${rule.id}`, { isActive: !rule.isActive })
      setRules(rs => rs.map(x => x.id === rule.id ? r.data.data : x))
    } finally { setRToggling('') }
  }

  const sendRuleNow = async (rule: any) => {
    if (!confirm(`"${rule.name}" bildirishnomasini HOZIR yuborasizmi?`)) return
    setRToggling(rule.id + '_send')
    try { await api.post(`/admin/seasonal-rules/${rule.id}/send`); alert('✅ Yuborildi!') }
    catch { alert('Yuborishda xatolik') }
    finally { setRToggling('') }
  }

  const onConfigSave = (key: string, value: string) => {
    saveConfig(key, value)
    setConfig(c => c.map(x => x.key === key ? { ...x, value } : x))
    setEditItem(null)
  }

  // right panel for banners tab
  const rightPanel = showNew ? (
    <BannerForm onSave={onPromoSaved} onClose={() => setShowNew(false)}/>
  ) : selectedPromo ? (
    <BannerForm
      initial={selectedPromo}
      onSave={onPromoSaved}
      onClose={() => setSelectedPromo(null)}
      onDelete={() => {
        setPromos(ps => ps.filter(p => p.id !== selectedPromo.id))
        setSelectedPromo(null)
      }}
    />
  ) : (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%', gap: 14 }}>
      <div style={{ width: 56, height: 56, borderRadius: 16, background: 'var(--surf2)', display: 'grid', placeItems: 'center' }}>
        <Icon n="bolt" s={26} col="var(--txt3)"/>
      </div>
      <p style={{ fontSize: 13.5, color: 'var(--txt3)', textAlign: 'center', lineHeight: 1.5, maxWidth: 190 }}>
        Bannerni tanlang yoki yangi banner yarating
      </p>
      <button onClick={() => { setSelectedPromo(null); setShowNew(true) }}
        style={{ height: 42, padding: '0 18px', borderRadius: 999, background: 'var(--inv)', color: 'var(--invT)', fontSize: 13.5, fontWeight: 600, cursor: 'pointer', border: 'none', display: 'flex', alignItems: 'center', gap: 7 }}>
        <Icon n="plus" s={15}/>Yangi banner
      </button>
    </div>
  )

  return (
    <AdminShell title="Marketing">
      <div className="fade-in" style={{ height: '100%' }}>

        {/* ── Tab bar ────────────────────────────────────────────────── */}
        <div style={{ display: 'flex', borderBottom: '1px solid var(--hair)', marginBottom: 22 }}>
          {TABS.map(t => (
            <button key={t.k} onClick={() => setTab(t.k)}
              style={{
                display: 'flex', alignItems: 'center', gap: 7,
                padding: '0 18px', height: 44,
                background: 'none', border: 'none', cursor: 'pointer',
                fontSize: 13.5, fontWeight: 600,
                color: tab === t.k ? 'var(--txt)' : 'var(--txt3)',
                borderBottom: `2px solid ${tab === t.k ? 'var(--txt)' : 'transparent'}`,
                transition: 'color .15s, border-color .15s',
              }}>
              <Icon n={t.icon} s={15}/>
              {t.l}
            </button>
          ))}
        </div>

        {/* ── Bannerlar ──────────────────────────────────────────────── */}
        {tab === 'banners' && (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 370px', gap: 18, height: 'calc(100vh - 164px)' }}>
            {/* left: list */}
            <div style={{ overflowY: 'auto' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 16 }}>
                <div>
                  <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--txt)', marginBottom: 3 }}>Promo bannerlar</div>
                  <div style={{ fontSize: 12.5, color: 'var(--txt3)' }}>Ilovaning bosh ekranida ko'rsatiladigan reklama kartochkalari</div>
                </div>
                <button onClick={() => { setSelectedPromo(null); setShowNew(true) }}
                  style={{ height: 40, padding: '0 16px', borderRadius: 999, background: 'var(--inv)', color: 'var(--invT)', fontSize: 13.5, fontWeight: 600, cursor: 'pointer', border: 'none', display: 'flex', alignItems: 'center', gap: 7, flexShrink: 0 }}>
                  <Icon n="plus" s={15}/>Yangi banner
                </button>
              </div>

              {promosLoading ? (
                <div style={{ color: 'var(--txt3)', fontSize: 13, padding: '24px 0' }}>Yuklanmoqda…</div>
              ) : promos.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '48px 0', color: 'var(--txt3)' }}>
                  <Icon n="bolt" s={36}/>
                  <p style={{ fontSize: 13, marginTop: 10 }}>Hozircha banner yo'q</p>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  {promos.map(p => (
                    <BannerCard
                      key={p.id} promo={p}
                      selected={selectedPromo?.id === p.id}
                      onClick={() => { setSelectedPromo(p); setShowNew(false) }}
                      onToggle={() => togglePromo(p)}
                      onDelete={() => deletePromo(p)}
                    />
                  ))}
                </div>
              )}
            </div>

            {/* right: detail/form panel */}
            <div style={{ background: 'var(--surf)', border: '1px solid var(--hair)', borderRadius: 18, padding: 22, overflowY: 'auto' }}>
              {rightPanel}
            </div>
          </div>
        )}

        {/* ── Push xabarlar ──────────────────────────────────────────── */}
        {tab === 'push' && (
          <div style={{ maxWidth: 480 }}>
            <div className="card">
              <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 4, color: 'var(--txt)' }}>Push bildirish yuborish</div>
              <p style={{ fontSize: 13, color: 'var(--txt2)', marginBottom: 16, lineHeight: 1.5 }}>Tanlangan segment bo'yicha xabar yuboring.</p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 14 }}>
                {SEGS.map(s => (
                  <button key={s.k} onClick={() => setSeg(s.k)}
                    style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 13px', borderRadius: 12, background: seg === s.k ? 'var(--surf2)' : 'var(--surf)', border: `1.5px solid ${seg === s.k ? 'var(--hair2)' : 'var(--hair)'}`, cursor: 'pointer', textAlign: 'left' }}>
                    <div style={{ width: 20, height: 20, borderRadius: '50%', border: `2px solid ${seg === s.k ? 'var(--txt)' : 'var(--hair2)'}`, display: 'grid', placeItems: 'center', flexShrink: 0 }}>
                      {seg === s.k && <div style={{ width: 10, height: 10, borderRadius: '50%', background: 'var(--txt)' }}/>}
                    </div>
                    <span style={{ flex: 1, fontSize: 14, fontWeight: 600, color: 'var(--txt)' }}>{s.l}</span>
                  </button>
                ))}
              </div>
              <input value={pushTitle} onChange={e => setPushTitle(e.target.value)}
                placeholder="Sarlavha (ixtiyoriy, default: Shina24)"
                style={{ width: '100%', background: 'var(--surf2)', border: '1px solid var(--hair)', borderRadius: 11, padding: '10px 14px', fontSize: 14, color: 'var(--txt)', fontFamily: 'inherit', outline: 'none', marginBottom: 10 }}/>
              <textarea value={pushMsg} onChange={e => setPushMsg(e.target.value)} placeholder="Xabar matni…" rows={3}
                style={{ width: '100%', background: 'var(--surf2)', border: '1px solid var(--hair)', borderRadius: 12, padding: '12px 14px', fontSize: 14, color: 'var(--txt)', fontFamily: 'inherit', outline: 'none', resize: 'none', marginBottom: 12 }}/>
              <button disabled={!pushMsg.trim() || sending} onClick={handleSend}
                style={{ width: '100%', height: 46, borderRadius: 999, background: pushMsg.trim() ? 'var(--inv)' : 'var(--surf2)', color: pushMsg.trim() ? 'var(--invT)' : 'var(--txt3)', fontSize: 14, fontWeight: 600, cursor: pushMsg.trim() ? 'pointer' : 'default', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, border: 'none', transition: 'all .15s' }}>
                {sent     ? <><Icon n="check" s={18}/>Yuborildi!</>
                 : sending ? <><span style={{ width: 16, height: 16, borderRadius: '50%', border: '2px solid rgba(255,255,255,.3)', borderTopColor: '#fff', animation: 'spin .7s linear infinite', display: 'inline-block' }}/>Yuborilmoqda…</>
                 : <><Icon n="send" s={18}/>Yuborish ({SEGS.find(s => s.k === seg)?.l})</>}
              </button>
            </div>
          </div>
        )}

        {/* ── Mavsumiy ───────────────────────────────────────────────── */}
        {tab === 'seasonal' && (
          <div style={{ maxWidth: 520 }}>
            <div className="card">
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
                <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--txt)' }}>Mavsumiy eslatmalar</div>
                <button onClick={() => setShowRule(true)}
                  style={{ height: 32, padding: '0 12px', borderRadius: 999, background: 'var(--inv)', color: 'var(--invT)', fontSize: 12.5, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, border: 'none' }}>
                  <Icon n="plus" s={14}/>Qo'shish
                </button>
              </div>
              <p style={{ fontSize: 13, color: 'var(--txt2)', marginBottom: 14, lineHeight: 1.5 }}>Avtomatik push — qish/yoz mavsumida.</p>
              {rulesLoading ? (
                <div style={{ color: 'var(--txt3)', fontSize: 13, padding: '8px 0' }}>Yuklanmoqda…</div>
              ) : rules.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '16px 0', color: 'var(--txt3)' }}>
                  <Icon n="snow" s={30}/>
                  <p style={{ fontSize: 12.5, marginTop: 8 }}>Qoida yo'q. Qo'shish tugmasini bosing.</p>
                </div>
              ) : rules.map((rule, i) => (
                <div key={rule.id} style={{ padding: '12px 14px', borderRadius: 13, background: 'var(--surf2)', marginBottom: i < rules.length - 1 ? 10 : 0 }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                    <Icon n="snow" s={17} col="var(--blue)" style={{ marginTop: 2, flexShrink: 0 }}/>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13.5, fontWeight: 600, marginBottom: 2, color: 'var(--txt)' }}>{rule.name}</div>
                      <div style={{ fontSize: 11.5, color: 'var(--txt3)', marginBottom: 2 }}>
                        {['Yan','Fev','Mar','Apr','May','Iyn','Iyl','Avg','Sen','Okt','Noy','Dek'][rule.sendMonth-1]} {rule.sendDay}-sana
                      </div>
                      <div style={{ fontSize: 12, color: 'var(--txt2)', lineHeight: 1.35 }}>{rule.messageUz}</div>
                    </div>
                    <Toggle on={rule.isActive} onChange={() => toggleRule(rule)}/>
                  </div>
                  <div style={{ display: 'flex', gap: 8, marginTop: 10, paddingTop: 10, borderTop: '1px solid var(--hair)' }}>
                    <button disabled={rToggling === rule.id + '_send'} onClick={() => sendRuleNow(rule)}
                      style={{ flex: 1, height: 32, borderRadius: 999, background: 'var(--greenDim)', color: 'var(--green)', fontSize: 12, fontWeight: 600, cursor: 'pointer', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, opacity: rToggling === rule.id + '_send' ? 0.5 : 1 }}>
                      <Icon n="send" s={13}/>{rToggling === rule.id + '_send' ? 'Yuborilmoqda…' : 'Hozir yuborish'}
                    </button>
                    {rule.lastSentAt && (
                      <span style={{ fontSize: 11, color: 'var(--txt3)', alignSelf: 'center' }}>
                        Oxirgi: {new Date(rule.lastSentAt).toLocaleDateString('uz', { day: '2-digit', month: '2-digit' })}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ── Sozlamalar ─────────────────────────────────────────────── */}
        {tab === 'settings' && (
          <div style={{ maxWidth: 520 }}>
            <div className="card">
              <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 14, color: 'var(--txt)' }}>Ilova konfiguratsiyasi</div>
              {config.map((item, i) => (
                <div key={item.key} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 0', borderBottom: i < config.length - 1 ? '1px solid var(--hair)' : 'none' }}>
                  <span style={{ fontSize: 13.5, color: 'var(--txt2)' }}>{item.label}</span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
                    <span style={{ fontFamily: "'JetBrains Mono',monospace", fontSize: 13, fontWeight: 600, color: 'var(--txt)' }}>{item.value}</span>
                    <button onClick={() => setEditItem(item)}
                      style={{ height: 28, padding: '0 10px', borderRadius: 999, background: 'var(--surf2)', color: 'var(--txt2)', fontSize: 11.5, fontWeight: 600, cursor: 'pointer', border: 'none', display: 'flex', alignItems: 'center', gap: 5 }}>
                      <Icon n="edit" s={12}/>O'zgartirish
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

      </div>

      {editItem && (
        <EditModal item={editItem} onSave={v => onConfigSave(editItem.key, v)} onClose={() => setEditItem(null)}/>
      )}
      {showRule && (
        <RuleModal onSave={r => { setRules(rs => [...rs, r]); setShowRule(false) }} onClose={() => setShowRule(false)}/>
      )}
    </AdminShell>
  )
}
