'use client'
import React from 'react'

type IconName =
  | 'dash' | 'store' | 'list' | 'users' | 'wallet' | 'bolt' | 'bell'
  | 'settings' | 'sun' | 'moon' | 'logout' | 'search' | 'check' | 'x'
  | 'crown' | 'pin' | 'star' | 'starF' | 'trend' | 'send' | 'snow'
  | 'chevD' | 'chevR' | 'edit' | 'plus' | 'ban' | 'refresh' | 'cal'
  | 'car' | 'nfc' | 'qr' | 'phone' | 'card' | 'chart' | 'clock' | 'disc'
  | 'menu' | 'chevL'

interface IconProps {
  n: IconName
  s?: number
  st?: number
  col?: string
  style?: React.CSSProperties
}

export default function Icon({ n, s = 18, st = 1.8, col, style }: IconProps) {
  const pp = {
    width: s, height: s, viewBox: '0 0 24 24', fill: 'none',
    stroke: col || 'currentColor', strokeWidth: st,
    strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const, style,
  }
  const paths: Record<IconName, React.ReactNode> = {
    dash: <><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></>,
    store: <><path d="M3 6.2V18a1 1 0 001 1h16a1 1 0 001-1V6.2"/><path d="M2 4h20v2.5a2 2 0 01-2 2H4a2 2 0 01-2-2V4z"/><path d="M9 19v-6a1 1 0 011-1h4a1 1 0 011 1v6"/></>,
    list: <><path d="M8 6h12M8 12h12M8 18h12"/><circle cx="4" cy="6" r="1"/><circle cx="4" cy="12" r="1"/><circle cx="4" cy="18" r="1"/></>,
    users: <><circle cx="9" cy="7" r="4"/><path d="M3 21v-2a4 4 0 014-4h4a4 4 0 014 4v2"/><path d="M16 3.1a4 4 0 010 7.8M22 21v-2a4 4 0 00-3-3.87"/></>,
    wallet: <><rect x="3" y="6" width="18" height="13" rx="3"/><path d="M3 10h18M16 14h2"/></>,
    bolt: <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>,
    bell: <><path d="M18 9a6 6 0 10-12 0c0 6-2.5 7-2.5 7h17S18 15 18 9z"/><path d="M10.5 20a2 2 0 003 0"/></>,
    settings: <><circle cx="12" cy="12" r="3"/><path d="M12 2v2M12 20v2M4.2 4.2l1.4 1.4M17 17l1.4 1.4M2 12h2M20 12h2M4.2 19.8l1.4-1.4M17 7l1.4-1.4"/></>,
    sun: <><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19"/></>,
    moon: <path d="M20 14a8 8 0 11-10-10 6.5 6.5 0 0010 10z"/>,
    logout: <><path d="M10 4H6a1 1 0 00-1 1v14a1 1 0 001 1h4"/><path d="M14 12h7m0 0l-3.5-3.5M21 12l-3.5 3.5"/></>,
    search: <><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></>,
    check: <path d="M5 12.5l4.5 4.5L19 6.5"/>,
    x: <path d="M6 6l12 12M18 6L6 18"/>,
    crown: <path d="M4 18h16M4 18l-1.5-9 5 4 4.5-7 4.5 7 5-4L20 18"/>,
    pin: <><path d="M12 21s7-5.5 7-11a7 7 0 10-14 0c0 5.5 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/></>,
    star: <path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z"/>,
    starF: <path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z" fill="currentColor" stroke="none"/>,
    trend: <><path d="M22 7l-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/></>,
    send: <path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z"/>,
    snow: <><path d="M12 3v18M5 7.5l14 9M19 7.5l-14 9"/></>,
    chevD: <path d="M5 9l7 7 7-7"/>,
    chevR: <path d="M9 5l7 7-7 7"/>,
    edit: <><path d="M17 3a2.83 2.83 0 114 4L7.5 20.5l-5 1 1-5z"/></>,
    plus: <><path d="M12 5v14M5 12h14"/></>,
    ban: <><circle cx="12" cy="12" r="9"/><path d="M4.9 4.9l14.2 14.2"/></>,
    refresh: <><path d="M23 4v6h-6"/><path d="M20.5 15a9 9 0 11-2.1-9.4L23 10"/></>,
    cal: <><rect x="3.5" y="5" width="17" height="16" rx="3"/><path d="M3.5 9.5h17M8 3v4M16 3v4"/></>,
    car: <><path d="M5 11l1.6-4.2A2 2 0 018.5 5.5h7a2 2 0 011.9 1.3L19 11"/><path d="M4 11h16a1 1 0 011 1v4a1 1 0 01-1 1h-1v1.5a1 1 0 01-1 1h-1a1 1 0 01-1-1V17H9v1.5a1 1 0 01-1 1H7a1 1 0 01-1-1V17H5a1 1 0 01-1-1v-4a1 1 0 011-1z"/></>,
    nfc: <><path d="M20 12a8 8 0 00-8-8"/><path d="M16 12a4 4 0 00-4-4"/><path d="M12 12h.01"/><path d="M4 12a8 8 0 008 8"/></>,
    qr: <><rect x="4" y="4" width="6" height="6" rx="1"/><rect x="14" y="4" width="6" height="6" rx="1"/><rect x="4" y="14" width="6" height="6" rx="1"/><path d="M14 14h2v2M20 14v6M16 18v2h4"/></>,
    phone: <path d="M5 3.5h3l1.5 4-2 1.4a12 12 0 005.6 5.6l1.4-2 4 1.5v3a2 2 0 01-2 2A16 16 0 013 5.5a2 2 0 012-2z"/>,
    card: <><rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M2.5 9.5h19"/></>,
    chart: <><path d="M18 20V10M12 20V4M6 20v-6"/></>,
    clock: <><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></>,
    disc: <><circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="3"/></>,
    menu: <><path d="M3 6h18M3 12h18M3 18h18"/></>,
    chevL: <path d="M15 19l-7-7 7-7"/>,
  }
  return <svg {...pp}>{paths[n] ?? null}</svg>
}
