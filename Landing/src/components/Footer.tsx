'use client'

import Image from 'next/image'
import { useI18n } from '@/lib/i18n'

export default function Footer() {
  const { t } = useI18n()
  return (
    <footer className="border-t border-white/[.08] py-10 px-5 sm:px-8">
      <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-5">
        <div className="flex items-center gap-2.5">
          <Image src="/brand/shina24-mark-white.png" alt="Shina24" width={22} height={22} />
          <span className="text-[14px] font-bold">Shina24</span>
        </div>
        <p className="text-[12.5px] text-txt3 text-center order-last sm:order-none">
          © {new Date().getFullYear()} Shina24. {t.footer.rights}
        </p>
        <div className="flex items-center gap-5 text-[12.5px] text-txt2">
          <a href="#how-it-works" className="hover:text-txt transition-colors">
            {t.footer.howItWorks}
          </a>
          <a href="#download" className="hover:text-txt transition-colors">
            {t.footer.download}
          </a>
        </div>
      </div>
    </footer>
  )
}
