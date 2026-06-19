'use client'

import { useEffect, useRef, useState } from 'react'
import { motion, useAnimationFrame, useMotionValue, useScroll, useTransform, type MotionValue } from 'framer-motion'
import WheelImage from './WheelImage'

const APK_URL = process.env.NEXT_PUBLIC_APK_URL || 'https://shina24.uz/media/shina24-v1.1.0.apk'

const VB_W = 100
const VB_H = 300
const WHEEL_SIZE = 104
const SPIN_PER_UNIT = 2.1

const SEG = [
  'M 50 8 C 50 50, 18 44, 18 86',
  'C 18 128, 82 122, 82 164',
  'C 82 206, 18 200, 18 242',
  'C 18 270, 30 296, 50 270',
]
const FULL_PATH = SEG.join(' ')
const PREFIXES = [SEG[0], SEG.slice(0, 2).join(' '), SEG.slice(0, 3).join(' '), SEG.slice(0, 4).join(' ')]

type Stop = {
  tag: string | null
  title: string
  desc: string
  cta?: boolean
}

const STOPS: Stop[] = [
  {
    tag: '01 — TANLASH',
    title: 'Xizmat turini tanlang',
    desc: 'Podkachka, perezobuvka, disk ta’miri — kerakli xizmatni bosh ekranda darhol tanlaysiz.',
  },
  {
    tag: '02 — BRON',
    title: 'Navbatsiz bron qiling',
    desc: 'Xaritadan eng yaqin servisni topib, qulay sana va vaqtni tanlaysiz — sizni kutadi.',
  },
  {
    tag: '03 — TO‘LOV',
    title: 'QR orqali to‘g‘ridan to‘lang',
    desc: 'Xizmatdan so‘ng QR kod yoki naqd to‘lov, xohlasangiz ustaga tip qoldirasiz.',
  },
  {
    tag: null,
    title: 'Ilovani hoziroq yuklab oling',
    desc: 'Mijoz sifatida bron qiling yoki shinomontaj sifatida ro‘yxatga oling — bitta ilovada ikki rol.',
    cta: true,
  },
]

type Waypoint = { x: number; y: number; frac: number }

