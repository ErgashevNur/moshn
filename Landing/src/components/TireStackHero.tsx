'use client'

import { motion, useScroll, useTransform } from 'framer-motion'

const APK_URL = process.env.NEXT_PUBLIC_APK_URL || 'https://shina24.uz/media/shina24-v1.1.0.apk'

export default function TireStackHero() {
  const { scrollY } = useScroll()
  const videoY = useTransform(scrollY, [0, 900], [0, 180])

  return (
    <div className="relative h-screen w-full overflow-hidden">
      {/* garage backdrop: looping neon-sign render, drifts down as you scroll */}
      <motion.video
        className="absolute inset-0 w-full h-full object-cover"
        style={{ transform: 'scale(1.18)', y: videoY }}
        src="/videos/garage-neon.mp4"
        poster="/images/garage-poster.png"
        autoPlay
        muted
        loop
        playsInline
      />
      <div
        className="absolute inset-0"
        style={{ background: 'radial-gradient(70% 60% at 50% 38%, rgba(8,7,6,.35), rgba(6,5,4,.82) 100%)' }}
      />

      <div className="absolute inset-0 flex flex-col items-center justify-center px-6">
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
          className="relative z-10 text-center"
        >
          <h1 className="text-[30px] sm:text-[44px] md:text-[52px] font-extrabold leading-[1.08] tracking-tight mb-4">
            Eng yaqin shinomontajni <span className="text-gold">bir necha bosishda</span> toping
          </h1>
          <p className="text-[15px] sm:text-[17px] text-txt2 leading-relaxed mb-7 max-w-md mx-auto">
            Shina24 — mijoz va shinomontaj servislarini bog‘laydigan platforma.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-3">
            <a
              href={APK_URL}
              className="h-[50px] px-7 rounded-full bg-gold text-bg font-semibold text-[15px] flex items-center hover:brightness-110 transition-all"
            >
              Ilovani yuklab olish
            </a>
            <a
              href="#xizmat-yoli"
              className="h-[50px] px-7 rounded-full border border-white/[.14] text-txt font-semibold text-[15px] flex items-center hover:bg-white/[.05] transition-all"
            >
              Qanday ishlaydi?
            </a>
          </div>
        </motion.div>
      </div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.1, duration: 0.6 }}
        className="absolute bottom-6 inset-x-0 flex flex-col items-center gap-2"
      >
        <span className="text-[11px] uppercase tracking-[.18em] text-txt3">Pastga aylantiring</span>
        <div className="w-[1px] h-8 bg-gradient-to-b from-txt3 to-transparent" />
      </motion.div>
    </div>
  )
}
