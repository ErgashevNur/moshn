'use client'
import { useState } from 'react'
import Icon from './Icon'

interface StarsProps {
  v?: number
  sz?: number
  interactive?: boolean
  onChange?: (v: number) => void
}

export default function Stars({ v = 0, sz = 14, interactive, onChange }: StarsProps) {
  const [hov, setH] = useState(0)
  const eff = interactive ? (hov || v) : v
  return (
    <div style={{ display: 'flex', gap: 2 }}>
      {[1,2,3,4,5].map(i => (
        <button
          key={i}
          onClick={() => interactive && onChange?.(i)}
          onMouseEnter={() => interactive && setH(i)}
          onMouseLeave={() => interactive && setH(0)}
          style={{
            color: eff >= i ? 'var(--gold)' : 'var(--txt3)',
            lineHeight: 0, background: 'none', border: 'none',
            cursor: interactive ? 'pointer' : 'default',
          }}
        >
          <Icon n={eff >= i ? 'starF' : 'star'} s={sz} st={1.5} />
        </button>
      ))}
    </div>
  )
}
