export default function GarageBackdrop() {
  return (
    <div className="absolute inset-0 pointer-events-none" aria-hidden>
      <div
        className="absolute inset-0"
        style={{
          background: 'linear-gradient(180deg, #0a0908 0%, #110e0a 22%, #161109 48%, #130f0a 72%, #0c0a08 100%)',
        }}
      />
      <div
        className="absolute inset-0 opacity-[0.05]"
        style={{
          backgroundImage:
            'repeating-linear-gradient(0deg, rgba(255,255,255,.5) 0px, rgba(255,255,255,.5) 1px, transparent 1px, transparent 64px), repeating-linear-gradient(90deg, rgba(255,255,255,.5) 0px, rgba(255,255,255,.5) 1px, transparent 1px, transparent 64px)',
        }}
      />
      <div className="absolute left-[8%] top-[10%] w-[420px] h-[420px] rounded-full blur-[110px] opacity-[0.16]" style={{ background: '#d4a843' }} />
      <div className="absolute right-[6%] top-[38%] w-[380px] h-[380px] rounded-full blur-[120px] opacity-[0.12]" style={{ background: '#3b82f6' }} />
      <div className="absolute left-[10%] top-[68%] w-[460px] h-[460px] rounded-full blur-[130px] opacity-[0.14]" style={{ background: '#d4a843' }} />
      <div className="absolute right-[10%] top-[92%] w-[400px] h-[400px] rounded-full blur-[120px] opacity-[0.13]" style={{ background: '#d4a843' }} />
      <div
        className="absolute top-0 inset-x-0 h-[5px] opacity-60"
        style={{ background: 'repeating-linear-gradient(135deg, #d4a843 0 16px, #0a0908 16px 32px)' }}
      />
      <div
        className="absolute inset-0"
        style={{ background: 'radial-gradient(80% 45% at 50% 0%, transparent 50%, rgba(6,5,4,.65) 100%)' }}
      />
    </div>
  )
}
