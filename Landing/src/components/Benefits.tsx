'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

const TABS = [
  {
    key: 'mijoz',
    id: 'mijoz',
    label: 'Mijozlar uchun',
    items: [
      ['🚗', 'Avtomobil ro‘yxati', 'Plaka raqami va foto bilan avtomobilingizni saqlang — har safar qayta kiritmang.'],
      ['📍', 'Yaqin servislar', 'Geolokatsiya bo‘yicha eng yaqin va mos shinomontajlarni darhol ko‘rasiz.'],
      ['🔔', 'Mavsum eslatmasi', 'Qish/yoz fasli kelganda shina almashtirish vaqti haqida push-bildirishnoma olasiz.'],
      ['💳', 'Keyinroq to‘lash', 'Xizmatni hozir oling, to‘lovni keyinroq amalga oshiring.'],
      ['⭐', 'Chayivoye (tip)', 'Xizmatdan mamnun bo‘lsangiz, ustaga to‘g‘ridan-to‘g‘ri tip qoldirasiz.'],
    ],
  },
  {
    key: 'servis',
    id: 'servis',
    label: 'Servislar uchun',
    items: [
      ['📋', 'Real-vaqt bronlar', 'Planshet/telefonga yangi bron, bekor qilish — barchasi jonli bildirishnoma orqali keladi.'],
      ['💰', 'Planshetda to‘lov', 'QR kod yoki karta orqali to‘lovni qabul qilasiz — terminal kabi qulay.'],
      ['👥', 'Mijozlar CRM bazasi', 'Telefon, ism, avtomobil, VIP belgisi va tashrif tarixi — barchasi bir joyda.'],
      ['📊', 'Statistika', 'Bugun/hafta/oy bo‘yicha bronlar va daromad statistikasini kuzatib borasiz.'],
      ['⭐', 'Ikki tomonlama baho', 'Siz ham mijozni baholaysiz — ishonchli va sifatli mijozlar bazasi shakllanadi.'],
    ],
  },
] as const

export default function Benefits() {
  const [tab, setTab] = useState<'mijoz' | 'servis'>('mijoz')
  const active = TABS.find((t) => t.key === tab)!

  return (
    <section id="afzalliklar" className="relative py-24 px-5 sm:px-8 bg-bgE overflow-hidden">
      <div
        className="absolute inset-0 pointer-events-none opacity-60"
        style={{ background: 'radial-gradient(45% 35% at 15% 0%, rgba(212,168,67,.08), transparent 70%)' }}
      />
      <span id="mijoz" className="absolute -top-16" />
      <span id="servis" className="absolute -top-16" />
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-10">
          <span className="text-gold text-[12.5px] font-bold uppercase tracking-[.08em]">Afzalliklar</span>
          <h2 className="text-[28px] sm:text-[36px] font-extrabold mt-3 tracking-tight">Har ikki tomon uchun qulay</h2>
        </div>

        <div className="flex justify-center mb-10">
          <div className="flex bg-surf rounded-full p-1.5 border border-white/[.08]">
            {TABS.map((t) => (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={`px-5 sm:px-6 h-10 rounded-full text-[13.5px] font-semibold transition-all ${
                  tab === t.key ? 'bg-gold text-bg' : 'text-txt2 hover:text-txt'
                }`}
              >
                {t.label}
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
            className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5"
          >
            {active.items.map(([icon, title, desc]) => (
              <div
                key={title}
                className="bg-white/[.03] backdrop-blur-sm border border-white/[.08] rounded-2xl p-6 transition-all hover:border-gold/30 hover:bg-white/[.05] hover:shadow-[0_0_30px_rgba(212,168,67,.10)]"
              >
                <div className="w-11 h-11 rounded-xl bg-goldDim flex items-center justify-center text-[20px] mb-4">{icon}</div>
                <h3 className="text-[15.5px] font-bold mb-2">{title}</h3>
                <p className="text-[13.5px] text-txt2 leading-relaxed">{desc}</p>
              </div>
            ))}
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
