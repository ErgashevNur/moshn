// moshn-screens-discover.jsx — Home, Map, Workshop detail

// ---------- Promo banner ----------
function PromoBanner({ t }) {
  return (
    <div style={{ position: "relative", borderRadius: "var(--r-xl)", overflow: "hidden", background: "var(--inverse-bg)", color: "var(--inverse-text)", padding: "20px 22px", minHeight: 116, display: "flex", flexDirection: "column", justifyContent: "center" }}>
      <div style={{ position: "absolute", right: -30, top: -30, width: 150, height: 150, borderRadius: "50%", border: "16px solid color-mix(in srgb, var(--inverse-text) 10%, transparent)" }} />
      <div style={{ position: "absolute", right: 6, bottom: -50, width: 120, height: 120, borderRadius: "50%", border: "14px solid color-mix(in srgb, var(--inverse-text) 8%, transparent)" }} />
      <span className="tag gold" style={{ alignSelf: "flex-start", marginBottom: 9 }}><Icon name="snow" size={12} /> {t("svc_swap").toUpperCase?.() || "MAVSUM"}</span>
      <div style={{ fontSize: 19, fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.15, maxWidth: 230, position: "relative" }}>−20% {t("seasonTitle")}</div>
    </div>
  );
}

// ---------- Home ----------
function Home({ app }) {
  const { t, lang, go } = app;
  const [svc, setSvc] = React.useState(null);
  const popular = [...WORKSHOPS].sort((a,b) => b.rating - a.rating);

  return (
    <div className="screen">
      <div className="appbar" style={{ paddingTop: 6, alignItems: "center" }}>
        <button style={{ display: "flex", alignItems: "center", gap: 7, flex: 1, minWidth: 0 }}>
          <Icon name="pin" size={18} style={{ color: "var(--text-2)" }} />
          <div style={{ textAlign: "left", minWidth: 0 }}>
            <div className="h-eyebrow" style={{ fontSize: 10 }}>{t("nearYou")}</div>
            <div style={{ display: "flex", alignItems: "center", gap: 4, fontWeight: 600, fontSize: 15 }}>Toshkent, Yunusobod <Icon name="chevD" size={15} style={{ color: "var(--text-3)" }} /></div>
          </div>
        </button>
        <button className="icon-btn" onClick={() => go("notifications")} style={{ position: "relative" }}>
          <Icon name="bell" size={20} />
          <span style={{ position: "absolute", top: 9, right: 10, width: 8, height: 8, borderRadius: "50%", background: "var(--danger)", border: "2px solid var(--surface)" }} />
        </button>
        <button onClick={() => go("profile")} style={{ width: 42, height: 42, borderRadius: "50%", overflow: "hidden", flexShrink: 0, border: "1px solid var(--hairline)" }}>
          <div className="ph" data-label="" style={{ width: "100%", height: "100%" }} />
        </button>
      </div>

      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        <h1 style={{ fontSize: 25, fontWeight: 700, letterSpacing: "-0.03em", margin: "8px 0 16px", lineHeight: 1.15 }}>{t("whatService")}</h1>

        <button onClick={() => go("map")} style={{ display: "flex", alignItems: "center", gap: 12, width: "100%", height: 52, padding: "0 16px", borderRadius: "var(--r-md)", background: "var(--surface)", border: "1px solid var(--hairline)", color: "var(--text-3)", marginBottom: 20 }}>
          <Icon name="search" size={20} />
          <span style={{ fontSize: 15 }}>{t("searchPh")}</span>
        </button>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 10, marginBottom: 24 }} className="stagger">
          {SERVICES.map(s => (
            <ServiceTile key={s.id} s={s} t={t} active={svc === s.id}
              onClick={() => { setSvc(s.id); app.setSvc(s.id); go("map"); }} />
          ))}
        </div>

        <div className="rise" style={{ marginBottom: 24 }}><PromoBanner t={t} /></div>

        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 13 }}>
          <h2 style={{ fontSize: 18, fontWeight: 700, letterSpacing: "-0.02em", margin: 0 }}>{t("popular")}</h2>
          <button onClick={() => go("map")} style={{ display: "flex", alignItems: "center", gap: 3, color: "var(--text-2)", fontSize: 13.5, fontWeight: 600 }}>{t("seeMap")} <Icon name="chevR" size={15} /></button>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 11 }} className="stagger">
          {popular.map(w => (
            <WorkshopCard key={w.id} w={w} t={t} lang={lang} onClick={() => { app.setShop(w); go("detail"); }} />
          ))}
        </div>
      </div>
    </div>
  );
}

