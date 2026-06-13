'use client'
export default function Toggle({ on, onChange }: { on: boolean; onChange?: (v: boolean) => void }) {
  return (
    <button
      className="tgl"
      onClick={() => onChange?.(!on)}
      style={{ background: on ? 'var(--green)' : 'var(--surf3)' }}
    >
      <div className="tgl-k" style={{ transform: on ? 'translateX(18px)' : 'none' }} />
    </button>
  )
}
