'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import Icon from './Icon'
import { useI18n } from '@/lib/i18n'

export default function Benefits() {
  const { t } = useI18n()
  const [tab, setTab] = useState<'clients' | 'services'>('clients')
  const tabs = [
    { key: 'clients' as const, label: t.benefits.tabClients },
    { key: 'services' as const, label: t.benefits.tabServices },
  ]
  const items = tab === 'clients' ? t.benefits.clients : t.benefits.services

  return (
    <section id="benefits" className="relative py-20 sm:py-24 px-5 sm:px-8 bg-bgE overflow-hidden">
      <div
        className="absolute inset-0 pointer-events-none opacity-60"
        style={{ background: 'radial-gradient(45% 35% at 15% 0%, rgba(212,168,67,.08), transparent 70%)' }}
      />
      <span id="clients" className="absolute -top-16" />
      <span id="services" className="absolute -top-16" />
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-9 sm:mb-10">
          <span className="text-gold text-[12.5px] font-bold uppercase tracking-[.08em]">{t.benefits.eyebrow}</span>
          <h2 className="text-[26px] sm:text-[36px] font-extrabold mt-3 tracking-tight">{t.benefits.title}</h2>
        </div>

        <div className="flex justify-center mb-9 sm:mb-10">
          <div className="flex bg-surf rounded-full p-1.5 border border-white/[.08] w-full max-w-[360px] sm:w-auto">
            {tabs.map((tb) => (
              <button
                key={tb.key}
                onClick={() => setTab(tb.key)}
                className={`flex-1 sm:flex-none px-4 sm:px-6 h-10 rounded-full text-[13px] sm:text-[13.5px] font-semibold transition-all ${
                  tab === tb.key ? 'bg-gold text-bg' : 'text-txt2 hover:text-txt'
                }`}
              >
                {tb.label}
              </button>
            ))}
          </div>
        </div>

        <AnimatePresence mode="wait">
          <motion.div
            key={tab}
            initial={{ opacity: 0, y: 14 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -14 }}
            transition={{ duration: 0.35, ease: [0.16, 1, 0.3, 1] }}
            className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5"
          >
            {items.map((item, i) => (
              <motion.div
                key={item.title}
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.06, duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
                className="bg-white/[.03] backdrop-blur-sm border border-white/[.08] rounded-2xl p-5 sm:p-6 transition-all hover:border-gold/30 hover:bg-white/[.05] hover:shadow-[0_0_30px_rgba(212,168,67,.10)]"
              >
                <div className="w-11 h-11 rounded-xl bg-goldDim flex items-center justify-center text-gold mb-4">
                  <Icon name={item.icon} size={22} />
                </div>
                <h3 className="text-[15.5px] font-bold mb-2">{item.title}</h3>
                <p className="text-[13.5px] text-txt2 leading-relaxed">{item.desc}</p>
              </motion.div>
            ))}
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
