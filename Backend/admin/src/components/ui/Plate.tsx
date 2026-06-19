'use client'
import React from 'react'

function isDigit(c: string) {
  const code = c.charCodeAt(0)
  return code >= 48 && code <= 57
}

// "01A123EA" → { region:"01", main:"A 123 EA" }
function splitUz(raw: string) {
  if (raw.length < 2) return { region: raw, main: '' }
  const region = raw.slice(0, 2)
  const rest = raw.slice(2)
  if (!rest) return { region, main: '' }

  let i = 0, buf = ''

  while (i < rest.length && !isDigit(rest[i]) && i < 3) buf += rest[i++]
  if (i < rest.length) {
    buf += ' '
    let dc = 0
    while (i < rest.length && isDigit(rest[i]) && dc < 3) { buf += rest[i++]; dc++ }
  }
  if (i < rest.length) buf += ' ' + rest.slice(i)

  return { region, main: buf.trim() }
}

// "A000AA77" → { main:"A 000 AA", region:"77" }
function splitRu(raw: string) {
  let i = 0, main = ''

  if (i < raw.length && !isDigit(raw[i])) main += raw[i++]
  if (i < raw.length) {
    main += ' '
    let dc = 0
    while (i < raw.length && isDigit(raw[i]) && dc < 3) { main += raw[i++]; dc++ }
  }
  if (i < raw.length && !isDigit(raw[i])) {
    main += ' '
    let lc = 0
    while (i < raw.length && !isDigit(raw[i]) && lc < 2) { main += raw[i++]; lc++ }
  }

  return { main: main.trim(), region: raw.slice(i) }
}

export default function Plate({ v, lg, sm }: { v: string; lg?: boolean; sm?: boolean }) {
  if (!v || v === '—') {
    return <span style={{ color: 'var(--txt3)', fontSize: lg ? 15 : 12 }}>—</span>
  }

  const raw = v.toUpperCase().replace(/\s+/g, '')
  const h       = lg ? 52 : sm ? 26 : 36
  const mainFz  = lg ? 17 : sm ? 10 : 12
  const bw      = lg ? 2  : 1.5
  const r       = lg ? 8  : sm ? 5  : 6
  const mono    = "'JetBrains Mono', monospace"

  const wrap: React.CSSProperties = {
    display: 'inline-flex', alignItems: 'stretch',
    height: h, borderRadius: r,
    border: `${bw}px solid #111`,
    background: '#fff',
    boxShadow: '0 2px 8px rgba(0,0,0,.15)',
    overflow: 'hidden', whiteSpace: 'nowrap',
  }

  const txt: React.CSSProperties = {
    fontFamily: mono, fontSize: mainFz,
    fontWeight: 800, color: '#0d0d0d',
    letterSpacing: '0.12em', lineHeight: 1,
  }

  if (isDigit(raw[0])) {
    // ── O'ZBEKISTON ──────────────────────────────
    const { region, main } = splitUz(raw)
    const flagW = lg ? 22 : sm ? 11 : 15
    const flagH = lg ? 5  : sm ? 2.5 : 3.5
    const sep   = lg ? 1.5 : 1

    return (
      <span style={wrap}>
        {/* Chap: dot + hudud kodi */}
        <span style={{ display:'inline-flex', alignItems:'center', gap: lg?5:sm?3:4, padding: lg?'0 10px':sm?'0 5px':'0 7px', background:'#fff' }}>
          <span style={{ width: lg?6:sm?3:4, height: lg?6:sm?3:4, borderRadius:'50%', background:'#555', flexShrink:0 }} />
          <span style={{ ...txt, fontSize: lg?16:sm?10:12 }}>{region || '01'}</span>
        </span>

        {/* Qalin vertikal ajratgich */}
        <span style={{ width: lg?3:sm?1.5:2, background:'#111', flexShrink:0 }} />

        {/* Asosiy matn */}
        <span style={{ display:'inline-flex', alignItems:'center', padding: lg?'0 14px':sm?'0 6px':'0 9px' }}>
          <span style={txt}>{main || 'A 123 EA'}</span>
        </span>

        {/* Ingichka separator */}
        <span style={{ width:1, background:'#ddd', flexShrink:0 }} />

        {/* UZ badge */}
        <span style={{ display:'inline-flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap: lg?3:sm?1.5:2, padding: lg?'0 10px':sm?'0 4px':'0 6px', background:'#fff' }}>
          <span style={{ display:'flex', flexDirection:'column', borderRadius:2, overflow:'hidden', width: flagW }}>
            <span style={{ height:flagH, background:'#1DAADF' }} />
            <span style={{ height:sep,   background:'#fff'    }} />
            <span style={{ height:flagH, background:'#1DB55E' }} />
          </span>
          <span style={{ fontFamily:mono, fontSize: lg?9:sm?6:7, fontWeight:900, color:'#0d0d0d', letterSpacing:'0.1em' }}>UZ</span>
        </span>
      </span>
    )
  }

  // ── ROSSIYA ──────────────────────────────────
  const { main, region: reg } = splitRu(raw)
  const flagW = lg ? 22 : sm ? 11 : 15
  const bandH = lg ? 4  : sm ? 2  : 3

  return (
    <span style={wrap}>
      {/* Asosiy matn */}
      <span style={{ display:'inline-flex', alignItems:'center', padding: lg?'0 16px':sm?'0 7px':'0 10px' }}>
        <span style={txt}>{main || raw}</span>
      </span>

      {/* Ingichka separator */}
      <span style={{ width:1, background:'#ddd', flexShrink:0 }} />

      {/* RUS badge */}
      <span style={{ display:'inline-flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap: lg?2:1.5, padding: lg?'0 10px':sm?'0 4px':'0 6px', background:'#fff' }}>
        <span style={{ display:'flex', flexDirection:'column', borderRadius:2, overflow:'hidden', width: flagW }}>
          <span style={{ height:bandH, background:'#fff',    outline:'0.5px solid #ddd' }} />
          <span style={{ height:bandH, background:'#0039A6' }} />
          <span style={{ height:bandH, background:'#D52B1E' }} />
        </span>
        <span style={{ fontFamily:mono, fontSize: lg?9:sm?6:7, fontWeight:900, color:'#0d0d0d', letterSpacing:'0.1em' }}>RUS</span>
        {reg && <span style={{ fontFamily:mono, fontSize: lg?10:sm?7:8, fontWeight:700, color:'#0d0d0d' }}>{reg}</span>}
      </span>
    </span>
  )
}
