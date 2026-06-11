// shina24-screens-owner.jsx — Owner: Home, Map, ServiceDetail, Booking, Payment, Confirmation

// ---------- Promo banner ----------
function PromoBanner({ t }) {
  return (
    <div style={{ position: "relative", borderRadius: "var(--r-xl)", overflow: "hidden", background: "var(--inverse-bg)", color: "var(--inverse-text)", padding: "20px 22px", minHeight: 116, display: "flex", flexDirection: "column", justifyContent: "center" }}>
      <div style={{ position: "absolute", right: -30, top: -30, width: 150, height: 150, borderRadius: "50%", border: "16px solid color-mix(in srgb, var(--inverse-text) 10%, transparent)" }} />
      <div style={{ position: "absolute", right: 6, bottom: -50, width: 120, height: 120, borderRadius: "50%", border: "14px solid color-mix(in srgb, var(--inverse-text) 8%, transparent)" }} />
      <span className="tag gold" style={{ alignSelf: "flex-start", marginBottom: 9 }}><Icon name="snow" size={12} /> MAVSUM</span>
      <div style={{ fontSize: 19, fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.15, maxWidth: 230, position: "relative" }}>−20% G'ildirak almashtirish</div>
    </div>
  );
}

// ---------- Owner Home ----------
function OwnerHome({ app }) {
  const { t, lang, go } = app;
  const [svc, setSvc] = React.useState(null);
  const popular = [...SERVICE_SHOPS].sort((a,b) => b.rating - a.rating);

  return (
    <div className="screen">
      {/* Appbar */}
      <div className="appbar" style={{ paddingTop: 6, alignItems: "center" }}>
        <button style={{ display: "flex", alignItems: "center", gap: 7, flex: 1, minWidth: 0 }}>
          <Icon name="pin" size={18} style={{ color: "var(--text-2)" }} />
          <div style={{ textAlign: "left", minWidth: 0 }}>
            <div className="h-eyebrow" style={{ fontSize: 10 }}>{t("nearYou")}</div>
            <div style={{ display: "flex", alignItems: "center", gap: 4, fontWeight: 600, fontSize: 15 }}>
              Toshkent, Yunusobod <Icon name="chevD" size={15} style={{ color: "var(--text-3)" }} />
            </div>
          </div>
        </button>
        <button className="icon-btn" onClick={() => go("notifications")} style={{ position: "relative" }}>
          <Icon name="bell" size={20} />
          <span style={{ position: "absolute", top: 9, right: 10, width: 8, height: 8, borderRadius: "50%", background: "var(--danger)", border: "2px solid var(--surface)" }} />
        </button>
        <button onClick={() => go("ownerProfile")} style={{ width: 42, height: 42, borderRadius: "50%", overflow: "hidden", flexShrink: 0, border: "1px solid var(--hairline)" }}>
          <div className="ph" data-label="" style={{ width: "100%", height: "100%" }} />
        </button>
      </div>

      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        <h1 style={{ fontSize: 25, fontWeight: 700, letterSpacing: "-0.03em", margin: "8px 0 16px", lineHeight: 1.15 }}>{t("whatService")}</h1>

        {/* Search */}
        <button onClick={() => go("map")} style={{ display: "flex", alignItems: "center", gap: 12, width: "100%", height: 52, padding: "0 16px", borderRadius: "var(--r-md)", background: "var(--surface)", border: "1px solid var(--hairline)", color: "var(--text-3)", marginBottom: 20 }}>
          <Icon name="search" size={20} />
          <span style={{ fontSize: 15 }}>{t("searchPh")}</span>
        </button>

        {/* Service type grid */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 10, marginBottom: 24 }} className="stagger">
          {SERVICES.map(s => (
            <ServiceTile key={s.id} s={s} t={t} active={svc === s.id}
              onClick={() => { setSvc(s.id); app.setSvc(s.id); go("map"); }} />
          ))}
        </div>

        {/* Promo */}
        <div className="rise" style={{ marginBottom: 24 }}><PromoBanner t={t} /></div>

        {/* Top services */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 13 }}>
          <h2 style={{ fontSize: 18, fontWeight: 700, letterSpacing: "-0.02em", margin: 0 }}>{t("popular")}</h2>
          <button onClick={() => go("map")} style={{ display: "flex", alignItems: "center", gap: 3, color: "var(--text-2)", fontSize: 13.5, fontWeight: 600 }}>
            {t("seeMap")} <Icon name="chevR" size={15} />
          </button>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 11 }} className="stagger">
          {popular.map(w => (
            <ServiceCard key={w.id} w={w} t={t} lang={lang} onClick={() => { app.setShop(w); go("serviceDetail"); }} />
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
  const [active, setActive] = React.useState(SERVICE_SHOPS[0].id);
  const list = SERVICE_SHOPS;
  const pinPos = { s1: [62,30], s2: [30,52], s3: [72,44], s4: [44,68] };

  return (
    <div className="screen">
      <div style={{ position: "absolute", inset: 0 }}>
        <MapView theme={theme} />
        {list.map(w => {
          const [x,y] = pinPos[w.id] || [50,50];
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

      {/* Top bar */}
      <div style={{ position: "relative", zIndex: 6, display: "flex", gap: 10, padding: "12px 16px" }}>
        <button className="icon-btn" onClick={() => go("ownerHome")} style={{ background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="chevL" size={20} /></button>
        <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 10, height: 42, padding: "0 14px", borderRadius: 99, background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}>
          <Icon name="search" size={18} style={{ color: "var(--text-3)" }} />
          <span style={{ fontSize: 14, color: "var(--text-2)" }}>
            {app.svc ? t(SERVICES.find(s=>s.id===app.svc)?.key || "svc_swap") : t("searchPh")}
          </span>
        </div>
        <button className="icon-btn" style={{ background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="sliders" size={20} /></button>
      </div>

      <button className="icon-btn" style={{ position: "absolute", right: 16, bottom: "48%", zIndex: 6, background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}><Icon name="location" size={20} /></button>

      {/* Bottom panel */}
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
          <span style={{ fontSize: 13, color: "var(--text-2)", display: "flex", alignItems: "center", gap: 4 }}>
            <Icon name="starFill" size={13} style={{ color: "var(--gold)" }} /> Top
          </span>
        </div>
        <div style={{ flex: 1, overflowY: "auto", padding: "0 16px 24px", display: "flex", flexDirection: "column", gap: 11 }}>
          {[...list].sort((a,b) => (a.id===active?-1:b.id===active?1:0)).map(w => (
            <ServiceCard key={w.id} w={w} t={t} lang={lang} onClick={() => { app.setShop(w); go("serviceDetail"); }} />
          ))}
        </div>
      </div>
    </div>
  );
}

// ---------- Service detail ----------
function ServiceDetail({ app }) {
  const { t, lang, go } = app;
  const w = app.shop || SERVICE_SHOPS[0];
  return (
    <div className="screen">
      <div className="screen-body">
        {/* Hero */}
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

          {/* About */}
          <div style={{ marginBottom: 24 }}>
            <h3 className="sec-label" style={{ marginBottom: 9 }}>{t("about")}</h3>
            <p style={{ fontSize: 14.5, lineHeight: 1.55, color: "var(--text-2)", margin: 0, textWrap: "pretty" }}>{w.desc[lang]}</p>
          </div>

          {/* Services & prices */}
          <div style={{ marginBottom: 24 }}>
            <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("services")}</h3>
            <div className="list-card">
              {SERVICES.slice(0,4).map(s => (
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

          {/* Reviews */}
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

      {/* Sticky CTA */}
      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)", display: "flex", alignItems: "center", gap: 14 }}>
        <div>
          <div className="h-eyebrow">{t("from")}</div>
          <div className="mono" style={{ fontSize: 19, fontWeight: 700 }}>{fmtSom(w.price)}</div>
        </div>
        <Button iconR="arrowR" onClick={() => go("ownerBooking")} style={{ flex: 1 }}>{t("book")}</Button>
      </div>
    </div>
  );
}

// ---------- Booking ----------
function OwnerBooking({ app }) {
  const { t, lang, go } = app;
  const w = app.shop || SERVICE_SHOPS[0];
  const [svc, setSvc] = React.useState(app.svc || "swap");
  const [car, setCar] = React.useState(VEHICLES[0].id);
  const [date, setDate] = React.useState(6);
  const [time, setTime] = React.useState(null);
  const svcObj = SERVICES.find(s => s.id === svc) || SERVICES[0];

  return (
    <div className="screen">
      <AppBar onBack={() => go("serviceDetail")} title={t("book")} />
      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        {/* Shop row */}
        <div className="card" style={{ display: "flex", alignItems: "center", gap: 12, padding: 12, marginBottom: 22 }}>
          <div className="ph" data-label="" style={{ width: 46, height: 46, borderRadius: 12 }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600 }}>{w.name}</div>
            <div style={{ fontSize: 12.5, color: "var(--text-2)", display: "flex", alignItems: "center", gap: 4 }}><Icon name="pin" size={13} /> {w.area}</div>
          </div>
          {w.tags.includes("vip") && <Icon name="crown" size={16} style={{ color: "var(--gold)" }} />}
        </div>

        {/* Service chips */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("chooseService")}</h3>
        <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 6, marginBottom: 22 }}>
          {SERVICES.map(s => (
            <button key={s.id} className="chip" data-active={svc === s.id} onClick={() => setSvc(s.id)} style={{ flexShrink: 0 }}>
              <Icon name={s.icon} size={16} /> {t(s.key)}
            </button>
          ))}
        </div>

        {/* Vehicle */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("yourCar")}</h3>
        <div style={{ display: "flex", flexDirection: "column", gap: 9, marginBottom: 22 }}>
          {VEHICLES.map(c => (
            <button key={c.id} onClick={() => setCar(c.id)} className="card" style={{
              display: "flex", alignItems: "center", gap: 12, padding: 12, textAlign: "left",
              borderColor: car === c.id ? "var(--text-3)" : "var(--hairline)", borderWidth: 1.5,
            }}>
              <div style={{ width: 42, height: 42, borderRadius: 11, background: c.color, display: "grid", placeItems: "center", flexShrink: 0, border: "1px solid var(--hairline-2)" }}>
                <Icon name="car" size={22} style={{ color: c.color === "#1c1c1c" ? "#fff" : "#222" }} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14.5, fontWeight: 600 }}>{c.make}</div>
                <div style={{ fontSize: 12, color: "var(--text-3)" }}>{c.size}</div>
              </div>
              <Plate value={c.plate} />
              <div style={{ width: 22, height: 22, borderRadius: "50%", border: `2px solid ${car===c.id?"var(--text)":"var(--hairline-2)"}`, display: "grid", placeItems: "center", flexShrink: 0 }}>
                {car === c.id && <div style={{ width: 11, height: 11, borderRadius: "50%", background: "var(--text)" }} />}
              </div>
            </button>
          ))}
        </div>

        {/* Date */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("chooseDate")}</h3>
        <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 6, marginBottom: 22 }}>
          {DATES.map(d => {
            const on = date === d.d;
            return (
              <button key={d.d} onClick={() => setDate(d.d)} style={{
                flexShrink: 0, width: 58, padding: "11px 0", borderRadius: "var(--r-md)",
                background: on ? "var(--inverse-bg)" : "var(--surface)", color: on ? "var(--inverse-text)" : "var(--text)",
                border: "1px solid var(--hairline)", textAlign: "center",
              }}>
                <div style={{ fontSize: 11, opacity: .65, fontWeight: 600 }}>{d.label ? t(d.label).slice(0,3) : d.wd[lang]}</div>
                <div style={{ fontSize: 19, fontWeight: 700, marginTop: 2 }}>{d.d}</div>
              </button>
            );
          })}
        </div>

        {/* Time slots */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("chooseTime")}</h3>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 9 }}>
          {TIMES.map(tm => {
            const booked = BOOKED_TIMES.includes(tm);
            const on = time === tm;
            return (
              <button key={tm} disabled={booked} onClick={() => setTime(tm)} className="mono" style={{
                padding: "12px 0", borderRadius: "var(--r-sm)", fontSize: 14, fontWeight: 600,
                background: on ? "var(--inverse-bg)" : "var(--surface)",
                color: booked ? "var(--text-3)" : on ? "var(--inverse-text)" : "var(--text)",
                border: "1px solid var(--hairline)", opacity: booked ? .45 : 1,
                textDecoration: booked ? "line-through" : "none",
              }}>{tm}</button>
            );
          })}
        </div>

        {time && (
          <div className="rise" style={{ display: "flex", alignItems: "center", gap: 8, marginTop: 18, padding: "11px 14px", borderRadius: "var(--r-md)", background: "var(--gold-dim)", color: "var(--gold)", fontSize: 13, fontWeight: 600 }}>
            <Icon name="clock" size={16} /> {t("slotHeld")}
          </div>
        )}
      </div>

      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)", display: "flex", alignItems: "center", gap: 14 }}>
        <div>
          <div className="h-eyebrow">{t("total")}</div>
          <div className="mono" style={{ fontSize: 19, fontWeight: 700 }}>{fmtSom(svcObj.price)}</div>
        </div>
        <Button disabled={!time} iconR="arrowR" onClick={() => { app.setOrder({ w, svc, car, date, time, price: svcObj.price }); go("ownerPayment"); }} style={{ flex: 1 }}>{t("toPayment")}</Button>
      </div>
    </div>
  );
}

