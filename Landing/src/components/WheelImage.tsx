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
          '0 18px 40px -8px rgba(0,0,0,.7), 0 0 0 2.5px rgba(226,226,232,.55), 0 0 0 4px rgba(0,0,0,.5), inset 0 0 0 2px rgba(255,255,255,.22)',
      }}
    >
      <Image
        src={src}
        alt="Sport avtomobil g'ildiragi"
        fill
        sizes={`${size}px`}
        className="object-cover"
        style={{ objectPosition, transform: scale !== 1 ? `scale(${scale})` : undefined, filter: 'brightness(1.08) contrast(1.05)' }}
      />
      <div
        className="absolute inset-0 rounded-full"
        style={{ background: 'radial-gradient(120% 120% at 28% 18%, rgba(255,255,255,.22), transparent 55%)' }}
      />
    </div>
  )
}
