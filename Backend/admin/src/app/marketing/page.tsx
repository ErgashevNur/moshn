'use client'
import { useEffect, useState, useRef } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import Icon from '@/components/ui/Icon'
import Toggle from '@/components/ui/Toggle'
import api from '@/lib/api'

// ── App Config (localStorage based — no backend API) ─────────────────────────
const CONFIG_KEY = 'shina24_app_config'
const DEFAULT_CONFIG = [
  { key:'slot_hold',   label:"Slot ushlab turish vaqti",    value:'5 daqiqa',  unit:'daqiqa', numVal:5 },
  { key:'pay_later',   label:'"Keyinroq to\'lash" muddati', value:'14 kun',    unit:'kun',    numVal:14 },
  { key:'installment', label:"Bo'lib to'lash muddati",      value:'3–6 oy',    unit:'oy',     numVal:null },
  { key:'vip_min',     label:"VIP miqyosi",                 value:'5 ta tashrif', unit:'tashrif', numVal:5 },
]

function loadConfig() {
  if (typeof window === 'undefined') return DEFAULT_CONFIG
  try {
    const saved = JSON.parse(localStorage.getItem(CONFIG_KEY) || 'null')
    if (!saved) return DEFAULT_CONFIG
    return DEFAULT_CONFIG.map(d => ({ ...d, value: saved[d.key] ?? d.value }))
  } catch { return DEFAULT_CONFIG }
}

function saveConfig(key: string, value: string) {
  try {
    const saved = JSON.parse(localStorage.getItem(CONFIG_KEY) || '{}')
    localStorage.setItem(CONFIG_KEY, JSON.stringify({ ...saved, [key]: value }))
  } catch {}
}

