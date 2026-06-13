'use client'
export default function Plate({ v, lg }: { v: string; lg?: boolean }) {
  return (
    <span style={{
      fontFamily: "'JetBrains Mono',monospace",
      display: 'inline-flex', alignItems: 'center',
      padding: lg ? '6px 12px' : '2px 8px',
      borderRadius: 7, background: '#f4f4f2', color: '#111',
      fontSize: lg ? 15 : 12, fontWeight: 700,
      letterSpacing: '.04em',
      border: '1px solid rgba(0,0,0,.18)',
      boxShadow: 'inset 0 0 0 2px #fff,0 1px 2px rgba(0,0,0,.18)',
      whiteSpace: 'nowrap',
    }}>{v}</span>
  )
}
