'use client'

import Image from 'next/image'

export default function WheelImage({
  size = 120,
  className = '',
  src = '/images/wheel-sport.jpg',
  objectPosition = '48% 46%',
  scale = 1,
}: {
  size?: number
  className?: string
  src?: string
  objectPosition?: string
  scale?: number
}) {
  return (
    <div
      className={`relative rounded-full overflow-hidden ${className}`}
      style={{
        width: size,
        height: size,
        boxShadow:
          '0 22px 48px -10px rgba(0,0,0,.78), 0 0 0 2.5px rgba(232,232,238,.6), 0 0 0 4px rgba(0,0,0,.55), inset 0 0 0 2px rgba(255,255,255,.25)',
      }}
    >
      <Image
        src={src}
        alt="Sport avtomobil g'ildiragi"
        fill
        sizes={`${size}px`}
        className="object-cover"
        style={{ objectPosition, transform: scale !== 1 ? `scale(${scale})` : undefined, filter: 'brightness(1.1) contrast(1.08) saturate(1.05)' }}
      />
      {/* Top-left key light */}
      <div
        className="absolute inset-0 rounded-full"
        style={{ background: 'radial-gradient(120% 120% at 28% 16%, rgba(255,255,255,.28), transparent 52%)' }}
      />
      {/* Bottom-right ambient occlusion for roundness */}
      <div
        className="absolute inset-0 rounded-full"
        style={{ background: 'radial-gradient(110% 110% at 76% 84%, rgba(0,0,0,.5), transparent 50%)' }}
      />
      {/* Rim vignette to seat the tyre edge */}
      <div
        className="absolute inset-0 rounded-full"
        style={{ boxShadow: 'inset 0 0 18px 6px rgba(0,0,0,.55)' }}
      />
    </div>
  )
}