export default function WheelSnakePath() {
  const sectionRef = useRef<HTMLDivElement>(null)
  const mainPathRef = useRef<SVGPathElement>(null)
  const prefixRefs = [
    useRef<SVGPathElement>(null),
    useRef<SVGPathElement>(null),
    useRef<SVGPathElement>(null),
    useRef<SVGPathElement>(null),
  ]

  const [size, setSize] = useState({ w: 0, h: 0 })
  const [waypoints, setWaypoints] = useState<Waypoint[]>([])
  const totalLenRef = useRef(0)
  const lastLenRef = useRef(0)
  const spinRef = useRef(0)

  const { scrollYProgress } = useScroll({ target: sectionRef, offset: ['start start', 'end end'] })
  const routeOffset = useTransform(scrollYProgress, (p) => 1 - p)

  const wx = useMotionValue(0)
  const wy = useMotionValue(0)
  const wrotate = useMotionValue(0)

  useEffect(() => {
    const measure = () => {
      if (!sectionRef.current || !mainPathRef.current) return
      const rect = sectionRef.current.getBoundingClientRect()
      setSize({ w: rect.width, h: rect.height })
      const total = mainPathRef.current.getTotalLength()
      totalLenRef.current = total
      const wps = prefixRefs.map((r) => {
        const len = r.current ? r.current.getTotalLength() : 0
        const frac = total > 0 ? len / total : 0
        const pt = mainPathRef.current!.getPointAtLength(len)
        return { x: pt.x, y: pt.y, frac }
      })
      setWaypoints(wps)
    }
    measure()
    window.addEventListener('resize', measure)
    return () => window.removeEventListener('resize', measure)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useAnimationFrame(() => {
    if (!mainPathRef.current || totalLenRef.current === 0 || size.w === 0) return
    const p = scrollYProgress.get()
    const len = p * totalLenRef.current
    const pt = mainPathRef.current.getPointAtLength(len)
    const px = (pt.x / VB_W) * size.w
    const py = (pt.y / VB_H) * size.h
    wx.set(px - WHEEL_SIZE / 2)
    wy.set(py - WHEEL_SIZE / 2)

    const delta = len - lastLenRef.current
    lastLenRef.current = len
    spinRef.current += delta * SPIN_PER_UNIT
    wrotate.set(spinRef.current)
  })

  return (
    <section ref={sectionRef} id="xizmat-yoli" className="relative h-[320vh] sm:h-[420vh]">
      <svg className="absolute inset-0 w-full h-full" viewBox={`0 0 ${VB_W} ${VB_H}`} preserveAspectRatio="none">
        <defs>
          <linearGradient id="routeGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#f0c668" />
            <stop offset="100%" stopColor="#9c7a2e" />
          </linearGradient>
        </defs>
        <path d={FULL_PATH} stroke="rgba(255,255,255,.10)" strokeWidth="0.9" fill="none" strokeDasharray="1.6 2.4" strokeLinecap="round" />
        <motion.path
          d={FULL_PATH}
          stroke="url(#routeGrad)"
          strokeWidth="0.9"
          fill="none"
          strokeLinecap="round"
          pathLength={1}
          strokeDasharray="1"
          style={{ strokeDashoffset: routeOffset }}
        />
        <path ref={mainPathRef} d={FULL_PATH} opacity={0} />
        {PREFIXES.map((d, i) => (
          <path key={i} ref={prefixRefs[i]} d={d} opacity={0} />
        ))}
      </svg>

      <motion.div
        style={{ x: wx, y: wy, rotate: wrotate, position: 'absolute', left: 0, top: 0, width: WHEEL_SIZE, height: WHEEL_SIZE }}
      >
        <WheelImage size={WHEEL_SIZE} src="/images/wheel-3d.png" objectPosition="50% 50%" />
      </motion.div>

      {waypoints.map((wp, i) => {
        const stop = STOPS[i]
        if (!stop) return null
        const px = (wp.x / VB_W) * size.w
        const py = (wp.y / VB_H) * size.h
        const isCenter = wp.x > 42 && wp.x < 58
        const side: 'left' | 'right' | 'center' = isCenter ? 'center' : wp.x < 50 ? 'right' : 'left'
        return <WaypointMarker key={i} scrollYProgress={scrollYProgress} px={px} py={py} frac={wp.frac} stop={stop} side={side} />
      })}
    </section>
  )
}

function WaypointMarker({
  scrollYProgress,
  px,
  py,
  frac,
  stop,
  side,
}: {
  scrollYProgress: MotionValue<number>
  px: number
  py: number
  frac: number
  stop: Stop
  side: 'left' | 'right' | 'center'
}) {
  const winIn = stop.cta ? 0.05 : 0.07
  const winOut = 0.05
  const fade = 0.025
  const start = Math.max(0, frac - winIn)
  const end = Math.min(1, frac + (stop.cta ? 0.2 : winOut))

  const opacityFade = useTransform(scrollYProgress, [start, start + fade, end - fade, end], [0, 1, 1, 0])
  const opacityHold = useTransform(scrollYProgress, [start, start + fade, 1], [0, 1, 1])
  const opacity = stop.cta ? opacityHold : opacityFade

  const alignClass = side === 'left' ? 'items-start text-left' : side === 'right' ? 'items-end text-right' : 'items-center text-center'
  const textTop = stop.cta ? py + 46 : py
  const textTransform = stop.cta ? 'translateX(-50%)' : side === 'center' ? 'translate(-50%,-50%)' : 'translateY(-50%)'

  return (
    <>
      <div
        className="absolute w-3 h-3 rounded-full bg-gold shadow-[0_0_18px_4px_rgba(212,168,67,.45)]"
        style={{ left: px, top: py, transform: 'translate(-50%,-50%)' }}
      />
      <motion.div
        style={{
          opacity,
          top: textTop,
          position: 'absolute',
          ...(side === 'left' ? { left: '6%' } : side === 'right' ? { right: '6%' } : { left: '50%' }),
          transform: textTransform,
        }}
        className={`flex flex-col ${alignClass} max-w-[270px] sm:max-w-[340px] px-4`}
      >
        {stop.tag && <span className="text-gold text-[11px] font-bold uppercase tracking-[.14em] mb-2">{stop.tag}</span>}
        <h3 className="text-[20px] sm:text-[26px] font-extrabold leading-tight tracking-tight">{stop.title}</h3>
        <p className="text-[13.5px] sm:text-[14.5px] text-txt2 leading-relaxed mt-2">{stop.desc}</p>
        {stop.cta && (
          <div
            className="flex flex-wrap gap-3 mt-3"
            style={{ justifyContent: side === 'center' ? 'center' : side === 'left' ? 'flex-start' : 'flex-end' }}
          >
            <a
              href={APK_URL}
              className="h-[44px] px-5 rounded-full bg-gold text-bg font-bold text-[12.5px] sm:text-[14px] flex items-center whitespace-nowrap hover:brightness-110 transition-all"
            >
              ⬇ Android uchun yuklab olish
            </a>
          </div>
        )}
      </motion.div>
    </>
  )
}
