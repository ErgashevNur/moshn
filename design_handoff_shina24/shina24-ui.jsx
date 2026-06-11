// shina24-ui.jsx — shared UI components

// ---------- Button ----------
function Button({ variant = "primary", size, children, icon, iconR, onClick, disabled, style }) {
  const cls = `btn btn-${variant}` + (size === "sm" ? " btn-sm" : "");
  return (
    <button className={cls} onClick={onClick} disabled={disabled} style={style}>
      {icon && <Icon name={icon} size={size === "sm" ? 17 : 19} />}
      {children}
      {iconR && <Icon name={iconR} size={size === "sm" ? 17 : 19} />}
    </button>
  );
}

// ---------- App bar ----------
function AppBar({ title, onBack, right, large, eyebrow }) {
  return (
    <div className="appbar" style={large ? { paddingTop: 4, alignItems: "flex-start" } : null}>
      {onBack && (
        <button className="icon-btn" onClick={onBack} aria-label="back">
          <Icon name="chevL" size={20} />
        </button>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        {eyebrow && <div className="h-eyebrow" style={{ marginBottom: 3 }}>{eyebrow}</div>}
        <div className="appbar-title" style={large ? { fontSize: 27, fontWeight: 700, letterSpacing: "-0.03em" } : null}>{title}</div>
      </div>
      {right}
    </div>
  );
}

// ---------- Bottom sheet ----------
function Sheet({ open, onClose, children, title }) {
  if (!open) return null;
  return (
    <>
      <div className="sheet-scrim" onClick={onClose} />
      <div className="sheet">
        <div className="sheet-grip" />
        {title && (
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "8px 22px 4px" }}>
            <div style={{ fontSize: 18, fontWeight: 600 }}>{title}</div>
            <button className="icon-btn ghost" onClick={onClose} style={{ width: 32, height: 32 }}><Icon name="x" size={20} /></button>
          </div>
        )}
        <div style={{ overflowY: "auto", padding: "8px 22px 0" }}>{children}</div>
      </div>
    </>
  );
}

// ---------- Shop tag ----------
function ShopTag({ tag, t }) {
  if (tag === "vip") return <span className="tag gold"><Icon name="crown" size={12} /> VIP</span>;
  if (tag === "24h") return <span className="tag">24/7</span>;
  return null;
}

// ---------- Service shop card ----------
function ServiceCard({ w, t, lang, onClick, compact }) {
  return (
    <button className="card" onClick={onClick} style={{
      display: "flex", gap: 13, padding: 13, textAlign: "left",
      alignItems: "stretch", width: "100%",
    }}>
      <div className="ph" data-label="SERVIS" style={{ width: compact ? 64 : 78, height: compact ? 64 : 78, borderRadius: 15, flexShrink: 0 }} />
      <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 5 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
          <span style={{ fontSize: 16, fontWeight: 600, letterSpacing: "-0.02em", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{w.name}</span>
          {w.tags.includes("vip") && <Icon name="crown" size={14} style={{ color: "var(--gold)", flexShrink: 0 }} />}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 13 }}>
          <Icon name="starFill" size={13} style={{ color: "var(--gold)" }} />
          <span style={{ fontWeight: 600 }}>{w.rating}</span>
          <span style={{ color: "var(--text-3)" }}>· {w.reviews} {t("reviews")}</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 5, color: "var(--text-2)", fontSize: 12.5, marginTop: "auto" }}>
          <Icon name="pin" size={13} />
          <span style={{ whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{w.area}</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 12.5, color: "var(--text-2)" }}>
          <span style={{ color: w.open ? "var(--success)" : "var(--danger)", fontWeight: 600 }}>{w.open ? t("openNow") : t("closed")}</span>
          <span style={{ color: "var(--text-3)" }}>·</span>
          <span>{w.dist} {t("km")}</span>
          <span style={{ color: "var(--text-3)" }}>·</span>
          <span>{w.eta} {t("min")}</span>
        </div>
      </div>
    </button>
  );
}

// ---------- Service tile (grid) ----------
function ServiceTile({ s, t, onClick, active }) {
  return (
    <button onClick={onClick} style={{
      display: "flex", flexDirection: "column", alignItems: "center", gap: 9,
      padding: "16px 6px 13px", borderRadius: "var(--r-lg)",
      background: active ? "var(--inverse-bg)" : "var(--surface)",
      color: active ? "var(--inverse-text)" : "var(--text)",
      border: "1px solid var(--hairline)", transition: "all .15s ease",
    }}>
      <Icon name={s.icon} size={26} stroke={1.7} />
      <span style={{ fontSize: 12, fontWeight: 500, textAlign: "center", lineHeight: 1.2 }}>{t(s.key)}</span>
    </button>
  );
}

// ---------- Plate badge ----------
function Plate({ value, size = "md" }) {
  const big = size === "lg";
  return (
    <span className="mono" style={{
      display: "inline-flex", alignItems: "center",
      padding: big ? "7px 14px" : "4px 9px", borderRadius: 7,
      background: "#f4f4f2", color: "#111", fontWeight: 700,
      fontSize: big ? 18 : 13, letterSpacing: "0.04em", whiteSpace: "nowrap",
      border: "1px solid rgba(0,0,0,0.2)", boxShadow: "inset 0 0 0 2px #fff, 0 1px 2px rgba(0,0,0,.2)",
    }}>{value}</span>
  );
}

