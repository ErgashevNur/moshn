'use client'
import { useRouter, usePathname } from 'next/navigation'
import { useState, useEffect } from 'react'
import Icon from '../ui/Icon'
import Brand from '../ui/Brand'

const NAV = [
  { id:'dashboard', icon:'dash'   as const, label:'Дашборд',      labelShort:'Главная',  href:'/dashboard',  group:0 },
  { id:'services',  icon:'store'  as const, label:'Сервисы',       labelShort:'Сервисы',  href:'/services',   group:0, badge:2 },
  { id:'bookings',  icon:'list'   as const, label:'Заказы',        labelShort:'Заказы',   href:'/bookings',   group:0 },
  { id:'users',     icon:'users'  as const, label:'Пользователи',  labelShort:'Клиенты',  href:'/users',      group:1 },
  { id:'finance',   icon:'wallet' as const, label:'Финансы',       labelShort:'Финансы',  href:'/finance',    group:1 },
  { id:'marketing', icon:'bolt'   as const, label:'Маркетинг',     labelShort:'Маркетинг',href:'/marketing',  group:1 },
]

// Bottom nav shows only top 5 (marketing dropped)
const BOTTOM_NAV = NAV.slice(0, 5)

interface Props {
  collapsed: boolean
  mobileOpen: boolean
  onClose: () => void
  onToggleCollapse: () => void
}

const DARK: Record<string,string> = {bg:'#09090a',bgE:'#131316',surf:'#1a1a1e',surf2:'#242429',surf3:'#2e2e34',hair:'rgba(255,255,255,.085)',hair2:'rgba(255,255,255,.14)',txt:'#f4f4f2',txt2:'rgba(244,244,242,.60)',txt3:'rgba(244,244,242,.36)',inv:'#f4f4f2',invT:'#0a0a0b',gold:'#d4a843',goldDim:'rgba(212,168,67,.16)',red:'#e5382b',redDim:'rgba(229,56,43,.16)',green:'#30d158',greenDim:'rgba(48,209,88,.16)',amber:'#f59e0b',amberDim:'rgba(245,158,11,.14)',blue:'#3b82f6',blueDim:'rgba(59,130,246,.14)',purple:'#a78bfa',purpleDim:'rgba(167,139,250,.14)'}
const LIGHT: Record<string,string> = {bg:'#f4f3f0',bgE:'#fff',surf:'#fff',surf2:'#ecebe7',surf3:'#e3e2dd',hair:'rgba(20,20,16,.09)',hair2:'rgba(20,20,16,.15)',txt:'#14140f',txt2:'rgba(20,20,15,.58)',txt3:'rgba(20,20,15,.40)',inv:'#14140f',invT:'#f6f5f2',gold:'#c49a1a',goldDim:'rgba(196,154,26,.16)',red:'#e5382b',redDim:'rgba(229,56,43,.16)',green:'#1a9e48',greenDim:'rgba(26,158,72,.16)',amber:'#c47d0a',amberDim:'rgba(196,125,10,.13)',blue:'#2563eb',blueDim:'rgba(37,99,235,.13)',purple:'#7c3aed',purpleDim:'rgba(124,58,237,.13)'}

function applyTheme(t: string) {
  const T = t === 'dark' ? DARK : LIGHT
  Object.entries(T).forEach(([k,v]) => document.documentElement.style.setProperty(`--${k}`, v))
  localStorage.setItem('ma_theme', t)
}

