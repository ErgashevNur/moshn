// moshn-screens-account.jsx — SOS, Garage, Bookings, Profile, Notifications

// ---------- SOS ----------
function SOS({ app }) {
  const { t, go } = app;
  const [state, setState] = React.useState("idle"); // idle | calling | connected
  const [reason, setReason] = React.useState(null);
  const reasons = ["sos_flat","sos_burst","sos_air","sos_tool"];

  React.useEffect(() => {
    if (state === "calling") { const id = setTimeout(() => setState("connected"), 2600); return () => clearTimeout(id); }
  }, [state]);

  if (state === "connected") return (
    <div className="screen" style={{ background: "#0c0c0d" }} data-theme="dark">
      <div style={{ position: "absolute", inset: 0 }}><MapView theme="dark" /></div>
      <div style={{ position: "absolute", inset: 0, background: "linear-gradient(to bottom, rgba(0,0,0,.6), transparent 30%, transparent 55%, rgba(0,0,0,.85))" }} />
      {/* moving master pin */}
      <div style={{ position: "absolute", left: "42%", top: "38%", zIndex: 2 }}>
        <div style={{ width: 46, height: 46, borderRadius: "50%", background: "var(--success)", display: "grid", placeItems: "center", color: "#fff", boxShadow: "0 0 0 6px rgba(48,209,88,.25)" }}><Icon name="wrench" size={22} /></div>
      </div>
      <div style={{ position: "absolute", left: "62%", top: "60%", zIndex: 2 }}>
        <div style={{ width: 18, height: 18, borderRadius: "50%", background: "#3b82f6", border: "3px solid #fff", boxShadow: "0 0 0 5px rgba(59,130,246,.3)" }} />
      </div>

      <div style={{ position: "relative", zIndex: 3, marginTop: "auto", padding: "16px 18px calc(env(safe-area-inset-bottom,0) + 18px)", color: "#fff" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, justifyContent: "center", marginBottom: 14, color: "rgba(255,255,255,.7)", fontSize: 13 }}>
          <span style={{ width: 7, height: 7, borderRadius: "50%", background: "var(--success)" }} /> {t("sosShareLoc")}
        </div>
        <div style={{ background: "rgba(28,28,32,.85)", backdropFilter: "blur(20px)", borderRadius: 24, padding: 16, border: "1px solid rgba(255,255,255,.1)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 13, marginBottom: 14 }}>
            <div className="ph" data-label="" style={{ width: 52, height: 52, borderRadius: "50%" }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16, fontWeight: 600 }}>Bobur — {t("sosConnected").toLowerCase()}</div>
              <div style={{ fontSize: 13, color: "rgba(255,255,255,.6)", display: "flex", alignItems: "center", gap: 6 }}>
                <Icon name="starFill" size={12} style={{ color: "var(--gold)" }} /> 4.9 · {t("sosOnWay")} · 3 {t("min")}
              </div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <button className="btn btn-secondary" style={{ flex: 1, background: "rgba(255,255,255,.12)", color: "#fff" }}><Icon name="video" size={19} /> {t("videoCall")}</button>
            <button className="btn" style={{ flex: 1, background: "var(--danger)", color: "#fff" }} onClick={() => { setState("idle"); go("app"); }}><Icon name="phone" size={19} /> {t("endCall")}</button>
          </div>
        </div>
      </div>
    </div>
  );

  if (state === "calling") return (
    <div className="screen" style={{ background: "var(--danger)", alignItems: "center" }}>
      <div className="screen-body" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", color: "#fff", textAlign: "center", padding: 30 }}>
        <div style={{ position: "relative", display: "grid", placeItems: "center", marginBottom: 40 }}>
          {[0,1,2].map(i => <div key={i} style={{ position: "absolute", width: 120, height: 120, borderRadius: "50%", border: "2px solid rgba(255,255,255,.5)", animation: `pulse-ring 2.2s ease-out infinite ${i*0.7}s` }} />)}
          <div style={{ width: 100, height: 100, borderRadius: "50%", background: "rgba(255,255,255,.16)", display: "grid", placeItems: "center" }}><Icon name="wrench" size={40} /></div>
        </div>
        <h1 style={{ fontSize: 23, fontWeight: 700, margin: "0 0 10px" }}>{t("sosCalling")}</h1>
        <p style={{ fontSize: 15, opacity: .85, margin: 0 }}>{t("sosShareLoc")}</p>
      </div>
      <div style={{ padding: "0 24px calc(env(safe-area-inset-bottom,0) + 24px)", width: "100%" }}>
        <button className="btn" style={{ background: "rgba(0,0,0,.25)", color: "#fff" }} onClick={() => setState("idle")}>{t("cancel")}</button>
      </div>
    </div>
  );

  return (
    <div className="screen">
      <AppBar onBack={() => go("app")} title={t("sosTitle")} />
      <div className="screen-body" style={{ display: "flex", flexDirection: "column", padding: "10px 24px 24px" }}>
        <p style={{ fontSize: 14.5, color: "var(--text-2)", textAlign: "center", margin: "0 0 6px", lineHeight: 1.5 }}>{t("sosWhat")}</p>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 9, margin: "16px 0 auto" }}>
          {reasons.map(r => (
            <button key={r} onClick={() => setReason(r)} className="card" style={{
              padding: "16px 12px", textAlign: "center", fontSize: 13.5, fontWeight: 600,
              borderColor: reason === r ? "var(--danger)" : "var(--hairline)", borderWidth: 1.5,
              color: reason === r ? "var(--danger)" : "var(--text)",
            }}>{t(r)}</button>
          ))}
        </div>

        <div style={{ display: "grid", placeItems: "center", padding: "30px 0 18px" }}>
          <button onClick={() => setState("calling")} style={{ position: "relative", display: "grid", placeItems: "center", background: "none" }}>
            {[0,1].map(i => <div key={i} style={{ position: "absolute", width: 150, height: 150, borderRadius: "50%", border: "2px solid var(--danger)", opacity: .4, animation: `pulse-ring 2.4s ease-out infinite ${i*1.2}s` }} />)}
            <div style={{ width: 150, height: 150, borderRadius: "50%", background: "var(--danger)", color: "#fff", display: "grid", placeItems: "center", boxShadow: "0 16px 40px -8px var(--danger)" }}>
              <div style={{ textAlign: "center" }}>
                <div style={{ fontSize: 34, fontWeight: 800, letterSpacing: "0.08em", lineHeight: 1 }}>SOS</div>
                <div style={{ fontSize: 10.5, opacity: .85, marginTop: 6, fontWeight: 600 }}>{t("tagline").split("—")[0]}</div>
              </div>
            </div>
          </button>
        </div>
        <p style={{ fontSize: 13, color: "var(--text-3)", textAlign: "center", margin: 0 }}>{t("sosHold")}</p>
      </div>
    </div>
  );
}