// ---------- Toggle switch ----------
function Toggle({ on: init = false, onChange }) {
  const [on, setOn] = React.useState(init);
  const handleClick = () => { const next = !on; setOn(next); onChange && onChange(next); };
  return (
    <button onClick={handleClick} style={{ width: 48, height: 29, borderRadius: 99, padding: 3, background: on ? "var(--success)" : "var(--surface-3)", flexShrink: 0, transition: "background .2s ease" }}>
      <div style={{ width: 23, height: 23, borderRadius: "50%", background: "#fff", transform: on ? "translateX(19px)" : "none", transition: "transform .2s ease", boxShadow: "0 1px 3px rgba(0,0,0,.3)" }} />
    </button>
  );
}

// ---------- Status chip ----------
function StatusChip({ status, t }) {
  const map = {
    pending:     { label: t("bookingPending"),     cls: "" },
    confirmed:   { label: t("bookingConfirmed"),   cls: "success" },
    in_progress: { label: t("bookingInProgress"),  cls: "gold" },
    completed:   { label: t("bookingCompleted"),   cls: "success" },
    cancelled:   { label: t("bookingCancelled"),   cls: "danger" },
    upcoming:    { label: t("upcoming"),            cls: "success" },
    past:        { label: t("past"),               cls: "" },
  };
  const { label, cls } = map[status] || { label: status, cls: "" };
  return <span className={`tag ${cls}`}>{label}</span>;
}

// ---------- Stylized minimal map ----------
function MapView({ pins = [], activeId, onPin, theme }) {
  const road    = theme === "dark" ? "#26262b" : "#e4e3de";
  const roadMaj = theme === "dark" ? "#33333a" : "#d6d5cf";
  const land    = theme === "dark" ? "#161619" : "#eceae4";
  const block   = theme === "dark" ? "#1d1d21" : "#f5f4f0";
  const water   = theme === "dark" ? "#15212b" : "#dde7ec";
  return (
    <svg viewBox="0 0 390 700" preserveAspectRatio="xMidYMid slice" style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}>
      <rect width="390" height="700" fill={land} />
      {[[20,60,90,80],[130,40,110,70],[260,70,120,90],[30,180,80,120],[140,200,90,100],[260,210,110,130],[20,330,100,90],[150,340,200,80],[30,450,130,120],[190,460,170,140],[40,610,300,70]].map((b,i)=>(
        <rect key={i} x={b[0]} y={b[1]} width={b[2]} height={b[3]} rx="6" fill={block} />
      ))}
      <path d="M-10 560 Q 120 540 210 600 T 410 580 L 410 720 L -10 720 Z" fill={water} opacity="0.8"/>
      <g stroke={road} strokeWidth="9" fill="none" strokeLinecap="round">
        <path d="M0 160 H390" /><path d="M0 310 H390" /><path d="M0 430 H390" /><path d="M0 590 H390" />
        <path d="M120 0 V700" /><path d="M250 0 V700" />
      </g>
      <g stroke={roadMaj} strokeWidth="15" fill="none" strokeLinecap="round">
        <path d="M0 250 H390" /><path d="M55 0 V700" />
        <path d="M0 40 Q 200 90 390 30" />
      </g>
      <g stroke={theme==="dark"?"#4a4a52":"#fff"} strokeWidth="1.6" strokeDasharray="6 8" fill="none" opacity="0.6">
        <path d="M0 250 H390" /><path d="M55 0 V700" />
      </g>
    </svg>
  );
}

// ---------- Customer row (CRM) ----------
function CustomerRow({ c, lang, t, onClick }) {
  return (
    <button className="row" onClick={onClick} style={{ width: "100%", textAlign: "left" }}>
      <div style={{ position: "relative", flexShrink: 0 }}>
        <div className="ph" data-label="" style={{ width: 44, height: 44, borderRadius: "50%" }} />
        {c.isVip && (
          <div style={{ position: "absolute", bottom: -2, right: -2, width: 18, height: 18, borderRadius: "50%", background: "var(--gold-dim)", border: "1.5px solid var(--bg)", display: "grid", placeItems: "center" }}>
            <Icon name="crown" size={10} style={{ color: "var(--gold)" }} />
          </div>
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14.5, fontWeight: 600, display: "flex", alignItems: "center", gap: 7 }}>
          {c.name}
          {c.isVip && <span className="tag gold" style={{ padding: "2px 6px", fontSize: 10 }}><Icon name="crown" size={9} /> VIP</span>}
        </div>
        <div style={{ fontSize: 12, color: "var(--text-3)", display: "flex", gap: 8, marginTop: 2 }}>
          <span className="mono">{c.phone}</span>
          <span>· {c.visits} {t("visitCount")}</span>
        </div>
      </div>
      <div style={{ textAlign: "right", flexShrink: 0 }}>
        <div style={{ fontSize: 11.5, color: "var(--text-3)" }}>{c.lastVisit[lang]}</div>
        <Icon name="chevR" size={16} style={{ color: "var(--text-3)", marginTop: 4 }} />
      </div>
    </button>
  );
}

Object.assign(window, { Button, AppBar, Sheet, ShopTag, ServiceCard, ServiceTile, Plate, Toggle, StatusChip, MapView, CustomerRow });