// ---------- Payment ----------
function OwnerPayment({ app }) {
  const { t, lang, go } = app;
  const o = app.order || { w: SERVICE_SHOPS[0], svc: "swap", price: 80000, date: 6, time: "16:30", car: VEHICLES[0].id };
  const svcObj = SERVICES.find(s => s.id === o.svc) || SERVICES[0];
  const vehicle = VEHICLES.find(c => c.id === o.car) || VEHICLES[0];
  const [timing, setTiming] = React.useState("now");
  const [method, setMethod] = React.useState("uzcard");
  const [tip, setTip] = React.useState(0);
  const tips = [0, 10000, 20000, 50000];

  const timingOpts = [
    { id: "now",   icon: "card",   title: t("payNow"),      desc: t("selectCard") },
    { id: "later", icon: "clock",  title: t("payLater"),    desc: t("payLaterDesc") },
    { id: "split", icon: "wallet", title: t("installment"), desc: t("installmentDesc") },
  ];
  const total = o.price + tip;

  return (
    <div className="screen">
      <AppBar onBack={() => go("ownerBooking")} title={t("payment")} />
      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        {/* Summary */}
        <div className="card" style={{ padding: 16, marginBottom: 22 }}>
          <h3 className="sec-label" style={{ marginBottom: 13 }}>{t("orderSummary")}</h3>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 14 }}>
            <div className="ph" data-label="" style={{ width: 44, height: 44, borderRadius: 12 }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600 }}>{o.w.name}</div>
              <div style={{ fontSize: 12.5, color: "var(--text-2)" }}>{t(svcObj.key)} · {vehicle.plate}</div>
            </div>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13.5, paddingTop: 13, borderTop: "1px solid var(--hairline)" }}>
            <span style={{ color: "var(--text-2)", display: "flex", alignItems: "center", gap: 6 }}><Icon name="calendar" size={15} /> {o.date}-dekabr</span>
            <span style={{ fontWeight: 600 }} className="mono">{o.time}</span>
          </div>
        </div>

        {/* Timing options */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("payment")}</h3>
        <div style={{ display: "flex", flexDirection: "column", gap: 9, marginBottom: 22 }}>
          {timingOpts.map(op => (
            <button key={op.id} onClick={() => setTiming(op.id)} className="card" style={{
              display: "flex", alignItems: "center", gap: 13, padding: 14, textAlign: "left",
              borderColor: timing === op.id ? "var(--text-3)" : "var(--hairline)", borderWidth: 1.5,
            }}>
              <div style={{ width: 40, height: 40, borderRadius: 11, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name={op.icon} size={20} /></div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14.5, fontWeight: 600 }}>{op.title}</div>
                <div style={{ fontSize: 12, color: "var(--text-3)" }}>{op.desc}</div>
              </div>
              <div style={{ width: 22, height: 22, borderRadius: "50%", border: `2px solid ${timing===op.id?"var(--text)":"var(--hairline-2)"}`, display: "grid", placeItems: "center", flexShrink: 0 }}>
                {timing === op.id && <div style={{ width: 11, height: 11, borderRadius: "50%", background: "var(--text)" }} />}
              </div>
            </button>
          ))}
        </div>

        {/* Cards (when pay now) */}
        {timing === "now" && (
          <div className="rise" style={{ marginBottom: 22 }}>
            <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 6 }}>
              {PAY_METHODS.map(m => (
                <button key={m.id} onClick={() => setMethod(m.id)} style={{
                  flexShrink: 0, width: 150, padding: 14, borderRadius: "var(--r-md)", textAlign: "left",
                  background: method === m.id ? "var(--inverse-bg)" : "var(--surface)",
                  color: method === m.id ? "var(--inverse-text)" : "var(--text)",
                  border: "1px solid var(--hairline)",
                }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 18 }}>
                    <span style={{ fontWeight: 700, fontSize: 13, letterSpacing: "0.04em" }}>{m.name}</span>
                    <Icon name="card" size={18} style={{ opacity: .6 }} />
                  </div>
                  <div className="mono" style={{ fontSize: 14, letterSpacing: "0.08em" }}>{m.num}</div>
                </button>
              ))}
              <button style={{ flexShrink: 0, width: 88, borderRadius: "var(--r-md)", border: "1.5px dashed var(--hairline-2)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 6, color: "var(--text-2)" }}>
                <Icon name="qr" size={22} /><span style={{ fontSize: 11, fontWeight: 600 }}>QR</span>
              </button>
            </div>
          </div>
        )}

        {/* Tip */}
        <div className="card" style={{ padding: 16, marginBottom: 8 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 4 }}>
            <Icon name="heart" size={18} style={{ color: "var(--danger)" }} />
            <span style={{ fontSize: 15, fontWeight: 600 }}>{t("addTip")}</span>
          </div>
          <p style={{ fontSize: 12.5, color: "var(--text-3)", margin: "0 0 13px" }}>{t("tipDesc")}</p>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 8 }}>
            {tips.map(tp => (
              <button key={tp} onClick={() => setTip(tp)} className="mono" style={{
                padding: "11px 0", borderRadius: "var(--r-sm)", fontSize: 13.5, fontWeight: 600,
                background: tip === tp ? "var(--inverse-bg)" : "var(--surface-2)",
                color: tip === tp ? "var(--inverse-text)" : "var(--text)",
              }}>{tp === 0 ? t("noTip") : (tp/1000) + "k"}</button>
            ))}
          </div>
        </div>
      </div>

      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)" }}>
        {timing === "split" && <div style={{ fontSize: 12, color: "var(--text-3)", textAlign: "center", marginBottom: 9 }}>{t("holdNotice")}</div>}
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div>
            <div className="h-eyebrow">{t("total")}</div>
            <div className="mono" style={{ fontSize: 19, fontWeight: 700 }}>{fmtSom(total)} <span style={{ fontSize: 12, color: "var(--text-3)" }}>{t("som")}</span></div>
          </div>
          <Button icon={timing==="now"?"shield":null} onClick={() => go("ownerConfirm")} style={{ flex: 1 }}>{t("confirmBooking")}</Button>
        </div>
      </div>
    </div>
  );
}