// ── Edit modal ────────────────────────────────────────────────────────────────
function EditModal({ item, onSave, onClose }: {
  item: typeof DEFAULT_CONFIG[0]
  onSave: (value: string) => void
  onClose: () => void
}) {
  const [val, setVal] = useState(item.value)
  const inputRef = useRef<HTMLInputElement>(null)
  useEffect(() => { inputRef.current?.focus() }, [])

  return (
    <div className="mbg" onClick={onClose}>
      <div className="modal" style={{maxWidth:380}} onClick={e => e.stopPropagation()}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:18}}>
          <span style={{fontSize:16,fontWeight:700,color:'var(--txt)'}}>{item.label}</span>
          <button onClick={onClose} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer'}}><Icon n="x" s={20}/></button>
        </div>
        <div style={{marginBottom:18}}>
          <label style={{display:'block',fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',marginBottom:7}}>
            Yangi qiymat
          </label>
          <input ref={inputRef} value={val} onChange={e => setVal(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && onSave(val)}
            style={{width:'100%',background:'var(--surf2)',border:'1px solid var(--hair)',borderRadius:11,padding:'11px 14px',fontSize:15,color:'var(--txt)',fontFamily:'inherit',outline:'none'}}/>
          <p style={{fontSize:12,color:'var(--txt3)',marginTop:7}}>Masalan: {item.unit === 'daqiqa' ? '10 daqiqa' : item.unit === 'kun' ? '30 kun' : item.unit === 'oy' ? '3–6 oy' : '10 ta tashrif'}</p>
        </div>
        <div style={{display:'flex',gap:10}}>
          <button onClick={onClose}
            style={{flex:1,height:44,borderRadius:999,background:'var(--surf2)',color:'var(--txt2)',fontSize:14,fontWeight:600,cursor:'pointer',border:'none'}}>
            Bekor
          </button>
          <button onClick={() => onSave(val)}
            style={{flex:1,height:44,borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:14,fontWeight:600,cursor:'pointer',border:'none'}}>
            Saqlash
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Seasonal Rule modal ───────────────────────────────────────────────────────
function RuleModal({ onSave, onClose }: {
  onSave: (rule: any) => void
  onClose: () => void
}) {
  const [name, setName]   = useState('')
  const [month, setMonth] = useState('10')
  const [day, setDay]     = useState('1')
  const [msgUz, setMsgUz] = useState('')
  const [msgRu, setMsgRu] = useState('')
  const [saving, setSaving] = useState(false)

  const months = ['Yanvar','Fevral','Mart','Aprel','May','Iyun','Iyul','Avgust','Sentabr','Oktabr','Noyabr','Dekabr']

  const submit = async () => {
    if (!name.trim() || !msgUz.trim()) return
    setSaving(true)
    try {
      const r = await api.post('/admin/seasonal-rules', {
        name: name.trim(),
        sendMonth: Number(month),
        sendDay: Number(day),
        messageUz: msgUz.trim(),
        messageRu: msgRu.trim() || msgUz.trim(),
      })
      onSave(r.data.data)
    } finally { setSaving(false) }
  }

  return (
    <div className="mbg" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20}}>
          <span style={{fontSize:16,fontWeight:700,color:'var(--txt)'}}>Yangi mavsum qoidasi</span>
          <button onClick={onClose} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer'}}><Icon n="x" s={20}/></button>
        </div>
        <div style={{display:'flex',flexDirection:'column',gap:14}}>
          {[
            {l:"Qoida nomi", val:name, set:setName, ph:"Masalan: Qish shinasi eslatmasi"},
            {l:"O'zbek tili xabari", val:msgUz, set:setMsgUz, ph:"Qishki g'ildiraklarga o'tish vaqti keldi!"},
            {l:"Rus tili xabari (ixtiyoriy)", val:msgRu, set:setMsgRu, ph:"Время перейти на зимние шины!"},
          ].map(({l,val,set,ph}) => (
            <div key={l}>
              <label style={{display:'block',fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',marginBottom:6}}>{l}</label>
              <input value={val} onChange={e => set(e.target.value)} placeholder={ph}
                style={{width:'100%',background:'var(--surf2)',border:'1px solid var(--hair)',borderRadius:11,padding:'10px 13px',fontSize:14,color:'var(--txt)',fontFamily:'inherit',outline:'none'}}/>
            </div>
          ))}
          <div style={{display:'flex',gap:12}}>
            <div style={{flex:1}}>
              <label style={{display:'block',fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',marginBottom:6}}>Oy</label>
              <select value={month} onChange={e => setMonth(e.target.value)}
                style={{width:'100%',background:'var(--surf2)',border:'1px solid var(--hair)',borderRadius:11,padding:'10px 13px',fontSize:14,color:'var(--txt)',fontFamily:'inherit',outline:'none',cursor:'pointer'}}>
                {months.map((m,i) => <option key={i+1} value={String(i+1)}>{m}</option>)}
              </select>
            </div>
            <div style={{flex:1}}>
              <label style={{display:'block',fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',marginBottom:6}}>Kun</label>
              <select value={day} onChange={e => setDay(e.target.value)}
                style={{width:'100%',background:'var(--surf2)',border:'1px solid var(--hair)',borderRadius:11,padding:'10px 13px',fontSize:14,color:'var(--txt)',fontFamily:'inherit',outline:'none',cursor:'pointer'}}>
                {Array.from({length:28},(_,i) => <option key={i+1} value={String(i+1)}>{i+1}</option>)}
              </select>
            </div>
          </div>
        </div>
        <div style={{display:'flex',gap:10,marginTop:20}}>
          <button onClick={onClose}
            style={{flex:1,height:44,borderRadius:999,background:'var(--surf2)',color:'var(--txt2)',fontSize:14,fontWeight:600,cursor:'pointer',border:'none'}}>Bekor</button>
          <button onClick={submit} disabled={!name.trim() || !msgUz.trim() || saving}
            style={{flex:1,height:44,borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:14,fontWeight:600,cursor:'pointer',border:'none',opacity:(!name.trim()||!msgUz.trim()||saving)?0.5:1}}>
            {saving ? 'Saqlanmoqda…' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Main Page ─────────────────────────────────────────────────────────────────
const SEGS = [
  {k:'all',    l:'Hammasi'},
  {k:'vip',    l:'VIP'},
  {k:'recent', l:"So'nggi 30 kun"},
  {k:'inactive',l:'Faol emas'},
]

export default function MarketingPage() {
  const [title, setTitle] = useState('')
  const [msg, setMsg]     = useState('')
  const [sending, setSending] = useState(false)
  const [sent, setSent]   = useState(false)
  const [seg, setSeg]     = useState('all')

  const [rules, setRules]             = useState<any[]>([])
  const [rulesLoading, setRulesLoading] = useState(true)
  const [toggling, setToggling]       = useState('')
  const [showRuleModal, setShowRuleModal] = useState(false)

  const [config, setConfig]   = useState(DEFAULT_CONFIG)
  const [editItem, setEditItem] = useState<typeof DEFAULT_CONFIG[0] | null>(null)

  useEffect(() => { setConfig(loadConfig()) }, [])

  useEffect(() => {
    api.get('/admin/seasonal-rules').then(r => {
      setRules(r.data.data || [])
    }).finally(() => setRulesLoading(false))
  }, [])

  const handleSend = async () => {
    if (!msg.trim()) return
    setSending(true)
    try {
      await api.post('/admin/notifications/broadcast', {
        title: title.trim() || 'Shina24',
        body: msg.trim(),
      })
      setSent(true)
      setMsg('')
      setTitle('')
      setTimeout(() => setSent(false), 3500)
    } catch {
      alert("Xabar yuborishda xatolik. Qayta urinib ko'ring.")
    } finally { setSending(false) }
  }

  const toggleRule = async (rule: any) => {
    setToggling(rule.id)
    try {
      const r = await api.put(`/admin/seasonal-rules/${rule.id}`, { isActive: !rule.isActive })
      setRules(rs => rs.map(x => x.id === rule.id ? r.data.data : x))
    } finally { setToggling('') }
  }

  const sendRuleNow = async (rule: any) => {
    if (!confirm(`"${rule.name}" bildirishnomasini HOZIR barcha foydalanuvchilarga yuborasizmi?`)) return
    setToggling(rule.id + '_send')
    try {
      await api.post(`/admin/seasonal-rules/${rule.id}/send`)
      alert('✅ Bildirishnoma muvaffaqiyatli yuborildi!')
    } catch { alert('Yuborishda xatolik') }
    finally { setToggling('') }
  }

  const deleteRule = async (rule: any) => {
    if (!confirm(`"${rule.name}" qoidasini o'chirasizmi?`)) return
    // No delete endpoint in backend, so just toggle off
    await toggleRule({ ...rule, isActive: true })
  }

  const onConfigSave = (key: string, value: string) => {
    saveConfig(key, value)
    setConfig(c => c.map(x => x.key === key ? { ...x, value } : x))
    setEditItem(null)
  }

  return (
    <AdminShell title="Marketing va Sozlamalar">
      <div className="fade-in">
        <div className="g2" style={{marginBottom:18}}>

          {/* ── Push sender ─────────── */}
          <div className="card">
            <div style={{fontSize:15,fontWeight:700,marginBottom:4,color:'var(--txt)'}}>Push bildirish yuborish</div>
            <p style={{fontSize:13,color:'var(--txt2)',marginBottom:16,lineHeight:1.5}}>Tanlangan segment bo'yicha xabar yuboring.</p>

            <div style={{display:'flex',flexDirection:'column',gap:8,marginBottom:14}}>
              {SEGS.map(s => (
                <button key={s.k} onClick={() => setSeg(s.k)}
                  style={{display:'flex',alignItems:'center',gap:12,padding:'10px 13px',borderRadius:12,background:seg===s.k?'var(--surf2)':'var(--surf)',border:`1.5px solid ${seg===s.k?'var(--hair2)':'var(--hair)'}`,cursor:'pointer',textAlign:'left'}}>
                  <div style={{width:20,height:20,borderRadius:'50%',border:`2px solid ${seg===s.k?'var(--txt)':'var(--hair2)'}`,display:'grid',placeItems:'center',flexShrink:0}}>
                    {seg===s.k && <div style={{width:10,height:10,borderRadius:'50%',background:'var(--txt)'}}/>}
                  </div>
                  <span style={{flex:1,fontSize:14,fontWeight:600,color:'var(--txt)'}}>{s.l}</span>
                </button>
              ))}
            </div>

            <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Sarlavha (ixtiyoriy, default: Shina24)"
              style={{width:'100%',background:'var(--surf2)',border:'1px solid var(--hair)',borderRadius:11,padding:'10px 14px',fontSize:14,color:'var(--txt)',fontFamily:'inherit',outline:'none',marginBottom:10}}/>
            <textarea value={msg} onChange={e => setMsg(e.target.value)} placeholder="Xabar matni…" rows={3}
              style={{width:'100%',background:'var(--surf2)',border:'1px solid var(--hair)',borderRadius:12,padding:'12px 14px',fontSize:14,color:'var(--txt)',fontFamily:'inherit',outline:'none',resize:'none',marginBottom:12}}/>

            <button disabled={!msg.trim() || sending} onClick={handleSend}
              style={{width:'100%',height:46,borderRadius:999,background:msg.trim()?'var(--inv)':'var(--surf2)',color:msg.trim()?'var(--invT)':'var(--txt3)',fontSize:14,fontWeight:600,cursor:msg.trim()?'pointer':'default',display:'flex',alignItems:'center',justifyContent:'center',gap:8,border:'none',transition:'all .15s'}}>
              {sent     ? <><Icon n="check" s={18}/>Yuborildi!</>
               : sending ? <><span style={{width:16,height:16,borderRadius:'50%',border:'2px solid rgba(255,255,255,.3)',borderTopColor:'#fff',animation:'spin .7s linear infinite',display:'inline-block'}}/>Yuborilmoqda…</>
               : <><Icon n="send" s={18}/>Yuborish ({SEGS.find(s=>s.k===seg)?.l})</>}
            </button>
          </div>

          {/* ── Right column ─────────── */}
          <div style={{display:'flex',flexDirection:'column',gap:14}}>

            {/* Seasonal Rules */}
            <div className="card">
              <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:4}}>
                <div style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>Mavsumiy eslatmalar</div>
                <button onClick={() => setShowRuleModal(true)}
                  style={{height:32,padding:'0 12px',borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:12.5,fontWeight:600,cursor:'pointer',display:'flex',alignItems:'center',gap:6,border:'none'}}>
                  <Icon n="plus" s={14}/>Qo'shish
                </button>
              </div>
              <p style={{fontSize:13,color:'var(--txt2)',marginBottom:14,lineHeight:1.5}}>Avtomatik push — qish/yoz mavsumida.</p>

              {rulesLoading ? (
                <div style={{color:'var(--txt3)',fontSize:13,padding:'8px 0'}}>Yuklanmoqda…</div>
              ) : rules.length === 0 ? (
                <div style={{textAlign:'center',padding:'16px 0',color:'var(--txt3)'}}>
                  <Icon n="snow" s={30}/>
                  <p style={{fontSize:12.5,marginTop:8}}>Qoida yo'q. Qo'shish tugmasini bosing.</p>
                </div>
              ) : rules.map((rule, i) => (
                <div key={rule.id} style={{padding:'12px 14px',borderRadius:13,background:'var(--surf2)',marginBottom:i<rules.length-1?10:0}}>
                  <div style={{display:'flex',alignItems:'flex-start',gap:10}}>
                    <Icon n="snow" s={17} col="var(--blue)" style={{marginTop:2,flexShrink:0}}/>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{fontSize:13.5,fontWeight:600,marginBottom:2,color:'var(--txt)'}}>{rule.name}</div>
                      <div style={{fontSize:11.5,color:'var(--txt3)',marginBottom:2}}>
                        {['Yan','Fev','Mar','Apr','May','Iyn','Iyl','Avg','Sen','Okt','Noy','Dek'][rule.sendMonth-1]} {rule.sendDay}-sana
                      </div>
                      <div style={{fontSize:12,color:'var(--txt2)',lineHeight:1.35}}>{rule.messageUz}</div>
                    </div>
                    <Toggle on={rule.isActive} onChange={() => toggleRule(rule)}/>
                  </div>
                  <div style={{display:'flex',gap:8,marginTop:10,paddingTop:10,borderTop:'1px solid var(--hair)'}}>
                    <button disabled={toggling===rule.id+'_send'}
                      onClick={() => sendRuleNow(rule)}
                      style={{flex:1,height:32,borderRadius:999,background:'var(--greenDim)',color:'var(--green)',fontSize:12,fontWeight:600,cursor:'pointer',border:'none',display:'flex',alignItems:'center',justifyContent:'center',gap:6,opacity:toggling===rule.id+'_send'?0.5:1}}>
                      <Icon n="send" s={13}/>{toggling===rule.id+'_send'?'Yuborilmoqda…':'Hozir yuborish'}
                    </button>
                    {rule.lastSentAt && (
                      <span style={{fontSize:11,color:'var(--txt3)',alignSelf:'center'}}>
                        Oxirgi: {new Date(rule.lastSentAt).toLocaleDateString('uz',{day:'2-digit',month:'2-digit'})}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* App Config */}
            <div className="card">
              <div style={{fontSize:15,fontWeight:700,marginBottom:14,color:'var(--txt)'}}>Ilova konfiguratsiyasi</div>
              {config.map((item, i) => (
                <div key={item.key} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderBottom:i<config.length-1?'1px solid var(--hair)':'none'}}>
                  <span style={{fontSize:13.5,color:'var(--txt2)'}}>{item.label}</span>
                  <div style={{display:'flex',alignItems:'center',gap:9}}>
                    <span style={{fontFamily:"'JetBrains Mono',monospace",fontSize:13,fontWeight:600,color:'var(--txt)'}}>{item.value}</span>
                    <button onClick={() => setEditItem(item)}
                      style={{height:28,padding:'0 10px',borderRadius:999,background:'var(--surf2)',color:'var(--txt2)',fontSize:11.5,fontWeight:600,cursor:'pointer',border:'none',display:'flex',alignItems:'center',gap:5}}>
                      <Icon n="edit" s={12}/>O'zgartirish
                    </button>
                  </div>
                </div>
              ))}
            </div>

          </div>
        </div>
      </div>

      {editItem && (
        <EditModal
          item={editItem}
          onSave={val => onConfigSave(editItem.key, val)}
          onClose={() => setEditItem(null)}
        />
      )}

      {showRuleModal && (
        <RuleModal
          onSave={rule => { setRules(rs => [...rs, rule]); setShowRuleModal(false) }}
          onClose={() => setShowRuleModal(false)}
        />
      )}
    </AdminShell>
  )
}
