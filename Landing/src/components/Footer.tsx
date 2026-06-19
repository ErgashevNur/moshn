import Image from 'next/image'

export default function Footer() {
  return (
    <footer className="border-t border-white/[.08] py-10 px-5 sm:px-8">
      <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-5">
        <div className="flex items-center gap-2.5">
          <Image src="/brand/shina24-mark-white.png" alt="Shina24" width={22} height={22} />
          <span className="text-[14px] font-bold">Shina24</span>
        </div>
        <p className="text-[12.5px] text-txt3 text-center">
          © {new Date().getFullYear()} Shina24. Barcha huquqlar himoyalangan.
        </p>
        <div className="flex items-center gap-5 text-[12.5px] text-txt2">
          <a href="#qanday-ishlaydi" className="hover:text-txt transition-colors">Qanday ishlaydi</a>
          <a href="#yuklab-olish" className="hover:text-txt transition-colors">Yuklab olish</a>
        </div>
      </div>
    </footer>
  )
}
