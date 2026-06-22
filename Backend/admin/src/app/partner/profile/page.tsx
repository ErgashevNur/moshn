'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import PartnerShell from '@/components/partner/PartnerShell'
import Icon from '@/components/ui/Icon'
import partnerApi from '@/lib/partnerApi'

interface Profile {
  shopName: string
  address: string
  phone: string
  workingHours: string
  serviceTypes: string[]
  user?: { fullName: string; phone: string; email: string }
}

export default function ProfilePage() {
  const router  = useRouter()
  const [data,    setData]    = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving,  setSaving]  = useState(false)
  const [saved,   setSaved]   = useState(false)
  const [form,    setForm]    = useState({ shopName:'', address:'', phone:'', workingHours:'' })

  useEffect(() => {
    if (!localStorage.getItem('partner_access_token')) { router.push('/partner/login'); return }
    partnerApi.get('/service/profile').then(r => {
      const d: Profile = r.data?.data || r.data
      setData(d)
      setForm({
        shopName:     d.shopName     || '',
        address:      d.address      || '',
        phone:        d.phone        || '',
        workingHours: d.workingHours || '',
      })
    }).catch(() => {}).finally(() => setLoading(false))
  }, [router])

  const save = async () => {
    setSaving(true)
    try {
      await partnerApi.put('/service/profile', form)
      setSaved(true)
      setTimeout(() => setSaved(false), 2500)
    } catch {}
    setSaving(false)
  }

  const logout = () => {
    localStorage.removeItem('partner_access_token')
    localStorage.removeItem('partner_refresh_token')
    router.push('/partner/login')
  }

  const inp = (field: keyof typeof form) => ({
    className: 'inp',
    value: form[field],
    onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
      setForm(f => ({ ...f, [field]: e.target.value })),
  })

  return (
    <PartnerShell>
      <div style={{ flex:1, display:'flex', flexDirection:'column', minWidth:0, overflow:'hidden' }}>
        {/* Header */}
        <div style={{ height:60, display:'flex', alignItems:'center', gap:14, padding:'0 18px', borderBottom:'1px solid var(--hair)', flexShrink:0, background:'var(--bgE)' }}>
          <div style={{ flex:1, minWidth:0 }}>
            <div style={{ fontSize:10, fontWeight:700, textTransform:'uppercase', letterSpacing:'.08em', color:'var(--txt3)' }}>SHINA24 PARTNER</div>
            <div style={{ fontSize:16, fontWeight:700, color:'var(--txt)' }}>Профиль</div>
          </div>
        </div>

        {/* Content */}
        <div style={{ flex:1, overflowY:'auto', padding:'20px 18px', maxWidth:560 }}>
          {loading ? (
            <div style={{ textAlign:'center', padding:'60px 0', color:'var(--txt3)' }}>Загрузка…</div>
          ) : (
            <>
              {/* Account info */}
              {data?.user && (
                <div style={{ marginBottom:24 }}>
                  <div className="slbl" style={{ marginBottom:12 }}>ДАННЫЕ АККАУНТА</div>
                  <div className="lcard">
                    {[
                      ['Имя',     data.user.fullName],
                      ['Телефон', data.user.phone],
                    ].map(([l, v], i) => (
                      <div key={i} className="lrow">
                        <span style={{ fontSize:12.5, color:'var(--txt3)', flex:1 }}>{l}</span>
                        <span style={{ fontSize:13.5, fontWeight:600, color:'var(--txt)' }}>{v || '—'}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Shop info form */}
              <div style={{ marginBottom:24 }}>
                <div className="slbl" style={{ marginBottom:12 }}>ДАННЫЕ МАГАЗИНА</div>
                <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
                  {([
                    ['shopName',     'Название',      'text'],
                    ['address',      'Адрес',         'text'],
                    ['phone',        'Телефон',       'tel'],
                    ['workingHours', 'Часы работы',   'text'],
                  ] as const).map(([field, label, type]) => (
                    <div key={field}>
                      <div style={{ fontSize:11, fontWeight:600, color:'var(--txt3)', marginBottom:5, textTransform:'uppercase', letterSpacing:'.06em' }}>{label}</div>
                      <input type={type} placeholder={label} {...inp(field)} style={{ width:'100%' }}/>
                    </div>
                  ))}
                </div>
              </div>

              {/* Service types (read-only chips) */}
              {data?.serviceTypes && data.serviceTypes.length > 0 && (
                <div style={{ marginBottom:24 }}>
                  <div className="slbl" style={{ marginBottom:10 }}>ВИДЫ УСЛУГ</div>
                  <div style={{ display:'flex', flexWrap:'wrap', gap:7 }}>
                    {data.serviceTypes.map(s => (
                      <span key={s} className="chip" style={{ background:'var(--surf2)', color:'var(--txt2)', fontSize:12 }}>{s}</span>
                    ))}
                  </div>
                </div>
              )}

              {/* Save button */}
              <button onClick={save} disabled={saving}
                style={{ width:'100%', height:48, borderRadius:12, background: saved ? 'var(--green)' : 'var(--inv)', color: saved ? '#fff' : 'var(--invT)', fontSize:15, fontWeight:700, border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:8, transition:'background .2s', marginBottom:12 }}>
                {saving ? 'Сохранение…' : saved ? <><Icon n="check" s={18}/>Сохранено!</> : 'Сохранить'}
              </button>

              {/* Logout */}
              <button onClick={logout}
                style={{ width:'100%', height:44, borderRadius:12, background:'var(--redDim)', color:'var(--red)', fontSize:14, fontWeight:600, border:'none', cursor:'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:8 }}>
                <Icon n="logout" s={17} col="var(--red)"/>
                Выйти
              </button>
            </>
          )}
        </div>
      </div>
    </PartnerShell>
  )
}
