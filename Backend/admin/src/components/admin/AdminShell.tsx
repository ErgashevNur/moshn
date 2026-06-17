'use client'
import { useEffect, useRef, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import AdminSidebar from './AdminSidebar'
import Icon from '../ui/Icon'
import api from '@/lib/api'

// ── Global Search ────────────────────────────────────────────────────────────
function SearchOverlay({ onClose }: { onClose: () => void }) {
  const router  = useRouter()
  const [q, setQ]           = useState('')
  const [users, setUsers]   = useState<any[]>([])
  const [shops, setShops]   = useState<any[]>([])
  const [loading, setLoading] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => { inputRef.current?.focus() }, [])

  useEffect(() => {
    if (!q.trim()) { setUsers([]); setShops([]); return }
    const t = setTimeout(() => {
      setLoading(true)
      Promise.all([
        api.get(`/admin/users?search=${encodeURIComponent(q)}&limit=5`),
        api.get(`/admin/shops?limit=50`),
      ]).then(([u, s]) => {
        setUsers(u.data.data?.users || [])
        const all: any[] = s.data.data?.shops || []
        setShops(all.filter(sh =>
          sh.shopName?.toLowerCase().includes(q.toLowerCase()) ||
          sh.address?.toLowerCase().includes(q.toLowerCase())
        ).slice(0, 5))
      }).finally(() => setLoading(false))
    }, 380)
    return () => clearTimeout(t)
  }, [q])

  const go = (path: string) => { router.push(path); onClose() }
  const hasResults = users.length > 0 || shops.length > 0

  return (
    <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,.6)',backdropFilter:'blur(4px)',zIndex:1000,display:'flex',alignItems:'flex-start',justifyContent:'center',paddingTop:80}}
      onClick={onClose}>
      <div style={{width:'100%',maxWidth:560,background:'var(--bgE)',borderRadius:18,border:'1px solid var(--hair2)',boxShadow:'0 32px 80px rgba(0,0,0,.5)',overflow:'hidden',animation:'rise .2s ease',margin:'0 16px'}}
        onClick={e => e.stopPropagation()}>

        <div style={{display:'flex',alignItems:'center',gap:10,padding:'14px 18px',borderBottom:'1px solid var(--hair)'}}>
          <Icon n="search" s={18} col="var(--txt3)"/>
          <input ref={inputRef} value={q} onChange={e => setQ(e.target.value)}
            placeholder="Пользователь, сервис, заказ…"
            style={{flex:1,background:'none',border:'none',fontSize:15,color:'var(--txt)',outline:'none',fontFamily:'inherit'}}/>
          {loading && <div style={{width:16,height:16,borderRadius:'50%',border:'2px solid var(--hair2)',borderTopColor:'var(--txt2)',animation:'spin .7s linear infinite'}}/>}
          <button onClick={onClose} style={{cursor:'pointer',color:'var(--txt3)',fontSize:12,padding:'3px 8px',borderRadius:7,background:'var(--surf2)',border:'1px solid var(--hair)'}}>Esc</button>
        </div>

        <div style={{maxHeight:440,overflowY:'auto'}}>
          {!q.trim() ? (
            <div style={{padding:'16px 18px 20px',display:'flex',flexDirection:'column',gap:6}}>
              <div style={{fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',marginBottom:6}}>Быстрые ссылки</div>
              {[
                ['/dashboard','dash','Дашборд'],
                ['/services','store','Сервисы'],
                ['/bookings','list','Заказы'],
                ['/users','users','Пользователи'],
                ['/finance','wallet','Финансы'],
                ['/marketing','bolt','Маркетинг'],
              ].map(([path, ic, label]) => (
                <button key={path} onClick={() => go(path)}
                  style={{display:'flex',alignItems:'center',gap:10,padding:'9px 12px',borderRadius:10,background:'none',border:'none',cursor:'pointer',textAlign:'left',color:'var(--txt)',fontSize:14,fontWeight:500,width:'100%'}}
                  onMouseEnter={e=>(e.currentTarget.style.background='var(--surf)')}
                  onMouseLeave={e=>(e.currentTarget.style.background='none')}>
                  <Icon n={ic as any} s={16} col="var(--txt3)"/>
                  {label}
                </button>
              ))}
            </div>
          ) : !hasResults && !loading ? (
            <div style={{padding:'28px 18px',textAlign:'center',color:'var(--txt3)',fontSize:14}}>
              По запросу &ldquo;{q}&rdquo; ничего не найдено
            </div>
          ) : (
            <div style={{padding:'10px 8px 12px'}}>
              {users.length > 0 && <>
                <div style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',padding:'6px 12px 4px'}}>Пользователи</div>
                {users.map(u => (
                  <button key={u.id} onClick={() => go('/users')}
                    style={{display:'flex',alignItems:'center',gap:11,padding:'9px 12px',borderRadius:10,background:'none',border:'none',cursor:'pointer',width:'100%',textAlign:'left'}}
                    onMouseEnter={e=>(e.currentTarget.style.background='var(--surf)')}
                    onMouseLeave={e=>(e.currentTarget.style.background='none')}>
                    <div style={{width:32,height:32,borderRadius:'50%',background:'var(--surf2)',display:'grid',placeItems:'center',fontSize:13,fontWeight:700,color:'var(--txt2)',flexShrink:0}}>
                      {(u.fullName||'?')[0].toUpperCase()}
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{fontSize:14,fontWeight:600,color:'var(--txt)'}}>{u.fullName}</div>
                      <div style={{fontSize:12,color:'var(--txt3)',fontFamily:"'JetBrains Mono',monospace"}}>{u.phone}</div>
                    </div>
                    <span style={{fontSize:11.5,color:'var(--txt3)',background:'var(--surf2)',padding:'2px 8px',borderRadius:6}}>{u.role}</span>
                  </button>
                ))}
              </>}
              {shops.length > 0 && <>
                <div style={{fontSize:10.5,fontWeight:700,textTransform:'uppercase',letterSpacing:'.07em',color:'var(--txt3)',padding:'10px 12px 4px'}}>Сервисы</div>
                {shops.map(s => (
                  <button key={s.id} onClick={() => go('/services')}
                    style={{display:'flex',alignItems:'center',gap:11,padding:'9px 12px',borderRadius:10,background:'none',border:'none',cursor:'pointer',width:'100%',textAlign:'left'}}
                    onMouseEnter={e=>(e.currentTarget.style.background='var(--surf)')}
                    onMouseLeave={e=>(e.currentTarget.style.background='none')}>
                    <div style={{width:32,height:32,borderRadius:9,background:'var(--surf2)',display:'grid',placeItems:'center',flexShrink:0}}>
                      <Icon n="store" s={16} col="var(--txt3)"/>
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{fontSize:14,fontWeight:600,color:'var(--txt)'}}>{s.shopName}</div>
                      <div style={{fontSize:12,color:'var(--txt3)'}}>{s.address}</div>
                    </div>
                    <span className={`badge ${s.verificationStatus==='verified'?'b-green':s.verificationStatus==='pending'?'b-amber':'b-red'}`} style={{fontSize:11}}>
                      {s.verificationStatus==='verified'?'Активен':s.verificationStatus==='pending'?'На проверке':'Заблокирован'}
                    </span>
                  </button>
                ))}
              </>}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// ── Notifications Panel ──────────────────────────────────────────────────────
function NotifPanel({ onClose, headerH }: { onClose: () => void; headerH?: number }) {
  const [notifs, setNotifs]   = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [marking, setMarking] = useState(false)

  const load = useCallback(() => {
    setLoading(true)
    api.get('/notifications?limit=30').then(r => {
      setNotifs(r.data.data?.notifications || [])
    }).finally(() => setLoading(false))
  }, [])

  useEffect(() => { load() }, [load])

  const markAll = async () => {
    setMarking(true)
    try {
      await api.put('/notifications/read-all')
      setNotifs(ns => ns.map(n => ({ ...n, isRead: true })))
    } finally { setMarking(false) }
  }

  const markOne = async (id: string) => {
    await api.put(`/notifications/${id}/read`)
    setNotifs(ns => ns.map(n => n.id === id ? { ...n, isRead: true } : n))
  }

  function fmtAgo(d: string) {
    const s = Math.floor((Date.now() - new Date(d).getTime()) / 1000)
    if (s < 60) return `${s}с`
    if (s < 3600) return `${Math.floor(s/60)} мин`
    if (s < 86400) return `${Math.floor(s/3600)} ч`
    return `${Math.floor(s/86400)} д`
  }

  const unread = notifs.filter(n => !n.isRead).length

  return (
    <>
      <div style={{position:'fixed',inset:0,zIndex:900}} onClick={onClose}/>
      <div style={{position:'fixed',top:(headerH||56),right:16,width:340,maxWidth:'calc(100vw - 32px)',background:'var(--bgE)',border:'1px solid var(--hair2)',borderRadius:16,boxShadow:'0 20px 60px rgba(0,0,0,.5)',zIndex:901,overflow:'hidden',animation:'rise .18s ease'}}>
        <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',padding:'14px 16px',borderBottom:'1px solid var(--hair)'}}>
          <div style={{display:'flex',alignItems:'center',gap:8}}>
            <span style={{fontSize:15,fontWeight:700,color:'var(--txt)'}}>Уведомления</span>
            {unread > 0 && <span style={{fontSize:11,fontWeight:700,background:'var(--red)',color:'#fff',borderRadius:999,padding:'1px 7px'}}>{unread}</span>}
          </div>
          <div style={{display:'flex',gap:8,alignItems:'center'}}>
            {unread > 0 && (
              <button onClick={markAll} disabled={marking}
                style={{fontSize:12,color:'var(--blue)',background:'none',border:'none',cursor:'pointer',fontWeight:600,opacity:marking?0.5:1}}>
                Отметить всё прочитанным
              </button>
            )}
            <button onClick={onClose} style={{background:'none',border:'none',cursor:'pointer',color:'var(--txt3)'}}><Icon n="x" s={18}/></button>
          </div>
        </div>

        <div style={{maxHeight:400,overflowY:'auto'}}>
          {loading ? (
            <div style={{padding:'28px',textAlign:'center',color:'var(--txt3)',fontSize:13}}>Загрузка…</div>
          ) : notifs.length === 0 ? (
            <div style={{padding:'28px',textAlign:'center',color:'var(--txt3)'}}>
              <Icon n="bell" s={36}/>
              <p style={{marginTop:10,fontSize:13}}>Нет уведомлений</p>
            </div>
          ) : notifs.map(n => (
            <button key={n.id} onClick={() => markOne(n.id)}
              style={{display:'flex',alignItems:'flex-start',gap:10,padding:'12px 16px',width:'100%',border:'none',borderBottom:'1px solid var(--hair)',textAlign:'left',cursor:'pointer',background:n.isRead?'none':'var(--surf)',transition:'background .1s'}}
              onMouseEnter={e=>(e.currentTarget.style.background='var(--surf2)')}
              onMouseLeave={e=>(e.currentTarget.style.background=n.isRead?'none':'var(--surf)')}>
              <div style={{width:8,height:8,borderRadius:'50%',background:n.isRead?'transparent':'var(--blue)',marginTop:5,flexShrink:0}}/>
              <div style={{flex:1,minWidth:0}}>
                <div style={{fontSize:13.5,fontWeight:n.isRead?500:700,color:'var(--txt)',marginBottom:2}}>{n.title}</div>
                <div style={{fontSize:12.5,color:'var(--txt2)',lineHeight:1.4}}>{n.body}</div>
              </div>
              <span style={{fontSize:11,color:'var(--txt3)',flexShrink:0,marginTop:2}}>{fmtAgo(n.createdAt)}</span>
            </button>
          ))}
        </div>
      </div>
    </>
  )
}

const DARK_T: Record<string,string> = {bg:'#09090a',bgE:'#131316',surf:'#1a1a1e',surf2:'#242429',surf3:'#2e2e34',hair:'rgba(255,255,255,.085)',hair2:'rgba(255,255,255,.14)',txt:'#f4f4f2',txt2:'rgba(244,244,242,.60)',txt3:'rgba(244,244,242,.36)',inv:'#f4f4f2',invT:'#0a0a0b',gold:'#d4a843',goldDim:'rgba(212,168,67,.16)',red:'#e5382b',redDim:'rgba(229,56,43,.16)',green:'#30d158',greenDim:'rgba(48,209,88,.16)',amber:'#f59e0b',amberDim:'rgba(245,158,11,.14)',blue:'#3b82f6',blueDim:'rgba(59,130,246,.14)',purple:'#a78bfa',purpleDim:'rgba(167,139,250,.14)'}
const LIGHT_T: Record<string,string> = {bg:'#f4f3f0',bgE:'#fff',surf:'#fff',surf2:'#ecebe7',surf3:'#e3e2dd',hair:'rgba(20,20,16,.09)',hair2:'rgba(20,20,16,.15)',txt:'#14140f',txt2:'rgba(20,20,15,.58)',txt3:'rgba(20,20,15,.40)',inv:'#14140f',invT:'#f6f5f2',gold:'#c49a1a',goldDim:'rgba(196,154,26,.16)',red:'#e5382b',redDim:'rgba(229,56,43,.16)',green:'#1a9e48',greenDim:'rgba(26,158,72,.16)',amber:'#c47d0a',amberDim:'rgba(196,125,10,.13)',blue:'#2563eb',blueDim:'rgba(37,99,235,.13)',purple:'#7c3aed',purpleDim:'rgba(124,58,237,.13)'}

function applyThemeVars(t: string) {
  const T = t === 'dark' ? DARK_T : LIGHT_T
  Object.entries(T).forEach(([k,v]) => document.documentElement.style.setProperty(`--${k}`, v))
  localStorage.setItem('ma_theme', t)
}

// ── Shell ────────────────────────────────────────────────────────────────────
export default function AdminShell({ title, children }: { title: string; children: React.ReactNode }) {
  const router = useRouter()
  const [searchOpen, setSearchOpen] = useState(false)
  const [nOpen, setNOpen]           = useState(false)
  const [unread, setUnread]         = useState(0)
  const [theme, setTheme]           = useState('dark')

  const logout = () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    router.push('/login')
  }

  // Sidebar states
  const [collapsed, setCollapsed] = useState(false)
  const [isMobile, setIsMobile]   = useState(false)

  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  useEffect(() => {
    const token = localStorage.getItem('access_token')
    if (!token) { router.push('/login'); return }
    const saved = localStorage.getItem('ma_collapsed')
    if (saved) setCollapsed(saved === '1')
    const savedTheme = localStorage.getItem('ma_theme') || 'dark'
    setTheme(savedTheme)
    applyThemeVars(savedTheme)
    api.get('/notifications?limit=1').then(r => {
      setUnread(r.data.data?.unread_count ?? 0)
    }).catch(() => {})
  }, [router])

  const toggleTheme = () => {
    const next = theme === 'dark' ? 'light' : 'dark'
    setTheme(next)
    applyThemeVars(next)
  }

  const toggleCollapse = () => {
    const next = !collapsed
    setCollapsed(next)
    localStorage.setItem('ma_collapsed', next ? '1' : '0')
  }

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') { e.preventDefault(); setSearchOpen(true) }
      if (e.key === 'Escape') { setSearchOpen(false); setNOpen(false) }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

  return (
    <div style={{display:'flex',height:'100vh',background:'var(--bg)',color:'var(--txt)',overflow:'hidden'}}>
      <AdminSidebar
        collapsed={collapsed}
        mobileOpen={false}
        onClose={() => {}}
        onToggleCollapse={toggleCollapse}
      />

      <div style={{
        flex:1, display:'flex', flexDirection:'column', minWidth:0, overflow:'hidden',
        paddingBottom: isMobile ? 'calc(64px + env(safe-area-inset-bottom))' : 0,
      }}>
        {/* Header — no border on mobile */}
        <div style={{
          height:56,
          display:'flex', alignItems:'center', gap:10,
          padding:'0 16px 0 20px',
          borderBottom: isMobile ? 'none' : '1px solid var(--hair)',
          flexShrink:0,
          background:'var(--bgE)',
        }}>
          <h1 style={{fontSize: isMobile ? 18 : 17, fontWeight:700, letterSpacing:'-.02em', flex:1, color:'var(--txt)', minWidth:0, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap'}}>{title}</h1>

          <div style={{display:'flex',alignItems:'center',gap:8,flexShrink:0}}>
            {/* Search trigger */}
            <button onClick={() => setSearchOpen(true)}
              style={{display:'flex',alignItems:'center',gap:8,height:34,padding:'0 12px',borderRadius:9,background:'var(--surf)',border:'1px solid var(--hair)',cursor:'pointer',color:'var(--txt3)',fontSize:13.5}}>
              <Icon n="search" s={14} col="var(--txt3)"/>
              {!isMobile && <><span>Поиск…</span><span style={{fontSize:11,background:'var(--surf2)',border:'1px solid var(--hair2)',borderRadius:5,padding:'1px 6px',color:'var(--txt3)',fontFamily:"'JetBrains Mono',monospace",marginLeft:6}}>⌘K</span></>}
            </button>

            {/* Notifications bell */}
            <div style={{position:'relative'}}>
              <button onClick={() => { setNOpen(o => !o); setUnread(0) }}
                style={{width:36,height:36,borderRadius:9,background:'var(--surf)',border:'1px solid var(--hair)',display:'grid',placeItems:'center',color:'var(--txt2)',cursor:'pointer'}}>
                <Icon n="bell" s={17}/>
              </button>
              {unread > 0 && (
                <div style={{position:'absolute',top:7,right:7,width:7,height:7,borderRadius:'50%',background:'var(--red)',border:'2px solid var(--bgE)'}}/>
              )}
              {nOpen && <NotifPanel onClose={() => setNOpen(false)} headerH={56}/>}
            </div>

            {/* Theme toggle */}
            <button onClick={toggleTheme}
              style={{display:'flex',alignItems:'center',gap:7,height:36,padding:'0 12px',borderRadius:9,background:'var(--surf)',border:'1px solid var(--hair)',cursor:'pointer',color:'var(--txt2)',fontSize:13,fontWeight:600,flexShrink:0}}>
              <Icon n={theme==='dark'?'sun':'moon'} s={16} col="var(--txt2)"/>
              {!isMobile && <span>{theme==='dark'?'Светлая':'Тёмная'}</span>}
            </button>

            {/* Logout — mobile only */}
            {isMobile && (
              <button onClick={logout}
                style={{width:36,height:36,borderRadius:9,background:'var(--surf)',border:'1px solid var(--hair)',display:'grid',placeItems:'center',color:'var(--red)',cursor:'pointer',flexShrink:0}}>
                <Icon n="logout" s={17} col="var(--red)"/>
              </button>
            )}
          </div>
        </div>

        {/* Body */}
        <div style={{flex:1,overflowY:'auto',padding: isMobile ? 16 : 24}}>
          {children}
        </div>
      </div>

      {searchOpen && <SearchOverlay onClose={() => setSearchOpen(false)}/>}
    </div>
  )
}
