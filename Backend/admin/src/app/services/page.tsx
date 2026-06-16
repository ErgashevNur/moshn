'use client'
import { useEffect, useState, useCallback } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import Icon from '@/components/ui/Icon'
import api from '@/lib/api'

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString('uz', { day:'2-digit', month:'2-digit', year:'numeric' })
}

const SVC_TYPES = [
  { slug:'tire_change', label:'Замена шины' },
  { slug:'balancing',   label:'Балансировка' },
  { slug:'tire_repair', label:'Вулканизация' },
  { slug:'inflation',   label:'Подкачка' },
  { slug:'disk_repair', label:'Ремонт диска' },
  { slug:'storage',     label:'Хранение шин' },
]

const EMPTY_FORM = {
  fullName:'', email:'', phone:'', password:'',
  shopName:'', address:'', workingHours:'09:00-18:00',
  serviceTypes:[] as string[],
}

const inp: React.CSSProperties = {
  width:'100%', boxSizing:'border-box', padding:'10px 14px',
  borderRadius:10, border:'1.5px solid var(--hair)',
  background:'var(--surf2)', color:'var(--txt)', fontSize:14, outline:'none',
}

export default function ServicesPage() {
  const [shops, setShops]     = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState('')
  const [flt, setFlt]         = useState('all')
  const [modal, setModal]     = useState<any>(null)
  const [acting, setActing]   = useState('')

  const [addOpen, setAddOpen] = useState(false)
  const [form, setForm]       = useState({ ...EMPTY_FORM })
  const [adding, setAdding]   = useState(false)
  const [addErr, setAddErr]   = useState('')

  const load = useCallback(() => {
    setLoading(true)
    api.get('/admin/shops?limit=100').then(r => {
      setShops(r.data.data?.shops || r.data.shops || [])
    }).catch(() => setError('Ошибка загрузки сервисов')).finally(() => setLoading(false))
  }, [])

  useEffect(() => { load() }, [load])

  const openAdd  = () => { setForm({ ...EMPTY_FORM }); setAddErr(''); setAddOpen(true) }
  const closeAdd = () => { setAddOpen(false); setAddErr('') }

  const toggleSvcType = (slug: string) => setForm(f => ({
    ...f,
    serviceTypes: f.serviceTypes.includes(slug)
      ? f.serviceTypes.filter(s => s !== slug)
      : [...f.serviceTypes, slug],
  }))

  const handleAdd = async () => {
    if (!form.fullName.trim() || !form.email.trim() || !form.phone.trim() || !form.password.trim()) {
      setAddErr('Имя, email, телефон и пароль обязательны'); return
    }
    setAdding(true); setAddErr('')
    try {
      await api.post('/admin/shops', {
        fullName:     form.fullName.trim(),
        email:        form.email.trim(),
        phone:        form.phone.trim(),
        password:     form.password,
        shopName:     form.shopName.trim()     || undefined,
        address:      form.address.trim()      || undefined,
        workingHours: form.workingHours.trim() || undefined,
        serviceTypes: form.serviceTypes.length ? form.serviceTypes : undefined,
      })
      closeAdd()
      load()
    } catch (e: any) {
      setAddErr(e.response?.data?.message || 'Произошла ошибка')
    } finally {
      setAdding(false)
    }
  }

  const mapped = shops.map(s => ({
    ...s,
    status: s.verificationStatus === 'verified' ? 'active'
          : s.verificationStatus === 'rejected'  ? 'suspended'
          : 'pending',
  }))

  const visible = flt === 'all' ? mapped : mapped.filter(s => s.status === flt)
  const pCnt    = mapped.filter(s => s.status === 'pending').length

  const tabs = [
    ['all',       `Все (${mapped.length})`],
    ['active',    'Активные'],
    ['pending',   `На проверке${pCnt > 0 ? ` (${pCnt})` : ''}`],
    ['suspended', 'Заблокированные'],
  ]

  const verify = async (id: string, status: string) => {
    setActing(id + status)
    try {
      await api.put(`/admin/shops/${id}/verify`, { status })
      setShops(prev => prev.map(s => s.id === id ? { ...s, verificationStatus: status } : s))
      if (modal?.id === id) setModal((m: any) => ({ ...m, verificationStatus: status }))
    } finally {
      setActing('')
    }
  }

  const sc = (status: string) =>
    status === 'active'    ? {l:'Активен',      c:'b-green'} :
    status === 'pending'   ? {l:'На проверке',  c:'b-amber'} :
                             {l:'Заблокирован', c:'b-red'}

  return (
    <AdminShell title="Управление сервисами">
      <div className="fade-in">
        <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:18}}>
          <div className="tabs">
            {tabs.map(([k,l]) => (
              <div key={k} className={`tab ${flt===k?'on':''}`} onClick={() => setFlt(k)}>{l}</div>
            ))}
          </div>
          <button onClick={openAdd}
            style={{height:38,padding:'0 16px',borderRadius:999,background:'var(--inv)',color:'var(--invT)',fontSize:13,fontWeight:600,cursor:'pointer',display:'flex',alignItems:'center',gap:8,border:'none'}}>
            <Icon n="plus" s={16}/>Добавить сервис
          </button>
        </div>

        <div className="card" style={{padding:0,overflow:'hidden'}}>
          {loading ? (
            <div style={{padding:40,textAlign:'center',color:'var(--txt3)'}}>Загрузка…</div>
          ) : error ? (
            <div style={{padding:40,textAlign:'center',color:'var(--red)'}}>
              {error} <button onClick={load} style={{marginLeft:12,color:'var(--blue)',background:'none',border:'none',cursor:'pointer',fontSize:13}}>Повторить</button>
            </div>
          ) : (
            <table className="tbl">
              <thead>
                <tr><th>Сервис</th><th>Владелец</th><th>Адрес</th><th>Рейтинг</th><th>Заказы</th><th>Статус</th><th>Действия</th></tr>
              </thead>
              <tbody>
                {visible.length === 0 ? (
                  <tr><td colSpan={7} style={{textAlign:'center',padding:24,color:'var(--txt3)'}}>Сервисы не найдены</td></tr>
                ) : visible.map(s => {
                  const badge = sc(s.status)
                  return (
                    <tr key={s.id} onClick={() => setModal(s)} style={{cursor:'pointer'}}>
                      <td>
                        <div style={{fontWeight:600,color:'var(--txt)'}}>{s.shopName || '—'}</div>
                        <div style={{fontSize:11.5,color:'var(--txt3)'}}>{fmtDate(s.createdAt)}</div>
                      </td>
                      <td style={{color:'var(--txt2)'}}>{s.user?.fullName || '—'}</td>
                      <td><div style={{display:'flex',alignItems:'center',gap:5,color:'var(--txt2)'}}><Icon n="pin" s={13}/>{s.address || '—'}</div></td>
                      <td>
                        {s.ratingAvg > 0
                          ? <span style={{display:'flex',alignItems:'center',gap:4,color:'var(--gold)',fontWeight:700,fontSize:13}}><Icon n="starF" s={12}/>{s.ratingAvg.toFixed(1)}</span>
                          : <span style={{color:'var(--txt3)'}}>—</span>}
                      </td>
                      <td style={{color:'var(--txt2)'}}>{s.totalBookings ?? 0}</td>
                      <td><span className={`badge ${badge.c}`}>{badge.l}</span></td>
                      <td onClick={e => e.stopPropagation()}>
                        <div style={{display:'flex',gap:6}}>
                          {s.status === 'pending' && (
                            <button disabled={!!acting} onClick={() => verify(s.id,'verified')}
                              style={{height:30,padding:'0 12px',borderRadius:999,background:'var(--greenDim)',color:'var(--green)',fontSize:12,fontWeight:600,cursor:'pointer',border:'none',opacity:acting?0.5:1}}>
                              {acting===s.id+'verified'?'…':'Подтвердить'}
                            </button>
                          )}
                          {s.status === 'active' && (
                            <button disabled={!!acting} onClick={() => verify(s.id,'rejected')}
                              style={{height:30,padding:'0 12px',borderRadius:999,background:'var(--surf2)',color:'var(--txt2)',fontSize:12,fontWeight:600,cursor:'pointer',border:'none',opacity:acting?0.5:1}}>
                              {acting===s.id+'rejected'?'…':'Заблокировать'}
                            </button>
                          )}
                          {s.status === 'suspended' && (
                            <button disabled={!!acting} onClick={() => verify(s.id,'verified')}
                              style={{height:30,padding:'0 12px',borderRadius:999,background:'var(--blueDim)',color:'var(--blue)',fontSize:12,fontWeight:600,cursor:'pointer',border:'none',opacity:acting?0.5:1}}>
                              {acting===s.id+'verified'?'…':'Активировать'}
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Detail modal */}
      {modal && !addOpen && (
        <div className="mbg" onClick={() => setModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20}}>
              <span style={{fontSize:19,fontWeight:700,color:'var(--txt)'}}>{modal.shopName || '—'}</span>
              <button onClick={() => setModal(null)} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer'}}><Icon n="x" s={22}/></button>
            </div>
            <div className="lcard">
              {[
                ['Владелец',        modal.user?.fullName || '—'],
                ['Телефон',         modal.phone || '—'],
                ['Email',           modal.user?.email || '—'],
                ['Адрес',           modal.address || '—'],
                ['Добавлен',        fmtDate(modal.createdAt)],
                ['Заказы',          `${modal.totalBookings ?? 0}`],
                ['Рейтинг',         modal.ratingAvg > 0 ? `${modal.ratingAvg.toFixed(1)} ★` : '—'],
                ['Типы услуг',      modal.serviceTypes?.join(', ') || '—'],
                ['Часы работы',     modal.workingHours || '—'],
                ['Статус',          sc(modal.status ?? (modal.verificationStatus === 'verified' ? 'active' : modal.verificationStatus === 'rejected' ? 'suspended' : 'pending')).l],
              ].map(([l,v],i) => (
                <div key={i} className="lrow">
                  <span style={{fontSize:13,color:'var(--txt3)',flex:1}}>{l}</span>
                  <span style={{fontSize:14,fontWeight:600,color:'var(--txt)'}}>{String(v)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Add-shop modal */}
      {addOpen && (
        <div className="mbg" onClick={closeAdd}>
          <div className="modal" style={{maxWidth:480,width:'95%',maxHeight:'90vh',overflowY:'auto'}} onClick={e => e.stopPropagation()}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:20}}>
              <span style={{fontSize:18,fontWeight:700,color:'var(--txt)'}}>Добавить новый сервис</span>
              <button onClick={closeAdd} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer'}}><Icon n="x" s={22}/></button>
            </div>

            <div style={{display:'flex',flexDirection:'column',gap:12}}>
              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                <div>
                  <div style={{fontSize:12,color:'var(--txt3)',marginBottom:5}}>Имя владельца *</div>
                  <input style={inp} placeholder="Иванов Иван" value={form.fullName}
                    onChange={e => setForm(f => ({...f, fullName:e.target.value}))}/>
                </div>
                <div>
                  <div style={{fontSize:12,color:'var(--txt3)',marginBottom:5}}>Название сервиса</div>
                  <input style={inp} placeholder="Shina24 Юнусобод" value={form.shopName}
                    onChange={e => setForm(f => ({...f, shopName:e.target.value}))}/>
                </div>
              </div>

              <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
                <div>
                  <div style={{fontSize:12,color:'var(--txt3)',marginBottom:5}}>Email *</div>
                  <input style={inp} type="email" placeholder="servis@email.com" value={form.email}
                    onChange={e => setForm(f => ({...f, email:e.target.value}))}/>
                </div>
                <div>
                  <div style={{fontSize:12,color:'var(--txt3)',marginBottom:5}}>Телефон *</div>
                  <input style={inp} placeholder="+998901234567" value={form.phone}
                    onChange={e => setForm(f => ({...f, phone:e.target.value}))}/>
                </div>
              </div>

              <div>
                <div style={{fontSize:12,color:'var(--txt3)',marginBottom:5}}>Пароль *</div>
                <input style={inp} type="password" placeholder="Минимум 6 символов" value={form.password}
                  onChange={e => setForm(f => ({...f, password:e.target.value}))}/>
              </div>

              <div>
                <div style={{fontSize:12,color:'var(--txt3)',marginBottom:5}}>Адрес</div>
                <input style={inp} placeholder="Ташкент, Юнусабадский район" value={form.address}
                  onChange={e => setForm(f => ({...f, address:e.target.value}))}/>
              </div>

              <div>
                <div style={{fontSize:12,color:'var(--txt3)',marginBottom:5}}>Часы работы</div>
                <input style={inp} placeholder="09:00-18:00" value={form.workingHours}
                  onChange={e => setForm(f => ({...f, workingHours:e.target.value}))}/>
              </div>

              <div>
                <div style={{fontSize:12,color:'var(--txt3)',marginBottom:7}}>Типы услуг</div>
                <div style={{display:'flex',flexWrap:'wrap',gap:8}}>
                  {SVC_TYPES.map(t => {
                    const on = form.serviceTypes.includes(t.slug)
                    return (
                      <button key={t.slug} onClick={() => toggleSvcType(t.slug)}
                        style={{padding:'5px 12px',borderRadius:999,fontSize:12,fontWeight:600,cursor:'pointer',border:'1.5px solid',
                          borderColor: on ? 'var(--blue)' : 'var(--hair)',
                          background:  on ? 'var(--blueDim)' : 'var(--surf2)',
                          color:       on ? 'var(--blue)'   : 'var(--txt3)'}}>
                        {t.label}
                      </button>
                    )
                  })}
                </div>
              </div>

              {addErr && (
                <div style={{padding:'8px 12px',borderRadius:8,background:'var(--redDim)',color:'var(--red)',fontSize:13}}>
                  {addErr}
                </div>
              )}

              <div style={{display:'flex',gap:10,marginTop:4}}>
                <button onClick={closeAdd} disabled={adding}
                  style={{flex:1,height:42,borderRadius:10,background:'var(--surf2)',color:'var(--txt2)',fontSize:14,fontWeight:600,cursor:'pointer',border:'none',opacity:adding?0.5:1}}>
                  Отмена
                </button>
                <button onClick={handleAdd} disabled={adding}
                  style={{flex:2,height:42,borderRadius:10,background:'var(--inv)',color:'var(--invT)',fontSize:14,fontWeight:600,cursor:'pointer',border:'none',opacity:adding?0.7:1}}>
                  {adding ? 'Сохранение…' : 'Добавить сервис'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  )
}
