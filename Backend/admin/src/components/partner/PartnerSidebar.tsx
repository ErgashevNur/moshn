'use client'
import { useRouter, usePathname } from 'next/navigation'
import { useState, useEffect } from 'react'
import Icon from '../ui/Icon'
import Brand from '../ui/Brand'

const NAV = [
  {id:'today',     icon:'cal'   as const, label:'Сегодня',  href:'/partner'},
  {id:'queue',     icon:'list'  as const, label:'Очередь',  href:'/partner/queue'},
  {id:'customers', icon:'users' as const, label:'Клиенты',  href:'/partner/customers'},
  {id:'terminal',  icon:'card'  as const, label:'Терминал', href:'/partner/terminal'},
  {id:'stats',     icon:'chart' as const, label:'Отчёт',    href:'/partner/stats'},
]

const DARK: Record<string,string> = {bg:'#09090a',bgE:'#131316',surf:'#1a1a1e',surf2:'#242429',surf3:'#2e2e34',hair:'rgba(255,255,255,.085)',hair2:'rgba(255,255,255,.14)',txt:'#f4f4f2',txt2:'rgba(244,244,242,.60)',txt3:'rgba(244,244,242,.36)',inv:'#f4f4f2',invT:'#0a0a0b',gold:'#d4a843',goldDim:'rgba(212,168,67,.16)',red:'#e5382b',redDim:'rgba(229,56,43,.16)',green:'#30d158',greenDim:'rgba(48,209,88,.16)',amber:'#f59e0b',amberDim:'rgba(245,158,11,.15)',blue:'#3b82f6',blueDim:'rgba(59,130,246,.15)'}
const LIGHT: Record<string,string> = {bg:'#f4f3f0',bgE:'#fff',surf:'#fff',surf2:'#ecebe7',surf3:'#e3e2dd',hair:'rgba(20,20,16,.09)',hair2:'rgba(20,20,16,.15)',txt:'#14140f',txt2:'rgba(20,20,15,.58)',txt3:'rgba(20,20,15,.40)',inv:'#14140f',invT:'#f6f5f2',gold:'#c49a1a',goldDim:'rgba(196,154,26,.16)',red:'#e5382b',redDim:'rgba(229,56,43,.16)',green:'#1a9e48',greenDim:'rgba(26,158,72,.16)',amber:'#c47d0a',amberDim:'rgba(196,125,10,.13)',blue:'#2563eb',blueDim:'rgba(37,99,235,.13)'}

function applyTheme(t: string) {
  const T = t === 'dark' ? DARK : LIGHT
  Object.entries(T).forEach(([k,v]) => document.documentElement.style.setProperty(`--${k}`, v))
  localStorage.setItem('mp_theme', t)
}

interface Props { pendingCount?: number }