// ---------- Confirmation ----------
function OwnerConfirmation({ app }) {
  const { t, go } = app;
  const o = app.order || { w: SERVICE_SHOPS[0], time: "16:30", date: 6 };
  return (
    <div className="screen">
      <div className="screen-body" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 30px", textAlign: "center" }}>
        <div style={{ position: "relative", display: "grid", placeItems: "center", marginBottom: 28 }}>
          <div style={{ position: "absolute", width: 110, height: 110, borderRadius: "50%", background: "var(--success-dim)", animation: "pop-in .5s ease both" }} />
          <div style={{ width: 84, height: 84, borderRadius: "50%", background: "var(--success)", display: "grid", placeItems: "center", color: "#fff", animation: "pop-in .45s cubic-bezier(.16,1.4,.3,1) both .1s" }}>
            <Icon name="check" size={42} stroke={2.6} />
          </div>
        </div>
        <h1 className="rise" style={{ fontSize: 27, fontWeight: 700, letterSpacing: "-0.03em", margin: "0 0 12px" }}>{t("booked")}</h1>
        <p className="rise" style={{ fontSize: 15.5, lineHeight: 1.5, color: "var(--text-2)", margin: "0 0 26px", maxWidth: 300 }}>{t("bookedSub")}</p>

        <div className="card rise" style={{ width: "100%", padding: 16, textAlign: "left" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 14, paddingBottom: 14, borderBottom: "1px solid var(--hairline)" }}>
            <div className="ph" data-label="" style={{ width: 44, height: 44, borderRadius: 12 }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600 }}>{o.w.name}</div>
              <div style={{ fontSize: 12.5, color: "var(--text-2)" }}>{o.w.area}</div>
            </div>
            {o.w.tags && o.w.tags.includes("vip") && <Icon name="crown" size={16} style={{ color: "var(--gold)" }} />}
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ display: "flex", alignItems: "center", gap: 7, fontSize: 14, color: "var(--text-2)" }}><Icon name="calendar" size={16} /> {o.date}-dekabr</span>
            <span className="mono" style={{ fontSize: 18, fontWeight: 700 }}>{o.time}</span>
          </div>
        </div>
      </div>

      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", display: "flex", flexDirection: "column", gap: 10 }}>
        <Button variant="outline" icon="calendar">{t("addCalendar")}</Button>
        <Button onClick={() => { app.setTab("ownerBookings"); go("ownerApp"); }}>{t("viewBooking")}</Button>
      </div>
    </div>
  );
}

