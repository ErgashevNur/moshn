'use client'

import { useEffect, useRef, useState } from 'react'
import { motion, useAnimationFrame, useMotionValue, useScroll, useSpring, useTransform, type MotionValue } from 'framer-motion'
import WheelImage from './WheelImage'
import Icon from './Icon'
import { useI18n } from '@/lib/i18n'

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
  ctaBtn?: string
}

type Waypoint = { x: number; y: number; frac: number }

export default function WheelSnakePath() {
  const { t } = useI18n()
  const STOPS = t.journey
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
  // Spring-smoothed progress drives both the route reveal and the wheel,
  // so scroll feels weighted and glides instead of snapping frame-to-frame.
  const progress = useSpring(scrollYProgress, { stiffness: 90, damping: 26, mass: 0.5, restDelta: 0.0005 })
  const routeOffset = useTransform(progress, (p) => 1 - p)

  const wx = useMotionValue(0)
  const wy = useMotionValue(0)
  const wrotate = useMotionValue(0)
  // Spin speed → motion blur, so a fast scroll smears the tread like a real spinning wheel.
  const wblur = useMotionValue(0)
  const wfilter = useTransform(wblur, (b) => `blur(${b.toFixed(2)}px)`)
  // Faster spin = the wheel presses harder + the contact shadow stretches/softens.
  const shadowScaleX = useTransform(wblur, [0, 6], [1, 1.18])
  const shadowOpacity = useTransform(wblur, [0, 6], [0.55, 0.28])

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
    const p = progress.get()
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

    // Ease the blur toward the current spin speed for a soft attack/decay.
    const target = Math.min(6, Math.abs(delta) * 5.5)
    wblur.set(wblur.get() + (target - wblur.get()) * 0.18)
  })

  return (
    <section ref={sectionRef} id="xizmat-yoli" className="relative h-[240vh] sm:h-[300vh]">
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

      {/* Outer wrapper translates along the path; inner layers handle spin/blur so the
          glow halo and ground shadow stay upright while the tread rotates. */}
      <motion.div
        style={{ x: wx, y: wy, position: 'absolute', left: 0, top: 0, width: WHEEL_SIZE, height: WHEEL_SIZE }}
      >
        <motion.div
          className="absolute rounded-[50%] bg-black/70 blur-md"
          style={{
            width: WHEEL_SIZE * 0.82,
            height: WHEEL_SIZE * 0.2,
            left: WHEEL_SIZE * 0.09,
            top: WHEEL_SIZE * 0.86,
            scaleX: shadowScaleX,
            opacity: shadowOpacity,
          }}
        />
        <div
          className="absolute inset-0 rounded-full"
          style={{ boxShadow: '0 0 55px 8px rgba(212,168,67,.22)' }}
        />
        <motion.div style={{ rotate: wrotate, filter: wfilter, width: WHEEL_SIZE, height: WHEEL_SIZE }}>
          <WheelImage size={WHEEL_SIZE} src="/images/wheel-3d.png" objectPosition="50% 50%" />
        </motion.div>
      </motion.div>

      {waypoints.map((wp, i) => {
        const stop = STOPS[i]
        if (!stop) return null
        const px = (wp.x / VB_W) * size.w
        const py = (wp.y / VB_H) * size.h
        const isCenter = wp.x > 42 && wp.x < 58
        const side: 'left' | 'right' | 'center' = isCenter ? 'center' : wp.x < 50 ? 'right' : 'left'
        return <WaypointMarker key={i} scrollYProgress={progress} px={px} py={py} frac={wp.frac} stop={stop} side={side} />
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
  const fade = 0.03
  const start = Math.max(0, frac - winIn)
  const end = Math.min(1, frac + (stop.cta ? 0.2 : winOut))

  // Fade in once and stay — info remains visible even after the wheel scrolls past.
  const opacity = useTransform(scrollYProgress, [start, start + fade, 1], [0, 1, 1])
  // `end` is no longer used for visibility, but kept for readability of the stop window.
  void end

  // Entrance: slides up and de-blurs as the wheel reaches the stop.
  const enterY = useTransform(scrollYProgress, [start, start + fade], [34, 0])
  const enterScale = useTransform(scrollYProgress, [start, start + fade], [0.96, 1])
  const enterBlur = useTransform(scrollYProgress, [start, start + fade * 0.8], [9, 0])
  const enterFilter = useTransform(enterBlur, (b) => `blur(${b.toFixed(2)}px)`)

  // Staggered per-line reveal so tag → title → desc cascade in.
  const tagY = useTransform(scrollYProgress, [start, start + fade], [16, 0])
  const tagO = useTransform(scrollYProgress, [start, start + fade * 0.7], [0, 1])
  const titleY = useTransform(scrollYProgress, [start + fade * 0.25, start + fade * 1.25], [20, 0])
  const titleO = useTransform(scrollYProgress, [start + fade * 0.25, start + fade], [0, 1])
  const descY = useTransform(scrollYProgress, [start + fade * 0.5, start + fade * 1.5], [22, 0])
  const descO = useTransform(scrollYProgress, [start + fade * 0.5, start + fade * 1.2], [0, 1])

  // Marker dot pulses in just before the text.
  const dotScale = useTransform(scrollYProgress, [start - fade, start, start + fade], [0, 1.25, 1])

  const alignClass = side === 'left' ? 'items-start text-left' : side === 'right' ? 'items-end text-right' : 'items-center text-center'
  const textTop = stop.cta ? py + 46 : py
  const textTransform = stop.cta ? 'translateX(-50%)' : side === 'center' ? 'translate(-50%,-50%)' : 'translateY(-50%)'

  return (
    <>
      <motion.div
        className="absolute w-3 h-3 rounded-full bg-gold shadow-[0_0_18px_4px_rgba(212,168,67,.45)]"
        style={{ left: px, top: py, x: '-50%', y: '-50%', scale: dotScale }}
      />
      <div
        style={{
          top: textTop,
          position: 'absolute',
          ...(side === 'left' ? { left: '6%' } : side === 'right' ? { right: '6%' } : { left: '50%' }),
          transform: textTransform,
        }}
      >
        <motion.div
          style={{ opacity, y: enterY, scale: enterScale, filter: enterFilter }}
          className={`flex flex-col ${alignClass} max-w-[78vw] xs:max-w-[330px] sm:max-w-[440px] px-4`}
        >
          {stop.tag && (
            <motion.span style={{ y: tagY, opacity: tagO }} className="text-gold text-[13px] sm:text-[14px] font-bold uppercase tracking-[.14em] mb-2.5">
              {stop.tag}
            </motion.span>
          )}
          <motion.h3 style={{ y: titleY, opacity: titleO }} className="text-[26px] sm:text-[36px] font-extrabold leading-[1.1] tracking-tight">
            {stop.title}
          </motion.h3>
          <motion.p style={{ y: descY, opacity: descO }} className="text-[15.5px] sm:text-[18px] text-txt2 leading-relaxed mt-3">
            {stop.desc}
          </motion.p>
          {stop.cta && (
            <div
              className="flex flex-wrap gap-3 mt-3"
              style={{ justifyContent: side === 'center' ? 'center' : side === 'left' ? 'flex-start' : 'flex-end' }}
            >
              <a
                href={APK_URL}
                className="h-[46px] px-5 rounded-full bg-gold text-bg font-bold text-[13px] sm:text-[14px] flex items-center gap-2 whitespace-nowrap hover:brightness-110 transition-all"
              >
                <Icon name="download" size={18} />
                {stop.ctaBtn}
              </a>
            </div>
          )}
        </motion.div>
      </div>
    </>
  )
}