// ---------- Map screen ----------
function MapScreen({ app }) {
  const { t, lang, theme, go } = app;
  const [expanded, setExpanded] = React.useState(false);
  const [active, setActive] = React.useState(WORKSHOPS[0].id);
  const list = WORKSHOPS;
  const pinPos = { w1: [62,30], w2: [30,52], w3: [72,44], w4: [44,68] };

  return (
    <div className="screen">
      <div style={{ position: "absolute", inset: 0 }}>
        <MapView theme={theme} />
        {/* pins */}
        {list.map(w => {
          const [x,y] = pinPos[w.id];
          const on = active === w.id;
          return (
            <button key={w.id} onClick={() => setActive(w.id)} style={{
              position: "absolute", left: `${x}%`, top: `${y}%`, transform: "translate(-50%,-100%)",
              zIndex: on ? 3 : 1, transition: "transform .2s ease",
            }}>
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                <div style={{
                  padding: on ? "6px 12px" : "5px 10px", borderRadius: 99,
                  background: on ? "var(--inverse-bg)" : "var(--bg-elev)",
                  color: on ? "var(--inverse-text)" : "var(--text)",
                  fontWeight: 700, fontSize: on ? 13 : 12, whiteSpace: "nowrap",
                  boxShadow: "var(--shadow-2)", display: "flex", alignItems: "center", gap: 5,
                  border: "1px solid var(--hairline)",
                }}>
                  {w.tags.includes("vip") && <Icon name="crown" size={12} style={{ color: "var(--gold)" }} />}
                  {fmtSom(w.price)}
                </div>
                <div style={{ width: 0, height: 0, borderLeft: "5px solid transparent", borderRight: "5px solid transparent", borderTop: `7px solid ${on ? "var(--inverse-bg)" : "var(--bg-elev)"}` }} />
              </div>
            </button>
          );
        })}
      </div>

      {/* top floating bar */}
      <div style={{ position: "relative", zIndex: 6, display: "flex", gap: 10, padding: "12px 16px" }}>
        <button className="icon-btn" onClick={() => go("home")} style={{ background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="chevL" size={20} /></button>
        <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 10, height: 42, padding: "0 14px", borderRadius: 99, background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}>
          <Icon name="search" size={18} style={{ color: "var(--text-3)" }} />
          <span style={{ fontSize: 14, color: "var(--text-2)" }}>{app.svc ? t(SERVICES.find(s=>s.id===app.svc).key) : t("searchPh")}</span>
        </div>
        <button className="icon-btn" style={{ background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="sliders" size={20} /></button>
      </div>

      {/* my location btn */}
      <button className="icon-btn" style={{ position: "absolute", right: 16, bottom: "48%", zIndex: 6, background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="location" size={20} /></button>

      {/* bottom list panel */}
      <div style={{
        position: "absolute", left: 0, right: 0, bottom: 0, zIndex: 7,
        height: expanded ? "82%" : "44%",
        background: "var(--bg-elev)", borderRadius: "var(--r-2xl) var(--r-2xl) 0 0",
        boxShadow: "0 -10px 40px rgba(0,0,0,.25)", transition: "height .34s cubic-bezier(.16,1,.3,1)",
        display: "flex", flexDirection: "column",
      }}>
        <button onClick={() => setExpanded(e => !e)} style={{ padding: "10px 0 6px", flexShrink: 0 }}>
          <div className="sheet-grip" style={{ margin: "0 auto" }} />
        </button>
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", padding: "0 20px 10px", flexShrink: 0 }}>
          <span style={{ fontSize: 16, fontWeight: 700 }}>{list.length} {t("nearYou").toLowerCase()}</span>
          <span style={{ fontSize: 13, color: "var(--text-2)", display: "flex", alignItems: "center", gap: 4 }}><Icon name="starFill" size={13} style={{ color: "var(--gold)" }} /> {t("popular").split(" ")[0]}</span>
        </div>
        <div style={{ flex: 1, overflowY: "auto", padding: "0 16px 24px", display: "flex", flexDirection: "column", gap: 11 }}>
          {[...list].sort((a,b) => (a.id===active?-1:b.id===active?1:0)).map(w => (
            <WorkshopCard key={w.id} w={w} t={t} lang={lang} onClick={() => { app.setShop(w); go("detail"); }} />
          ))}
        </div>
      </div>
    </div>
  );
}

// ---------- Workshop detail ----------
function WorkshopDetail({ app }) {
  const { t, lang, go } = app;
  const w = app.shop || WORKSHOPS[0];
  return (
    <div className="screen">
      <div className="screen-body">
        {/* hero */}
        <div style={{ position: "relative", height: 260 }}>
          <div className="ph" data-label="SERVIS FOTOSI" style={{ position: "absolute", inset: 0, borderRadius: 0 }} />
          <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom, var(--scrim) 0%, transparent 28%, transparent 70%, var(--bg) 100%)" }} />
          <div style={{ position: "absolute", top: 12, left: 16, right: 16, display: "flex", justifyContent: "space-between", zIndex: 2 }}>
            <button className="icon-btn" onClick={() => go("map")} style={{ background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="chevL" size={20} /></button>
            <button className="icon-btn" style={{ background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="heart" size={20} /></button>
          </div>
          <div style={{ position: "absolute", bottom: 12, right: 16, display: "flex", gap: 4 }}>
            {[0,1,2].map(i => <div key={i} style={{ width: i===0?16:6, height: 6, borderRadius: 99, background: i===0?"#fff":"rgba(255,255,255,.5)" }} />)}
          </div>
        </div>

        <div style={{ padding: "4px 20px 20px" }}>
          <div style={{ display: "flex", alignItems: "flex-start", gap: 10, marginBottom: 8 }}>
            <h1 style={{ fontSize: 24, fontWeight: 700, letterSpacing: "-0.03em", margin: 0, flex: 1, lineHeight: 1.1 }}>{w.name}</h1>
            {w.tags.map(tg => <ShopTag key={tg} tag={tg} t={t} />)}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 14, marginBottom: 6 }}>
            <Icon name="starFill" size={15} style={{ color: "var(--gold)" }} />
            <b>{w.rating}</b><span style={{ color: "var(--text-3)" }}>· {w.reviews} {t("reviews")}</span>
            <span style={{ color: "var(--text-3)" }}>·</span>
            <span style={{ color: "var(--success)", fontWeight: 600 }}>{w.open ? t("openNow") : t("closed")}</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--text-2)", fontSize: 13.5, marginBottom: 18 }}>
            <Icon name="pin" size={15} /> {w.area} · {w.dist} {t("km")}
          </div>

          <div style={{ display: "flex", gap: 10, marginBottom: 24 }}>
            <Button variant="secondary" size="sm" icon="route" style={{ flex: 1 }}>{t("route")}</Button>
            <Button variant="secondary" size="sm" icon="phone" style={{ flex: 1 }}>{t("callShop")}</Button>
          </div>

          <div style={{ marginBottom: 24 }}>
            <h3 className="sec-label" style={{ marginBottom: 9 }}>{t("about")}</h3>
            <p style={{ fontSize: 14.5, lineHeight: 1.55, color: "var(--text-2)", margin: 0, textWrap: "pretty" }}>{w.desc[lang]}</p>
          </div>

          <div style={{ marginBottom: 24 }}>
            <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("services")}</h3>
            <div className="list-card">
              {SERVICES.slice(0,4).map((s, i) => (
                <div key={s.id} className="row" style={{ padding: "14px 16px" }}>
                  <div style={{ width: 38, height: 38, borderRadius: 11, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name={s.icon} size={20} /></div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14.5, fontWeight: 600 }}>{t(s.key)}</div>
                    <div style={{ fontSize: 12.5, color: "var(--text-3)" }}>≈ {s.dur} {t("min")}</div>
                  </div>
                  <div className="mono" style={{ fontSize: 14, fontWeight: 600 }}>{fmtSom(s.price)}</div>
                </div>
              ))}
            </div>
          </div>

          <div style={{ marginBottom: 8 }}>
            <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("reviewsTitle")} · {w.reviews}</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {REVIEWS.map(r => (
                <div key={r.id} className="card" style={{ padding: 15 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 8 }}>
                    <div className="ph" data-label="" style={{ width: 34, height: 34, borderRadius: "50%" }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 14, fontWeight: 600 }}>{r.name}</div>
                      <div style={{ fontSize: 11.5, color: "var(--text-3)" }}>{r.ago[lang]}</div>
                    </div>
                    <Stars value={r.rating} size={13} />
                  </div>
                  <p style={{ fontSize: 13.5, lineHeight: 1.5, color: "var(--text-2)", margin: 0 }}>{r.text[lang]}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* sticky CTA */}
      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)", display: "flex", alignItems: "center", gap: 14 }}>
        <div>
          <div className="h-eyebrow">{t("from")}</div>
          <div className="mono" style={{ fontSize: 19, fontWeight: 700 }}>{fmtSom(w.price)}</div>
        </div>
        <Button iconR="arrowR" onClick={() => go("booking")} style={{ flex: 1 }}>{t("book")}</Button>
      </div>
    </div>
  );
}

Object.assign(window, { Home, MapScreen, WorkshopDetail, PromoBanner });
