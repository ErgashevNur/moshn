'use client'

import { motion } from 'framer-motion'

const APK_URL = process.env.NEXT_PUBLIC_APK_URL || 'https://shina24.uz/media/shina24-v1.1.0.apk'

export default function DownloadCTA() {
  return (
    <section id="yuklab-olish" className="py-24 px-5 sm:px-8 section-glow">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-60px' }}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="max-w-3xl mx-auto text-center bg-white/[.03] backdrop-blur-xl border border-white/[.08] rounded-3xl px-6 sm:px-12 py-12 sm:py-16 shadow-[0_0_60px_rgba(212,168,67,.06)]"
      >
        <h2 className="text-[28px] sm:text-[38px] font-extrabold tracking-tight mb-4">
          Shina24&apos;ni hoziroq <span className="text-gold">yuklab oling</span>
        </h2>
        <p className="text-[15px] sm:text-[16px] text-txt2 leading-relaxed mb-9 max-w-lg mx-auto">
          Mijoz sifatida bron qiling yoki shinomontaj sifatida o‘z servisingizni ro‘yxatga oling — bitta ilovada ikki rol.
        </p>
        <div className="flex flex-wrap items-center justify-center gap-4">
          <a
            href={APK_URL}
            className="h-[54px] px-8 rounded-full bg-gold text-bg font-bold text-[15px] flex items-center gap-2.5 hover:brightness-110 transition-all"
          >
            ⬇ Android uchun yuklab olish (APK)
          </a>
        </div>
        <p className="text-[12px] text-txt3 mt-5">iOS versiyasi tez kunda. So‘rovlar uchun: support@shina24.uz</p>
      </motion.div>
    </section>
  )
}
