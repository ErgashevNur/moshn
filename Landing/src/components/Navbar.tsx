'use client'

import Image from 'next/image'
import { useEffect, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import Icon from './Icon'
import { useI18n } from '@/lib/i18n'

export default function Navbar() {
  const { t } = useI18n()
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

  const links = [
    { href: '#how-it-works', label: t.nav.howItWorks },
    { href: '#benefits', label: t.nav.benefits },
    { href: '#clients', label: t.nav.forClients },
    { href: '#services', label: t.nav.forServices },
    { href: '#download', label: t.nav.download },
  ]

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12)
    onScroll()
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  // Lock body scroll while the mobile menu is open.
  useEffect(() => {
    document.body.style.overflow = menuOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [menuOpen])

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled || menuOpen ? 'bg-bg/80 backdrop-blur-md border-b border-white/[.08]' : 'bg-transparent'
      }`}
    >
      <nav className="max-w-6xl mx-auto flex items-center justify-between px-5 sm:px-8 h-16">
        <a href="#" className="flex items-center gap-2.5" onClick={() => setMenuOpen(false)}>
          <Image src="/brand/shina24-mark-white.png" alt="Shina24" width={28} height={28} />
          <span className="text-[17px] font-bold tracking-tight">Shina24</span>
        </a>

        <div className="hidden md:flex items-center gap-7">
          {links.map((l) => (
            <a key={l.href} href={l.href} className="text-[13.5px] font-medium text-txt2 hover:text-txt transition-colors">
              {l.label}
            </a>
          ))}
        </div>

        <div className="flex items-center gap-2 sm:gap-3">
          <a
            href="#download"
            className="hidden sm:flex items-center gap-1.5 h-10 px-4 rounded-full bg-gold text-bg text-[13.5px] font-semibold hover:brightness-110 transition-all"
          >
            {t.nav.downloadApp}
          </a>
          <button
            type="button"
            onClick={() => setMenuOpen((v) => !v)}
            aria-label="Menu"
            aria-expanded={menuOpen}
            className="md:hidden flex items-center justify-center w-10 h-10 rounded-full border border-white/[.12] text-txt"
          >
            <Icon name={menuOpen ? 'close' : 'menu'} size={20} />
          </button>
        </div>
      </nav>

      <AnimatePresence>
        {menuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] }}
            className="md:hidden overflow-hidden border-t border-white/[.08] bg-bg/95 backdrop-blur-md"
          >
            <div className="px-5 py-4 flex flex-col">
              {links.map((l, i) => (
                <motion.a
                  key={l.href}
                  href={l.href}
                  onClick={() => setMenuOpen(false)}
                  initial={{ opacity: 0, x: -12 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.04 * i + 0.05, duration: 0.25 }}
                  className="py-3 text-[15px] font-medium text-txt2 hover:text-txt border-b border-white/[.05] last:border-0"
                >
                  {l.label}
                </motion.a>
              ))}
              <a
                href="#download"
                onClick={() => setMenuOpen(false)}
                className="mt-4 flex items-center justify-center gap-2 h-12 rounded-full bg-gold text-bg text-[14.5px] font-semibold"
              >
                <Icon name="download" size={18} />
                {t.nav.downloadApp}
              </a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  )
}