// ---------- Owner Bookings ----------
function OwnerBookings({ app }) {
  const { t, lang, go } = app;
  const [tab, setTab] = React.useState("upcoming");
  const list = OWNER_BOOKINGS.filter(b => tab === "upcoming" ? b.status === "upcoming" : b.status === "past");
  return (
    <div className="screen">
      <AppBar large title={t("navBookings")} />
      <div style={{ padding: "0 18px 14px" }}>
        <div className="seg">
          {[["upcoming",t("upcoming")],["past",t("past")]].map(([k,label]) => (
            <button key={k} className="seg-item" data-active={tab===k} onClick={() => setTab(k)}>{label}</button>
          ))}
        </div>
      </div>
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        {list.length === 0 ? (
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "70%", color: "var(--text-3)", gap: 12 }}>
            <Icon name="calendar" size={42} /><span style={{ fontSize: 14 }}>—</span>
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 13 }} className="stagger">
            {list.map(b => (
              <div key={b.id} className="card" style={{ padding: 15 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 13 }}>
                  <div className="ph" data-label="" style={{ width: 46, height: 46, borderRadius: 12 }} />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, fontWeight: 600 }}>{b.shop}</div>
                    <div style={{ fontSize: 12.5, color: "var(--text-2)" }}>{t(b.svc)} · {b.car}</div>
                  </div>
                  {b.status === "upcoming"
                    ? <span className="tag success">{t("upcoming")}</span>
                    : b.rated ? <Stars value={b.rated} size={13} /> : <span className="tag">{t("past")}</span>}
                </div>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", paddingTop: 13, borderTop: "1px solid var(--hairline)" }}>
                  <span style={{ display: "flex", alignItems: "center", gap: 7, fontSize: 13.5, color: "var(--text-2)" }}><Icon name="calendar" size={15} /> {b.date[lang]}</span>
                  <span className="mono" style={{ fontSize: 14, fontWeight: 600 }}>{fmtSom(b.price)}</span>
                </div>
                {b.status === "past" && (
                  <div style={{ display: "flex", gap: 9, marginTop: 13 }}>
                    {!b.rated && <Button variant="secondary" size="sm" icon="star" style={{ flex: 1 }}>{t("leaveReview")}</Button>}
                    <Button variant={b.rated ? "secondary" : "outline"} size="sm" icon="arrowR" onClick={() => go("ownerHome")} style={{ flex: 1 }}>{t("rebook")}</Button>
                  </div>
                )}
                {b.status === "upcoming" && (
                  <div style={{ display: "flex", gap: 9, marginTop: 13 }}>
                    <Button variant="secondary" size="sm" icon="route" style={{ flex: 1 }}>{t("route")}</Button>
                    <Button variant="secondary" size="sm" icon="phone" style={{ flex: 1 }}>{t("callShop")}</Button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ---------- Vehicles ----------
function OwnerVehicles({ app }) {
  const { t } = app;
  const [adding, setAdding] = React.useState(false);
  return (
    <div className="screen">
      <AppBar large title={t("myVehicles")} right={<button className="icon-btn" onClick={() => setAdding(true)}><Icon name="plus" size={22} /></button>} />
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }} className="stagger">
          {VEHICLES.map(c => (
            <div key={c.id} className="card" style={{ overflow: "hidden" }}>
              <div style={{ position: "relative", height: 130 }}>
                <div className="ph" data-label="AVTO FOTOSI" style={{ position: "absolute", inset: 0 }} />
                {c.primary && <span className="tag" style={{ position: "absolute", top: 12, left: 12, background: "var(--bg-elev)" }}>{t("primary")}</span>}
                <div style={{ position: "absolute", bottom: 12, right: 12 }}><Plate value={c.plate} size="lg" /></div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 12, padding: 14 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 16, fontWeight: 600 }}>{c.make}</div>
                  <div style={{ fontSize: 13, color: "var(--text-2)", display: "flex", alignItems: "center", gap: 6 }}><Icon name="disc" size={14} /> {c.size}</div>
                </div>
                <button className="icon-btn ghost"><Icon name="settings" size={20} /></button>
              </div>
            </div>
          ))}
          <div className="card" style={{ padding: 16, display: "flex", gap: 13, alignItems: "flex-start" }}>
            <div style={{ width: 40, height: 40, borderRadius: 11, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name="phone" size={20} /></div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14.5, fontWeight: 600, marginBottom: 3 }}>{t("callOwner")}</div>
              <p style={{ fontSize: 12.5, color: "var(--text-3)", margin: 0, lineHeight: 1.45 }}>{t("callOwnerDesc")}</p>
            </div>
            <Toggle on={true} />
          </div>
          <Button variant="outline" icon="plus" onClick={() => setAdding(true)}>{t("addCar")}</Button>
        </div>
      </div>

      <Sheet open={adding} onClose={() => setAdding(false)} title={t("addCar")}>
        <div style={{ display: "flex", flexDirection: "column", gap: 14, paddingBottom: 8 }}>
          <button className="ph" data-label="" style={{ height: 120, borderRadius: "var(--r-lg)", border: "1.5px dashed var(--hairline-2)", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 8, color: "var(--text-2)" }}>
            <Icon name="camera" size={26} /><span style={{ fontSize: 13, fontWeight: 600 }}>{t("carPhoto")}</span>
          </button>
          <div>
            <label className="sec-label" style={{ display: "block", marginBottom: 7 }}>{t("plate")}</label>
            <input className="field mono" placeholder="01 A 000 AA" style={{ letterSpacing: "0.06em", fontWeight: 600 }} />
          </div>
          <div>
            <label className="sec-label" style={{ display: "block", marginBottom: 7 }}>{t("makeModel")}</label>
            <input className="field" placeholder="Chevrolet Malibu" />
          </div>
          <div>
            <label className="sec-label" style={{ display: "block", marginBottom: 7 }}>{t("wheelSize")}</label>
            <input className="field mono" placeholder="R17 215/55" />
          </div>
          <Button onClick={() => setAdding(false)} style={{ marginTop: 4 }}>{t("save")}</Button>
        </div>
      </Sheet>
    </div>
  );
}

Object.assign(window, { OwnerHome, MapScreen, ServiceDetail, OwnerBooking, OwnerPayment, OwnerConfirmation, OwnerBookings, OwnerVehicles, PromoBanner });
