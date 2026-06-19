'use client'

import Image from 'next/image'
import { useEffect, useState } from 'react'

const LINKS = [
  { href: '#xizmat-yoli', label: 'Qanday ishlaydi' },
  { href: '#afzalliklar', label: 'Afzalliklar' },
  { href: '#mijoz', label: 'Mijozlar uchun' },
  { href: '#servis', label: 'Servislar uchun' },
  { href: '#yuklab-olish', label: 'Yuklab olish' },
]

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12)
    onScroll()
    window.addEventListener('scroll', onScroll)
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled ? 'bg-bg/80 backdrop-blur-md border-b border-white/[.08]' : 'bg-transparent'
      }`}
    >
      <nav className="max-w-6xl mx-auto flex items-center justify-between px-5 sm:px-8 h-16">
        <a href="#" className="flex items-center gap-2.5">
          <Image src="/brand/shina24-mark-white.png" alt="Shina24" width={28} height={28} />
          <span className="text-[17px] font-bold tracking-tight">Shina24</span>
        </a>

        <div className="hidden md:flex items-center gap-7">
          {LINKS.map((l) => (
            <a key={l.href} href={l.href} className="text-[13.5px] font-medium text-txt2 hover:text-txt transition-colors">
              {l.label}
            </a>
          ))}
        </div>

        <a
          href="#yuklab-olish"
          className="flex items-center gap-1.5 h-10 px-4 rounded-full bg-gold text-bg text-[13.5px] font-semibold hover:brightness-110 transition-all"
        >
          Ilovani yuklash
        </a>
      </nav>
    </header>
  )
}
