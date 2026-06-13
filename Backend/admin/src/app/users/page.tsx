'use client'
import { useEffect, useState, useCallback } from 'react'
import AdminShell from '@/components/admin/AdminShell'
import Icon from '@/components/ui/Icon'
import api from '@/lib/api'

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString('uz', { day:'2-digit', month:'2-digit', year:'numeric' })
}

const ROLE_LABEL: Record<string, string> = {
  owner:   'Mijoz',
  service: 'Servis',
  admin:   'Admin',
  '':      'Aniqlanmagan',
}

export default function UsersPage() {
  const [users, setUsers]     = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState('')
  const [q, setQ]             = useState('')
  const [role, setRole]       = useState('all')

  const load = useCallback(() => {
    setLoading(true)
    const r = role !== 'all' ? `&role=${role}` : ''
    api.get(`/admin/users?limit=100${r}`).then(res => {
      setUsers(res.data.data?.users || [])
    }).catch(() => setError('Foydalanuvchilarni yuklashda xatolik')).finally(() => setLoading(false))
  }, [role])

  useEffect(() => { load() }, [load])

  const list = users.filter(u =>
    !q ||
    (u.fullName || '').toLowerCase().includes(q.toLowerCase()) ||
    (u.phone || '').includes(q) ||
    (u.email || '').toLowerCase().includes(q.toLowerCase())
  )

  return (
    <AdminShell title="Foydalanuvchilar">
      <div className="fade-in">
        <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:18}}>
          <div className="srch" style={{flex:1}}>
            <Icon n="search" s={15} col="var(--txt3)"/>
            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Ism, telefon yoki email…"
              style={{border:'none',background:'none',fontSize:13.5,color:'var(--txt)',outline:'none',flex:1,fontFamily:'inherit'}}/>
            {q && <button onClick={() => setQ('')} style={{background:'none',border:'none',color:'var(--txt3)',cursor:'pointer'}}><Icon n="x" s={15}/></button>}
          </div>
          <div className="tabs">
            {[['all','Hammasi'],['owner','Mijozlar'],['service','Servislar'],['admin','Adminlar']].map(([k,l]) => (
              <div key={k} className={`tab ${role===k?'on':''}`} onClick={() => setRole(k)} style={{fontSize:12.5,padding:'7px 14px'}}>{l}</div>
            ))}
          </div>
          <span style={{fontSize:13,color:'var(--txt3)',flexShrink:0}}>{list.length} ta</span>
        </div>

        <div className="card" style={{padding:0,overflow:'hidden'}}>
          {loading ? (
            <div style={{padding:40,textAlign:'center',color:'var(--txt3)'}}>Yuklanmoqda…</div>
          ) : error ? (
            <div style={{padding:40,textAlign:'center',color:'var(--red)'}}>
              {error} <button onClick={load} style={{marginLeft:12,color:'var(--blue)',background:'none',border:'none',cursor:'pointer',fontSize:13}}>Qayta urinish</button>
            </div>
          ) : (
            <table className="tbl">
              <thead>
                <tr><th>Foydalanuvchi</th><th>Telefon</th><th>Email</th><th>Rol</th><th>Ro'yxatga kirgan</th></tr>
              </thead>
              <tbody>
                {list.length === 0 ? (
                  <tr><td colSpan={5} style={{textAlign:'center',padding:24,color:'var(--txt3)'}}>Foydalanuvchilar topilmadi</td></tr>
                ) : list.map(u => (
                  <tr key={u.id}>
                    <td>
                      <div style={{display:'flex',alignItems:'center',gap:10}}>
                        <div style={{width:32,height:32,borderRadius:'50%',background:'var(--surf2)',display:'grid',placeItems:'center',fontSize:13,fontWeight:700,color:'var(--txt2)',flexShrink:0}}>
                          {(u.fullName || '?')[0].toUpperCase()}
                        </div>
                        <span style={{fontWeight:600,color:'var(--txt)'}}>{u.fullName || '—'}</span>
                      </div>
                    </td>
                    <td style={{fontFamily:"'JetBrains Mono',monospace",fontSize:12.5,color:'var(--txt2)'}}>{u.phone || '—'}</td>
                    <td style={{fontSize:13,color:'var(--txt2)'}}>{u.email || '—'}</td>
                    <td>
                      <span className={`badge ${u.role==='admin'?'b-gold':u.role==='service'?'b-blue':'b-gray'}`}>
                        {ROLE_LABEL[u.role] || u.role}
                      </span>
                    </td>
                    <td style={{color:'var(--txt3)',fontSize:13}}>{fmtDate(u.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </AdminShell>
  )
}