export default function AdminSidebar({ collapsed, mobileOpen, onClose, onToggleCollapse }: Props) {
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
    const saved = localStorage.getItem('ma_theme') || 'dark'
    setTheme(saved)
    applyTheme(saved)
  }, [])

  const toggleTheme = () => {
    const next = theme === 'dark' ? 'light' : 'dark'
    setTheme(next); applyTheme(next)
  }

  const logout = () => {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    router.push('/login')
  }

  const go = (href: string) => {
    router.push(href)
    if (isMobile) onClose()
  }

  // ── Mobile: bottom nav bar ──────────────────────────────────────────────
  if (isMobile) {
    return (
      <nav style={{
        position:'fixed', bottom:0, left:0, right:0, height:64,
        background:'var(--bgE)', borderTop:'1px solid var(--hair)',
        display:'flex', alignItems:'stretch', zIndex:100,
        paddingBottom:'env(safe-area-inset-bottom)',
      }}>
        {BOTTOM_NAV.map(n => {
          const active = pathname === n.href || (n.href !== '/dashboard' && pathname.startsWith(n.href))
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
              {active && (
                <div style={{position:'absolute',top:6,width:20,height:2.5,borderRadius:2,background:'var(--txt)'}}/>
              )}
              <div style={{position:'relative'}}>
                <Icon n={n.icon} s={22}/>
                {n.badge && n.id==='services' && (
                  <div style={{position:'absolute',top:-3,right:-5,minWidth:14,height:14,borderRadius:999,background:'var(--amber)',color:'#111',fontSize:8,fontWeight:700,display:'grid',placeItems:'center',padding:'0 3px',border:'2px solid var(--bgE)'}}>{n.badge}</div>
                )}
              </div>
              {n.labelShort}
            </button>
          )
        })}
      </nav>
    )
  }

  // ── Desktop: collapsible sidebar ────────────────────────────────────────
  const showLabel = !collapsed

  const navBtn = (n: typeof NAV[0]) => (
    <button key={n.id} onClick={() => go(n.href)}
      title={!showLabel ? n.label : undefined}
      style={{
        display:'flex', alignItems:'center', gap:showLabel ? 10 : 0,
        justifyContent: showLabel ? 'flex-start' : 'center',
        padding: showLabel ? '9px 12px' : '10px 0',
        margin: showLabel ? '1px 8px' : '1px 6px',
        borderRadius:11, fontSize:13.5,
        fontWeight:pathname===n.href?600:500,
        color:pathname===n.href?'var(--txt)':'var(--txt2)',
        cursor:'pointer', transition:'background .13s', border:'none',
        background:pathname===n.href?'var(--surf)':'none',
        position:'relative',
      }}>
      <Icon n={n.icon} s={17}/>
      {showLabel && <span style={{flex:1, whiteSpace:'nowrap'}}>{n.label}</span>}
      {n.badge && n.id==='services' && showLabel && (
        <span style={{minWidth:18,height:18,borderRadius:999,background:'var(--amber)',color:'#111',fontSize:10,fontWeight:700,display:'grid',placeItems:'center',padding:'0 5px'}}>{n.badge}</span>
      )}
    </button>
  )

  return (
    <div style={{
      width: collapsed ? 68 : 224,
      background:'var(--bgE)', borderRight:'1px solid var(--hair)',
      display:'flex', flexDirection:'column', flexShrink:0,
      transition:'width .22s cubic-bezier(.4,0,.2,1)',
      overflow:'hidden',
    }}>
      {/* Brand */}
      <div style={{display:'flex',alignItems:'center',gap:10,padding:'14px 14px',borderBottom:'1px solid var(--hair)',marginBottom:6,flexShrink:0}}>
        <div style={{width:38,height:38,borderRadius:11,background:'var(--inv)',color:'var(--invT)',display:'grid',placeItems:'center',flexShrink:0}}>
          <Brand s={22}/>
        </div>
        {showLabel && (
          <div style={{minWidth:0,overflow:'hidden'}}>
            <div style={{fontSize:15,fontWeight:700,letterSpacing:'-.02em',color:'var(--txt)',whiteSpace:'nowrap'}}>Shina24</div>
            <div style={{fontSize:11,color:'var(--txt3)',fontWeight:500}}>Панель администратора</div>
          </div>
        )}
      </div>

      {showLabel && (
        <div style={{fontSize:10,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)',padding:'10px 18px 4px'}}>Основное</div>
      )}
      {!showLabel && <div style={{height:6}}/>}
      {NAV.filter(n=>n.group===0).map(navBtn)}

      {showLabel
        ? <div style={{fontSize:10,fontWeight:700,textTransform:'uppercase',letterSpacing:'.08em',color:'var(--txt3)',padding:'10px 18px 4px'}}>Управление</div>
        : <div style={{height:10,borderTop:'1px solid var(--hair)',margin:'6px 10px'}}/>
      }
      {NAV.filter(n=>n.group===1).map(navBtn)}

      <div style={{flex:1}}/>

      <div style={{padding:'8px',borderTop:'1px solid var(--hair)'}}>
        <button onClick={toggleTheme}
          style={{display:'flex',alignItems:'center',justifyContent:showLabel?'flex-start':'center',gap:showLabel?10:0,padding:showLabel?'9px 12px':'10px 0',width:'100%',borderRadius:11,fontSize:13.5,fontWeight:500,color:'var(--txt2)',cursor:'pointer',border:'none',background:'none'}}>
          <Icon n={theme==='dark'?'sun':'moon'} s={17}/>
          {showLabel && (theme==='dark' ? 'Светлая тема' : 'Тёмная тема')}
        </button>
        <button onClick={logout}
          style={{display:'flex',alignItems:'center',justifyContent:showLabel?'flex-start':'center',gap:showLabel?10:0,padding:showLabel?'9px 12px':'10px 0',width:'100%',borderRadius:11,fontSize:13.5,fontWeight:500,color:'var(--red)',cursor:'pointer',border:'none',background:'none'}}>
          <Icon n="logout" s={17} col="var(--red)"/>
          {showLabel && 'Выйти'}
        </button>
        <button onClick={onToggleCollapse}
          style={{display:'flex',alignItems:'center',justifyContent:collapsed?'center':'flex-start',gap:collapsed?0:10,padding:collapsed?'10px 0':'9px 12px',width:'100%',borderRadius:11,fontSize:13.5,fontWeight:500,color:'var(--txt3)',cursor:'pointer',border:'none',background:'none'}}>
          <Icon n={collapsed?'chevR':'chevL'} s={17}/>
          {!collapsed && 'Свернуть'}
        </button>
      </div>
    </div>
  )
}
