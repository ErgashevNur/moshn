'use client'

import { motion } from 'framer-motion'
import Icon from './Icon'
import { useI18n } from '@/lib/i18n'

const APK_URL = process.env.NEXT_PUBLIC_APK_URL || 'https://shina24.uz/media/shina24-v1.1.0.apk'

export default function DownloadCTA() {
  const { t } = useI18n()
  return (
    <section id="download" className="py-20 sm:py-24 px-5 sm:px-8 section-glow">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-60px' }}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="max-w-3xl mx-auto text-center bg-white/[.03] backdrop-blur-xl border border-white/[.08] rounded-3xl px-5 sm:px-12 py-11 sm:py-16 shadow-[0_0_60px_rgba(212,168,67,.06)]"
      >
        <h2 className="text-[26px] sm:text-[38px] font-extrabold tracking-tight mb-4">
          {t.cta.titlePre} <span className="text-gold">{t.cta.titleHi}</span>
        </h2>
        <p className="text-[14.5px] sm:text-[16px] text-txt2 leading-relaxed mb-9 max-w-lg mx-auto">{t.cta.desc}</p>
        <div className="flex flex-wrap items-center justify-center gap-4">
          <a
            href={APK_URL}
            className="h-[54px] w-full sm:w-auto px-8 rounded-full bg-gold text-bg font-bold text-[14.5px] sm:text-[15px] flex items-center justify-center gap-2.5 hover:brightness-110 transition-all"
          >
            <Icon name="download" size={20} />
            {t.cta.btn}
          </a>
        </div>
        <p className="text-[12px] text-txt3 mt-5">{t.cta.note}</p>
      </motion.div>
    </section>
  )
}
