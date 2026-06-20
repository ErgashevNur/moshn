'use client'

import { useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import Icon from './Icon'
import { LANGS, useI18n } from '@/lib/i18n'

export default function LangSelect({ className = '' }: { className?: string }) {
  const { lang, setLang } = useI18n()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  const current = LANGS.find((l) => l.code === lang)!

  useEffect(() => {
    const onDoc = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onDoc)
    return () => document.removeEventListener('mousedown', onDoc)
  }, [])

  return (
    <div ref={ref} className={`relative ${className}`}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label="Til / Язык"
        className="flex items-center gap-1.5 h-9 px-2.5 rounded-full border border-white/[.12] text-txt2 hover:text-txt hover:border-white/25 transition-colors"
      >
        <Icon name="globe" size={16} />
        <span className="text-[12.5px] font-semibold">{current.short}</span>
        <motion.span animate={{ rotate: open ? 180 : 0 }} transition={{ duration: 0.2 }} className="flex">
          <Icon name="chevronDown" size={14} />
        </motion.span>
      </button>

      <AnimatePresence>
        {open && (
          <motion.ul
            role="listbox"
            initial={{ opacity: 0, y: -6, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -6, scale: 0.97 }}
            transition={{ duration: 0.16, ease: [0.16, 1, 0.3, 1] }}
            className="absolute right-0 mt-2 min-w-[150px] rounded-xl bg-bgE/95 backdrop-blur-md border border-white/[.10] p-1.5 shadow-[0_12px_40px_rgba(0,0,0,.5)] z-50"
          >
            {LANGS.map((l) => (
              <li key={l.code}>
                <button
                  type="button"
                  role="option"
                  aria-selected={l.code === lang}
                  onClick={() => {
                    setLang(l.code)
                    setOpen(false)
                  }}
                  className={`w-full flex items-center justify-between gap-3 px-3 h-9 rounded-lg text-[13px] font-medium transition-colors ${
                    l.code === lang ? 'bg-gold/15 text-gold' : 'text-txt2 hover:bg-white/[.06] hover:text-txt'
                  }`}
                >
                  <span>{l.label}</span>
                  <span className="text-[11px] font-semibold opacity-70">{l.short}</span>
                </button>
              </li>
            ))}
          </motion.ul>
        )}
      </AnimatePresence>
    </div>
  )
}
