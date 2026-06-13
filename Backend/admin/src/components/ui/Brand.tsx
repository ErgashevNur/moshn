'use client'
export default function Brand({ s = 26 }: { s?: number }) {
  return (
    <svg width={s} height={s} viewBox="0 0 48 48" fill="none">
      <circle cx="24" cy="24" r="21" stroke="currentColor" strokeWidth="2.4"/>
      <circle cx="24" cy="24" r="8" stroke="currentColor" strokeWidth="2.4"/>
      <g stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
        <path d="M24 3v8M24 37v8M3 24h8M37 24h8"/>
      </g>
    </svg>
  )
}