export default function PartnerSidebar({ pendingCount = 0 }: Props) {
  const router   = useRouter()
  const pathname = usePathname()
  const [theme, setTheme]     = useState('dark')
  const [isMobile, setMobile] = useState(false)

  useEffect(() => {
    const check = () => setMobile(window.innerWidth < 768)
    check()
    window.addEventListener('resize', check)
    return () => window.removeEventListener('resize', check)
  }, [])

  useEffect(() => {
    const saved = localStorage.getItem('mp_theme') || 'dark'
    setTheme(saved)
    applyTheme(saved)
  }, [])

  const isActive = (href: string) => href === '/partner' ? pathname === '/partner' : pathname.startsWith(href)

  const toggleTheme = () => {
    const next = theme === 'dark' ? 'light' : 'dark'
    setTheme(next); applyTheme(next)
  }

  const logout = () => {
    localStorage.removeItem('partner_access_token')
    localStorage.removeItem('partner_refresh_token')
    router.push('/partner/login')
  }

  // ── Mobile bottom nav bar ────────────────────────────────────────────────
  if (isMobile) {
    return (
      <nav style={{
        position:'fixed', bottom:0, left:0, right:0, height:64,
        background:'var(--bgE)', borderTop:'1px solid var(--hair)',
        display:'flex', alignItems:'stretch', zIndex:100,
        paddingBottom:'env(safe-area-inset-bottom)',
      }}>
        {NAV.map(n => {
          const active = isActive(n.href)
          return (
            <button key={n.id} onClick={() => router.push(n.href)}
              style={{
                flex:1, display:'flex', flexDirection:'column', alignItems:'center',
                justifyContent:'center', gap:3, border:'none', background:'none',
                color: active ? 'var(--txt)' : 'var(--txt3)',
                cursor:'pointer', position:'relative', fontSize:9.5,
                fontWeight: active ? 700 : 500,
                letterSpacing:'.04em',
              }}>
              {/* Active indicator dot */}
              {active && (
                <div style={{position:'absolute',top:6,width:20,height:2.5,borderRadius:2,background:'var(--txt)'}}/>
              )}
              <div style={{position:'relative'}}>
                <Icon n={n.icon} s={22}/>
                {n.id==='queue' && pendingCount > 0 && (
                  <div style={{position:'absolute',top:-3,right:-5,minWidth:14,height:14,borderRadius:999,background:'var(--red)',color:'#fff',fontSize:8,fontWeight:700,display:'grid',placeItems:'center',padding:'0 3px',border:'2px solid var(--bgE)'}}>{pendingCount}</div>
                )}
              </div>
              {n.label}
            </button>
          )
        })}
      </nav>
    )
  }

  // ── Desktop left sidebar ─────────────────────────────────────────────────
  return (
    <div style={{width:72,background:'var(--bgE)',borderRight:'1px solid var(--hair)',display:'flex',flexDirection:'column',alignItems:'center',padding:'12px 0',gap:2,flexShrink:0,zIndex:2}}>
      <div style={{width:44,height:44,borderRadius:13,background:'var(--inv)',color:'var(--invT)',display:'grid',placeItems:'center',marginBottom:14,flexShrink:0}}>
        <Brand s={28}/>
      </div>

      {NAV.map(n => (
        <button key={n.id} onClick={() => router.push(n.href)}
          style={{width:54,height:54,borderRadius:13,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',gap:3,color:isActive(n.href)?'var(--txt)':'var(--txt3)',fontSize:8.5,fontWeight:700,letterSpacing:'.05em',textTransform:'uppercase',cursor:'pointer',transition:'all .15s',position:'relative',border:'none',background:isActive(n.href)?'var(--surf)':'none'}}>
          <div style={{position:'relative'}}>
            <Icon n={n.icon} s={22}/>
            {n.id==='queue' && pendingCount > 0 && (
              <div style={{position:'absolute',top:-3,right:-5,minWidth:16,height:16,borderRadius:999,background:'var(--red)',color:'#fff',fontSize:9,fontWeight:700,display:'grid',placeItems:'center',padding:'0 4px',border:'2px solid var(--bgE)'}}>{pendingCount}</div>
            )}
          </div>
          {n.label}
        </button>
      ))}

      <div style={{flex:1}}/>
      <div style={{width:34,height:1,background:'var(--hair)',margin:'6px 0'}}/>
      <button onClick={toggleTheme}
        style={{width:54,height:54,borderRadius:13,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',gap:3,color:'var(--txt3)',fontSize:8.5,fontWeight:700,letterSpacing:'.05em',textTransform:'uppercase',cursor:'pointer',border:'none',background:'none'}}>
        <Icon n={theme==='dark'?'sun':'moon'} s={20}/>Тема
      </button>
      <button onClick={logout}
        style={{width:54,height:54,borderRadius:13,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',gap:3,color:'var(--txt3)',fontSize:8.5,fontWeight:700,letterSpacing:'.05em',textTransform:'uppercase',cursor:'pointer',border:'none',background:'none'}}>
        <Icon n="logout" s={20}/>Выйти
      </button>
    </div>
  )
}
