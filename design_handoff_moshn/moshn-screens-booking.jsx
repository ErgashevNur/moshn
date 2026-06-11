// moshn-screens-booking.jsx — booking, payment, confirmation

// ---------- Booking ----------
function Booking({ app }) {
  const { t, lang, go } = app;
  const w = app.shop || WORKSHOPS[0];
  const [svc, setSvc] = React.useState(app.svc || "swap");
  const [car, setCar] = React.useState(CARS[0].id);
  const [date, setDate] = React.useState(6);
  const [time, setTime] = React.useState(null);
  const svcObj = SERVICES.find(s => s.id === svc);

  return (
    <div className="screen">
      <AppBar onBack={() => go("detail")} title={t("book")} />
      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        {/* shop row */}
        <div className="card" style={{ display: "flex", alignItems: "center", gap: 12, padding: 12, marginBottom: 22 }}>
          <div className="ph" data-label="" style={{ width: 46, height: 46, borderRadius: 12 }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600 }}>{w.name}</div>
            <div style={{ fontSize: 12.5, color: "var(--text-2)", display: "flex", alignItems: "center", gap: 4 }}><Icon name="pin" size={13} /> {w.area}</div>
          </div>
          {w.tags.includes("vip") && <Icon name="crown" size={16} style={{ color: "var(--gold)" }} />}
        </div>

        {/* service */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("chooseService")}</h3>
        <div style={{ display: "flex", gap: 8, overflowX: "auto", paddingBottom: 6, marginBottom: 22 }}>
          {SERVICES.map(s => (
            <button key={s.id} className="chip" data-active={svc === s.id} onClick={() => setSvc(s.id)} style={{ flexShrink: 0 }}>
              <Icon name={s.icon} size={16} /> {t(s.key)}
            </button>
          ))}
        </div>

        {/* car */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("yourCar")}</h3>
        <div style={{ display: "flex", flexDirection: "column", gap: 9, marginBottom: 22 }}>
          {CARS.map(c => (
            <button key={c.id} onClick={() => setCar(c.id)} className="card" style={{
              display: "flex", alignItems: "center", gap: 12, padding: 12, textAlign: "left",
              borderColor: car === c.id ? "var(--text-3)" : "var(--hairline)",
              borderWidth: 1.5,
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

        {/* date */}
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

        {/* time */}
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
        <Button disabled={!time} iconR="arrowR" onClick={() => { app.setOrder({ w, svc, car, date, time, price: svcObj.price }); go("payment"); }} style={{ flex: 1 }}>{t("toPayment")}</Button>
      </div>
    </div>
  );
}

// ---------- Payment ----------
function Payment({ app }) {
  const { t, lang, go } = app;
  const o = app.order || { w: WORKSHOPS[0], svc: "swap", price: 80000, date: 6, time: "16:30", car: CARS[0].id };
  const svcObj = SERVICES.find(s => s.id === o.svc);
  const car = CARS.find(c => c.id === o.car) || CARS[0];
  const [timing, setTiming] = React.useState("now");
  const [method, setMethod] = React.useState("uzcard");
  const [tip, setTip] = React.useState(0);
  const tips = [0, 10000, 20000, 50000];

  const timingOpts = [
    { id: "now",  icon: "card",   title: t("payNow"),       desc: t("selectCard") },
    { id: "later",icon: "clock",  title: t("payLater"),     desc: t("payLaterDesc") },
    { id: "split",icon: "wallet", title: t("installment"),  desc: t("installmentDesc") },
  ];
  const total = o.price + tip;

  return (
    <div className="screen">
      <AppBar onBack={() => go("booking")} title={t("payment")} />
      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        {/* summary */}
        <div className="card" style={{ padding: 16, marginBottom: 22 }}>
          <h3 className="sec-label" style={{ marginBottom: 13 }}>{t("orderSummary")}</h3>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 14 }}>
            <div className="ph" data-label="" style={{ width: 44, height: 44, borderRadius: 12 }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 600 }}>{o.w.name}</div>
              <div style={{ fontSize: 12.5, color: "var(--text-2)" }}>{t(svcObj.key)} · {car.plate}</div>
            </div>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13.5, paddingTop: 13, borderTop: "1px solid var(--hairline)" }}>
            <span style={{ color: "var(--text-2)", display: "flex", alignItems: "center", gap: 6 }}><Icon name="calendar" size={15} /> {o.date}-noyabr</span>
            <span style={{ fontWeight: 600 }} className="mono">{o.time}</span>
          </div>
        </div>

        {/* timing */}
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

        {/* card / qr (when pay now) */}
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

        {/* tips */}
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
          <Button icon={timing==="now"?"shield":null} onClick={() => go("confirm")} style={{ flex: 1 }}>{t("confirmBooking")}</Button>
        </div>
      </div>
    </div>
  );
}

// ---------- Confirmation ----------
function Confirmation({ app }) {
  const { t, go } = app;
  const o = app.order || { w: WORKSHOPS[0], time: "16:30", date: 6 };
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
            <span style={{ display: "flex", alignItems: "center", gap: 7, fontSize: 14, color: "var(--text-2)" }}><Icon name="calendar" size={16} /> {o.date}-noyabr</span>
            <span className="mono" style={{ fontSize: 18, fontWeight: 700 }}>{o.time}</span>
          </div>
        </div>
      </div>

      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", display: "flex", flexDirection: "column", gap: 10 }}>
        <Button variant="outline" icon="calendar">{t("addCalendar")}</Button>
        <Button onClick={() => { app.setTab("bookings"); go("app"); }}>{t("viewBooking")}</Button>
      </div>
    </div>
  );
}

Object.assign(window, { Booking, Payment, Confirmation });