// ---------- Garage (tab) ----------
function Garage({ app }) {
  const { t, go } = app;
  const [adding, setAdding] = React.useState(false);
  return (
    <div className="screen">
      <AppBar large title={t("garage")} right={<button className="icon-btn" onClick={() => setAdding(true)}><Icon name="plus" size={22} /></button>} />
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 14 }} className="stagger">
          {CARS.map(c => (
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

          {/* call-by-plate feature */}
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
          <button className="ph" data-label="" style={{ height: 120, borderRadius: "var(--r-lg)", border: "1.5px dashed var(--hairline-2)", display: "flex", flexDirection: "column", gap: 8, color: "var(--text-2)" }}>
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

function Toggle({ on: init = false }) {
  const [on, setOn] = React.useState(init);
  return (
    <button onClick={() => setOn(o => !o)} style={{ width: 48, height: 29, borderRadius: 99, padding: 3, background: on ? "var(--success)" : "var(--surface-3)", flexShrink: 0, transition: "background .2s ease" }}>
      <div style={{ width: 23, height: 23, borderRadius: "50%", background: "#fff", transform: on ? "translateX(19px)" : "none", transition: "transform .2s ease", boxShadow: "0 1px 3px rgba(0,0,0,.3)" }} />
    </button>
  );
}

// ---------- Bookings (tab) ----------
function Bookings({ app }) {
  const { t, lang, go } = app;
  const [tab, setTab] = React.useState("upcoming");
  const list = BOOKINGS.filter(b => tab === "upcoming" ? b.status === "upcoming" : b.status === "past");
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
            {list.map(b => {
              const svc = SERVICES.find(s => s.id === b.svc.replace("svc_",""))  || SERVICES.find(s => s.key === b.svc);
              return (
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
                      <Button variant={b.rated ? "secondary" : "outline"} size="sm" icon="arrowR" onClick={() => go("home")} style={{ flex: 1 }}>{t("rebook")}</Button>
                    </div>
                  )}
                  {b.status === "upcoming" && (
                    <div style={{ display: "flex", gap: 9, marginTop: 13 }}>
                      <Button variant="secondary" size="sm" icon="route" style={{ flex: 1 }}>{t("route")}</Button>
                      <Button variant="secondary" size="sm" icon="phone" style={{ flex: 1 }}>{t("callShop")}</Button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

// ---------- Profile (tab) ----------
function Profile({ app }) {
  const { t, go } = app;
  return (
    <div className="screen">
      <AppBar large title={t("profile")} onBack={app.fromHome ? () => go("home") : null} />
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        <div className="card" style={{ display: "flex", alignItems: "center", gap: 14, padding: 16, marginBottom: 22 }}>
          <div className="ph" data-label="" style={{ width: 60, height: 60, borderRadius: "50%" }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 17, fontWeight: 600 }}>Akmal Karimov</div>
            <div className="mono" style={{ fontSize: 13, color: "var(--text-2)" }}>+998 (90) 123-45-67</div>
          </div>
          <button className="icon-btn ghost"><Icon name="chevR" size={20} /></button>
        </div>

        {/* language */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 2px 11px" }}>
          <span style={{ display: "flex", alignItems: "center", gap: 11, fontSize: 15 }}><Icon name="globe" size={20} style={{ color: "var(--text-2)" }} /> {t("language")}</span>
          <LangToggle app={app} />
        </div>
        {/* appearance */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "11px 2px 16px" }}>
          <span style={{ display: "flex", alignItems: "center", gap: 11, fontSize: 15 }}><Icon name={app.theme==="dark"?"moon":"sun"} size={20} style={{ color: "var(--text-2)" }} /> {t("appearance")}</span>
          <div className="seg" style={{ width: 150 }}>
            <button className="seg-item" data-active={app.theme==="light"} onClick={() => app.setTheme("light")} style={{ fontSize: 12.5 }}>{t("themeLight")}</button>
            <button className="seg-item" data-active={app.theme==="dark"} onClick={() => app.setTheme("dark")} style={{ fontSize: 12.5 }}>{t("themeDark")}</button>
          </div>
        </div>

        <div className="list-card" style={{ marginBottom: 22 }}>
          {[["wallet",t("paymentMethods")],["chat",t("myReviews")],["bell",t("notifications"),()=>go("notifications")],["shield",t("help")]].map(([ic,label,fn],i,arr) => (
            <button key={i} className="row" style={{ width: "100%", textAlign: "left" }} onClick={fn}>
              <Icon name={ic} size={20} style={{ color: "var(--text-2)" }} />
              <span style={{ flex: 1, fontSize: 15 }}>{label}</span>
              <Icon name="chevR" size={18} style={{ color: "var(--text-3)" }} />
            </button>
          ))}
        </div>

        {/* partner promo */}
        <button className="card" style={{ width: "100%", textAlign: "left", display: "flex", alignItems: "center", gap: 13, padding: 16, marginBottom: 22 }} onClick={() => app.setShowPartner && app.setShowPartner(true)}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: "var(--inverse-bg)", color: "var(--inverse-text)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name="wrench" size={22} /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14.5, fontWeight: 600 }}>{t("forPartners")}</div>
            <div style={{ fontSize: 12, color: "var(--text-3)" }}>{t("partnerDesc")}</div>
          </div>
          <Icon name="chevR" size={18} style={{ color: "var(--text-3)" }} />
        </button>

        <button className="row" style={{ width: "100%", color: "var(--danger)", fontSize: 15, fontWeight: 600, justifyContent: "center", gap: 8 }} onClick={() => go("onboarding")}>
          <Icon name="logout" size={19} /> {t("logout")}
        </button>
      </div>
    </div>
  );
}

// ---------- Notifications ----------
function Notifications({ app }) {
  const { t, go } = app;
  return (
    <div className="screen">
      <AppBar onBack={() => go("app")} title={t("notifications")} />
      <div className="screen-body" style={{ padding: "4px 18px 24px" }}>
        {/* seasonal smart push — featured */}
        <div className="card rise" style={{ padding: 18, marginBottom: 16, border: "1.5px solid var(--gold)", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", right: -24, top: -24, opacity: .12 }}><Icon name="snow" size={120} style={{ color: "var(--gold)" }} /></div>
          <span className="tag gold" style={{ marginBottom: 12 }}><Icon name="spark" size={12} /> SMART PUSH</span>
          <h3 style={{ fontSize: 17, fontWeight: 700, letterSpacing: "-0.02em", margin: "0 0 7px", position: "relative" }}>{t("seasonTitle")}</h3>
          <p style={{ fontSize: 13.5, lineHeight: 1.5, color: "var(--text-2)", margin: "0 0 15px", position: "relative" }}>{t("seasonBody")}</p>
          <Button size="sm" iconR="arrowR" onClick={() => go("home")} style={{ width: "auto", position: "relative" }}>{t("bookNow")}</Button>
        </div>

        <div className="list-card">
          {[
            { ic: "checkCircle", c: "var(--success)", title: { uz: "Bandlov tasdiqlandi", ru: "Запись подтверждена" }, sub: { uz: "Shinmaster Pro · Bugun 16:30", ru: "Shinmaster Pro · Сегодня 16:30" }, ago: "1 soat" },
            { ic: "heart", c: "var(--danger)", title: { uz: "Ustaga rahmat aytildi", ru: "Мастеру отправлены чаевые" }, sub: { uz: "10 000 so‘m chaevoy", ru: "Чаевые 10 000 сум" }, ago: "2 kun" },
            { ic: "star", c: "var(--gold)", title: { uz: "Sharhingizni qoldiring", ru: "Оставьте отзыв" }, sub: { uz: "Avto Shina 24/7", ru: "Avto Shina 24/7" }, ago: "3 kun" },
          ].map((n, i) => (
            <div key={i} className="row">
              <div style={{ width: 40, height: 40, borderRadius: 11, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name={n.ic} size={20} style={{ color: n.c }} /></div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14.5, fontWeight: 600 }}>{n.title[app.lang]}</div>
                <div style={{ fontSize: 12.5, color: "var(--text-2)" }}>{n.sub[app.lang]}</div>
              </div>
              <span style={{ fontSize: 11.5, color: "var(--text-3)" }}>{n.ago}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SOS, Garage, Bookings, Profile, Notifications, Toggle });
