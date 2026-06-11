// ios-frame.jsx — iPhone 14 Pro style device wrapper for the Moshn prototype
function IOSDevice({ dark, children }) {
  const body  = dark ? "#1d1d1f" : "#e8e8ec";
  const btn   = dark ? "#2a2a2d" : "#d0d0d5";
  const btnShadow = dark ? "0 0 0 0.5px rgba(255,255,255,0.06)" : "0 0 0 0.5px rgba(0,0,0,0.13)";
  const textC = dark ? "#fff" : "#000";
  const iconO = dark ? 1 : 0.88;

  return (
    <div style={{
      position: "relative",
      width: 428,
      background: body,
      borderRadius: 58,
      padding: "16px 19px",
      boxSizing: "border-box",
      boxShadow: dark
        ? "0 0 0 1px rgba(255,255,255,0.09), inset 0 1px 0 rgba(255,255,255,0.08), 0 80px 160px rgba(0,0,0,0.8)"
        : "0 0 0 1px rgba(0,0,0,0.18), inset 0 1px 0 rgba(255,255,255,0.85), 0 80px 160px rgba(0,0,0,0.32)",
    }}>

      {/* Silent switch */}
      <div style={{ position:"absolute", left:-3, top:60,  width:3, height:22, borderRadius:"2px 0 0 2px", background:btn, boxShadow:btnShadow }} />
      {/* Volume up */}
      <div style={{ position:"absolute", left:-3, top:100, width:3, height:32, borderRadius:"2px 0 0 2px", background:btn, boxShadow:btnShadow }} />
      {/* Volume down */}
      <div style={{ position:"absolute", left:-3, top:144, width:3, height:32, borderRadius:"2px 0 0 2px", background:btn, boxShadow:btnShadow }} />
      {/* Power */}
      <div style={{ position:"absolute", right:-3, top:120, width:3, height:64, borderRadius:"0 2px 2px 0", background:btn, boxShadow:btnShadow }} />

      {/* Screen */}
      <div style={{
        width: 390, height: 844,
        borderRadius: 44,
        overflow: "hidden",
        position: "relative",
        background: "#000",
        boxShadow: "inset 0 0 0 0.5px rgba(255,255,255,0.08)",
        flexShrink: 0,
      }}>
        {children}

        {/* Dynamic Island */}
        <div style={{
          position: "absolute", top: 12,
          left: "50%", transform: "translateX(-50%)",
          width: 126, height: 37, borderRadius: 20,
          background: "#000", zIndex: 200, pointerEvents: "none",
        }} />

        {/* Status bar — time (left) + icons (right) */}
        <div style={{
          position: "absolute", top: 0, left: 0, right: 0, height: 50,
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "14px 26px 0",
          zIndex: 201, pointerEvents: "none",
        }}>
          <span style={{
            fontSize: 15, fontWeight: 600, color: textC,
            letterSpacing: "-0.01em", fontFamily: "Sora, system-ui",
          }}>9:41</span>

          <div style={{ display: "flex", alignItems: "center", gap: 6, opacity: iconO }}>
            {/* Cellular signal */}
            <svg width="17" height="12" viewBox="0 0 17 12" fill="none">
              <rect x="0"    y="5"  width="3" height="7"  rx="1" fill={textC} />
              <rect x="4.5"  y="3"  width="3" height="9"  rx="1" fill={textC} />
              <rect x="9"    y="1"  width="3" height="11" rx="1" fill={textC} />
              <rect x="13.5" y="0"  width="3" height="12" rx="1" fill={textC} opacity="0.35" />
            </svg>
            {/* Wi-Fi */}
            <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
              <circle cx="8" cy="10.5" r="1.5" fill={textC} />
              <path d="M4.5 7.5a5 5 0 017 0" stroke={textC} strokeWidth="1.5" strokeLinecap="round" />
              <path d="M1.5 4.5a9 9 0 0113 0" stroke={textC} strokeWidth="1.5" strokeLinecap="round" opacity="0.45" />
            </svg>
            {/* Battery */}
            <div style={{ display: "flex", alignItems: "center", gap: 1.5 }}>
              <div style={{
                width: 25, height: 12, borderRadius: 4,
                border: `1.5px solid ${dark ? "rgba(255,255,255,0.45)" : "rgba(0,0,0,0.35)"}`,
                padding: "2px",
                display: "flex", alignItems: "center",
              }}>
                <div style={{ width: "78%", height: "100%", borderRadius: 2, background: textC }} />
              </div>
              <div style={{
                width: 2, height: 5, borderRadius: "0 1.5px 1.5px 0",
                background: dark ? "rgba(255,255,255,0.4)" : "rgba(0,0,0,0.3)",
              }} />
            </div>
          </div>
        </div>

        {/* Home indicator */}
        <div style={{
          position: "absolute", bottom: 8,
          left: "50%", transform: "translateX(-50%)",
          width: 134, height: 5, borderRadius: 99,
          background: dark ? "rgba(255,255,255,0.30)" : "rgba(0,0,0,0.20)",
          zIndex: 200, pointerEvents: "none",
        }} />
      </div>
    </div>
  );
}

Object.assign(window, { IOSDevice });
