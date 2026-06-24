'use client'
import { useEffect, useState, useCallback } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import Icon from '@/components/ui/Icon'
import api from '@/lib/api'

const SC: Record<string, {l:string; c:string}> = {
  pending:     {l:'Ожидает',       c:'b-blue'},
  confirmed:   {l:'Подтверждён',  c:'b-amber'},
  in_progress: {l:'В процессе',   c:'b-amber'},
  completed:   {l:'Завершён',     c:'b-green'},
  cancelled:   {l:'Отменён',      c:'b-red'},
}

function fmt(n: number) { return n.toLocaleString('ru-RU') }
function fmtDate(d: string) {
  return new Date(d).toLocaleDateString('ru-RU', { day:'2-digit', month:'2-digit', year:'2-digit', hour:'2-digit', minute:'2-digit' })
}
function shortId(id: string) { return id.slice(0, 8).toUpperCase() }

export default function BookingsPage() {
  const [bookings, setBookings] = useState<any[]>([])
  const [loading, setLoading]   = useState(true)
  const [error, setError]       = useState('')
  const [st, setSt]             = useState('all')
  const [q, setQ]               = useState('')

  const load = useCallback((status = '') => {
    setLoading(true)
    const qs = status && status !== 'all' ? `?status=${status}&limit=100` : '?limit=100'
    api.get(`/admin/bookings${qs}`).then(r => {
      setBookings(r.data.data?.bookings || [])
    }).catch(() => setError('Ошибка загрузки заказов')).finally(() => setLoading(false))
  }, [])

  useEffect(() => { load() }, [load])

  const statusTabs = [
    ['all','Все'],
    ['completed','Завершён'],
    ['in_progress','В процессе'],
    ['confirmed','Подтверждён'],
    ['pending','Ожидает'],
    ['cancelled','Отменён'],
  ]

  const list = bookings.filter(b => {
    const matchSt = st === 'all' || b.status === st
    const qLow = q.toLowerCase()
    const matchQ = !q
      || (b.customer?.fullName || '').toLowerCase().includes(qLow)
      || (b.shop?.shopName || '').toLowerCase().includes(qLow)
    return matchSt && matchQ
  })

  return (
    <AdminShell title="Заказы">
      <div className="fade-in">
        {/* Search + tabs — stack vertically on mobile */}
        <div style={{display:'flex',flexDirection:'column',gap:10,marginBottom:18}}>
          <div className="srch">
            <Icon n="search" s={15} col="var(--txt3)"/>
            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Клиент или сервис…"
              style={{border:'none',background:'none',fontSize:13.5,color:'var(--txt)',outline:'none',flex:1,fontFamily:'inherit'}}/>
            {q && <button onClick={() => setQ('')} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer'}}><Icon n="x" s={15}/></button>}
          </div>
          {/* Horizontally scrollable tabs */}
          <div className="tabs-scroll">
            {statusTabs.map(([k,l]) => (
              <div key={k} className={`tab ${st===k?'on':''}`}
                onClick={() => { setSt(k); load(k === 'all' ? '' : k) }}
                style={{fontSize:12.5,padding:'7px 14px'}}>{l}</div>
            ))}
          </div>
        </div>

        <div className="card tbl-wrap" style={{padding:0,overflow:'hidden'}}>
          {loading ? (
            <div style={{padding:40,textAlign:'center',color:'var(--txt3)'}}>Загрузка…</div>
          ) : error ? (
            <div style={{padding:40,textAlign:'center',color:'var(--red)'}}>
              {error} <button onClick={() => load()} style={{marginLeft:12,color:'var(--blue)',background:'none',border:'none',cursor:'pointer',fontSize:13}}>Повторить</button>
            </div>
          ) : (
            <table className="tbl">
              <thead>
                <tr><th>ID</th><th>Клиент</th><th>Сервис</th><th>Услуга</th><th>Дата/Время</th><th>Цена</th><th>Статус</th></tr>
              </thead>
              <tbody>
                {list.length === 0 ? (
                  <tr><td colSpan={7} style={{textAlign:'center',padding:24,color:'var(--txt3)'}}>Заказы не найдены</td></tr>
                ) : list.map(b => {
                  const s = SC[b.status] || {l: b.status, c:'b-gray'}
                  return (
                    <tr key={b.id}>
                      <td style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12,color:'var(--txt3)'}}>{shortId(b.id)}</td>
                      <td>
                        <div style={{fontWeight:600,color:'var(--txt)'}}>{b.customer?.fullName || '—'}</div>
                        <div style={{fontSize:11.5,color:'var(--txt3)',fontFamily:"'JetBrains Mono',monospace"}}>{b.customer?.phone || ''}</div>
                      </td>
                      <td style={{color:'var(--txt2)'}}>{b.shop?.shopName || '—'}</td>
                      <td style={{color:'var(--txt2)'}}>{b.serviceType?.nameUz || '—'}</td>
                      <td style={{fontFamily:"'JetBrains Mono',monospace",fontSize:13,color:'var(--txt)'}}>{fmtDate(b.scheduledAt)}</td>
                      <td><span style={{fontFamily:"'JetBrains Mono',monospace",fontWeight:600,color:'var(--txt)'}}>{fmt(b.totalPrice)}</span></td>
                      <td><span className={`badge ${s.c}`}>{s.l}</span></td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </div>

        {!loading && !error && (
          <div style={{textAlign:'right',marginTop:10,fontSize:12.5,color:'var(--txt3)'}}>
            Всего: {list.length} заказов
          </div>
        )}
      </div>
    </AdminShell>
  )
}
