// moshn-icons.jsx — clean 24px line icons, currentColor
function Icon({ name, size = 22, stroke = 1.8, fill = false, style }) {
  const p = { width: size, height: size, viewBox: "0 0 24 24", fill: "none",
    stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round",
    strokeLinejoin: "round", style };
  const paths = {
    search: <><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></>,
    pin: <><path d="M12 21s7-5.5 7-11a7 7 0 10-14 0c0 5.5 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/></>,
    route: <><circle cx="6" cy="19" r="2.5"/><circle cx="18" cy="5" r="2.5"/><path d="M9 18h6a3 3 0 003-3V9a3 3 0 00-3-3H9"/></>,
    home: <><path d="M3 11l9-7 9 7"/><path d="M5 10v9a1 1 0 001 1h12a1 1 0 001-1v-9"/></>,
    calendar: <><rect x="3.5" y="5" width="17" height="16" rx="3"/><path d="M3.5 9.5h17M8 3v4M16 3v4"/></>,
    car: <><path d="M5 11l1.6-4.2A2 2 0 018.5 5.5h7a2 2 0 011.9 1.3L19 11"/><path d="M4 11h16a1 1 0 011 1v4a1 1 0 01-1 1h-1v1.5a1 1 0 01-1 1h-1a1 1 0 01-1-1V17H9v1.5a1 1 0 01-1 1H7a1 1 0 01-1-1V17H5a1 1 0 01-1-1v-4a1 1 0 011-1z"/><circle cx="7.5" cy="14" r="1"/><circle cx="16.5" cy="14" r="1"/></>,
    bell: <><path d="M18 9a6 6 0 10-12 0c0 6-2.5 7-2.5 7h17S18 15 18 9z"/><path d="M10.5 20a2 2 0 003 0"/></>,
    user: <><circle cx="12" cy="8" r="4"/><path d="M4 20c0-3.5 3.5-6 8-6s8 2.5 8 6"/></>,
    alert: <><path d="M12 3l9.5 16.5a1 1 0 01-.87 1.5H3.37a1 1 0 01-.87-1.5L12 3z"/><path d="M12 9v5M12 17.5v.01"/></>,
    card: <><rect x="2.5" y="5" width="19" height="14" rx="3"/><path d="M2.5 9.5h19"/></>,
    star: <><path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z"/></>,
    starFill: <path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z" fill="currentColor" stroke="none"/>,
    chevL: <path d="M15 5l-7 7 7 7"/>,
    chevR: <path d="M9 5l7 7-7 7"/>,
    chevD: <path d="M5 9l7 7 7-7"/>,
    arrowR: <><path d="M5 12h14"/><path d="M13 6l6 6-6 6"/></>,
    plus: <><path d="M12 5v14M5 12h14"/></>,
    check: <path d="M5 12.5l4.5 4.5L19 6.5"/>,
    checkCircle: <><circle cx="12" cy="12" r="9"/><path d="M8 12.2l2.6 2.6L16 9.5"/></>,
    x: <path d="M6 6l12 12M18 6L6 18"/>,
    phone: <path d="M5 3.5h3l1.5 4-2 1.4a12 12 0 005.6 5.6l1.4-2 4 1.5v3a2 2 0 01-2 2A16 16 0 013 5.5a2 2 0 012-2z"/>,
    clock: <><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></>,
    sliders: <><path d="M4 7h10M18 7h2M4 17h2M10 17h10"/><circle cx="16" cy="7" r="2"/><circle cx="8" cy="17" r="2"/></>,
    camera: <><path d="M4 8h3l1.5-2h7L17 8h3a1 1 0 011 1v9a1 1 0 01-1 1H4a1 1 0 01-1-1V9a1 1 0 011-1z"/><circle cx="12" cy="13" r="3.2"/></>,
    heart: <path d="M12 20s-7-4.3-7-9.5A4 4 0 0112 7a4 4 0 017 3.5C19 15.7 12 20 12 20z"/>,
    qr: <><rect x="4" y="4" width="6" height="6" rx="1"/><rect x="14" y="4" width="6" height="6" rx="1"/><rect x="4" y="14" width="6" height="6" rx="1"/><path d="M14 14h2v2M20 14v6M16 18v2h4"/></>,
    wallet: <><rect x="3" y="6" width="18" height="13" rx="3"/><path d="M3 10h18M16 14h2"/></>,
    globe: <><circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.3 2.5 14.7 0 17M12 3.5c-2.5 2.3-2.5 14.7 0 17"/></>,
    moon: <path d="M20 14a8 8 0 11-10-10 6.5 6.5 0 0010 10z"/>,
    sun: <><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19"/></>,
    spark: <path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/>,
    gauge: <><path d="M4 18a8 8 0 1116 0"/><path d="M12 18l4-5"/><circle cx="12" cy="18" r="1.2" fill="currentColor" stroke="none"/></>,
    wrench: <path d="M15 6.5a3.5 3.5 0 00-4.6 4.3l-5.6 5.6a1.5 1.5 0 002.1 2.1l5.6-5.6A3.5 3.5 0 0017.5 9l-2 2-2-2 2-2z"/>,
    snow: <><path d="M12 3v18M5 7.5l14 9M19 7.5l-14 9"/><path d="M9.5 4.5L12 6l2.5-1.5M9.5 19.5L12 18l2.5 1.5"/></>,
    disc: <><circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="3"/><path d="M12 3.5v3M12 17.5v3M3.5 12h3M17.5 12h3"/></>,
    layers: <><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/></>,
    shield: <><path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6l7-3z"/><path d="M9 12l2 2 4-4"/></>,
    video: <><rect x="3" y="6" width="13" height="12" rx="2.5"/><path d="M16 10l5-3v10l-5-3z"/></>,
    location: <><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/></>,
    settings: <><circle cx="12" cy="12" r="3"/><path d="M19.4 13a1.6 1.6 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.6 1.6 0 00-2.7 1.1V21a2 2 0 01-4 0v-.1A1.6 1.6 0 006.8 19l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.6 1.6 0 00-1.1-2.7H3a2 2 0 010-4h.1A1.6 1.6 0 005 6.8l-.1-.1a2 2 0 112.8-2.8l.1.1A1.6 1.6 0 0010 4.6V4a2 2 0 014 0v.1a1.6 1.6 0 002.7 1.1l.1-.1a2 2 0 112.8 2.8l-.1.1a1.6 1.6 0 001.1 2.7H21a2 2 0 010 4h-.1a1.6 1.6 0 00-1.5 1z"/></>,
    crown: <path d="M4 18h16M4 18l-1.5-9 5 4 4.5-7 4.5 7 5-4L20 18"/>,
    gift: <><rect x="4" y="9" width="16" height="11" rx="2"/><path d="M4 13h16M12 9v11M12 9S9 9 8 7.5 9 4 12 9zM12 9s3 0 4-1.5S15 4 12 9z"/></>,
    list: <><path d="M8 6h12M8 12h12M8 18h12"/><circle cx="4" cy="6" r="1"/><circle cx="4" cy="12" r="1"/><circle cx="4" cy="18" r="1"/></>,
    chat: <path d="M4 5h16a1 1 0 011 1v9a1 1 0 01-1 1H9l-4 4v-4H4a1 1 0 01-1-1V6a1 1 0 011-1z"/>,
    logout: <><path d="M14 4h4a1 1 0 011 1v14a1 1 0 01-1 1h-4"/><path d="M10 12H3m0 0l3.5-3.5M3 12l3.5 3.5"/></>,
  };
  return <svg {...p}>{paths[name] || null}</svg>;
}

// Stars rating row
function Stars({ value = 0, size = 14, gap = 2 }) {
  return (
    <span className="stars" style={{ gap }}>
      {[1,2,3,4,5].map(i => (
        <Icon key={i} name={i <= Math.round(value) ? "starFill" : "star"} size={size}
          style={{ color: i <= Math.round(value) ? "var(--gold)" : "var(--text-3)" }} />
      ))}
    </span>
  );
}

Object.assign(window, { Icon, Stars });
