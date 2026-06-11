// shina24-screens-service.jsx — Service side: Dashboard, Bookings, CRM, Stats, Profile

// Status color helper
function statusColor(s) {
  if (s === "confirmed")   return "var(--success)";
  if (s === "in_progress") return "var(--gold)";
  if (s === "completed")   return "var(--text-3)";
  if (s === "cancelled")   return "var(--danger)";
  return "var(--text-2)"; // pending
}

// ---------- Incoming booking notification card ----------
function IncomingCard({ t, lang, booking, onAccept, onReject }) {
  return (
    <div className="rise" style={{
      background: "var(--surface)", borderRadius: "var(--r-xl)",
      border: "1.5px solid var(--hairline-2)", padding: 18, marginBottom: 16,
      boxShadow: "var(--shadow-2)", position: "relative", overflow: "hidden",
    }}>
      {/* Pulsing indicator */}
      <div style={{ position: "absolute", top: 16, right: 16 }}>
        <div style={{ position: "relative", width: 10, height: 10 }}>
          <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: "var(--success)", opacity: .5, animation: "pulse-ring 1.8s ease-out infinite" }} />
          <div style={{ width: 10, height: 10, borderRadius: "50%", background: "var(--success)" }} />
        </div>
      </div>

      <div className="h-eyebrow" style={{ color: "var(--success)", marginBottom: 12 }}>{t("newBookingIncoming")}</div>

      <div style={{ display: "flex", gap: 12, marginBottom: 14 }}>
        <div className="ph" data-label="" style={{ width: 44, height: 44, borderRadius: "50%", flexShrink: 0 }} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 600 }}>{booking.customerName}</div>
          <div className="mono" style={{ fontSize: 12.5, color: "var(--text-2)" }}>{booking.phone}</div>
        </div>
      </div>

      <div className="list-card" style={{ marginBottom: 14 }}>
        <div className="row" style={{ padding: "10px 14px" }}>
          <Icon name="car" size={16} style={{ color: "var(--text-3)" }} />
          <span style={{ fontSize: 13.5 }}>{booking.make}</span>
          <Plate value={booking.plate} />
        </div>
        <div className="row" style={{ padding: "10px 14px" }}>
          <Icon name="wrench" size={16} style={{ color: "var(--text-3)" }} />
          <span style={{ flex: 1, fontSize: 13.5 }}>G'ildirak almashtirish</span>
          <span className="mono" style={{ fontSize: 13.5, fontWeight: 600 }}>{booking.time}</span>
        </div>
      </div>

      <div style={{ display: "flex", gap: 10 }}>
        <button className="btn btn-secondary btn-sm" style={{ flex: 1 }} onClick={onReject}>
          <Icon name="x" size={17} /> {t("rejectBooking")}
        </button>
        <button className="btn btn-primary btn-sm" style={{ flex: 1 }} onClick={onAccept}>
          <Icon name="check" size={17} /> {t("confirmBookingAction")}
        </button>
      </div>
    </div>
  );
}

// ---------- Service Dashboard (Today) ----------
function ServiceDashboard({ app }) {
  const { t, lang, go } = app;
  const [showIncoming, setShowIncoming] = React.useState(true);
  const todayList = SERVICE_BOOKINGS_TODAY;

  const statusBg = { pending: "var(--surface-2)", confirmed: "var(--success-dim)", in_progress: "var(--gold-dim)", completed: "var(--surface-2)", cancelled: "var(--danger-dim)" };

  return (
    <div className="screen">
      <div className="appbar" style={{ paddingTop: 6 }}>
        <div style={{ flex: 1 }}>
          <div className="h-eyebrow" style={{ fontSize: 10 }}>Shinmaster Pro</div>
          <div style={{ fontSize: 19, fontWeight: 700, letterSpacing: "-0.02em" }}>{t("todayBookings")}</div>
        </div>
        <button className="icon-btn" onClick={() => go("serviceNotifications")} style={{ position: "relative" }}>
          <Icon name="bell" size={20} />
          {showIncoming && <span style={{ position: "absolute", top: 9, right: 10, width: 8, height: 8, borderRadius: "50%", background: "var(--danger)", border: "2px solid var(--surface)" }} />}
        </button>
      </div>

      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        {/* Quick stats row */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10, marginBottom: 20 }}>
          {[
            { label: t("totalBookings"), value: "5", icon: "calendar", color: "var(--text)" },
            { label: t("totalRevenue"),  value: "270k", icon: "wallet", color: "var(--success)" },
            { label: t("avgRating"),     value: "4.9", icon: "starFill", color: "var(--gold)" },
          ].map((s,i) => (
            <div key={i} className="card" style={{ padding: "14px 12px", textAlign: "center" }}>
              <Icon name={s.icon} size={18} style={{ color: s.color, marginBottom: 6 }} />
              <div style={{ fontSize: 17, fontWeight: 700, letterSpacing: "-0.02em", color: s.color }}>{s.value}</div>
              <div style={{ fontSize: 10.5, color: "var(--text-3)", marginTop: 2, fontWeight: 600 }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Incoming new booking */}
        {showIncoming && (
          <IncomingCard t={t} lang={lang} booking={NEW_BOOKING_INCOMING}
            onAccept={() => setShowIncoming(false)}
            onReject={() => setShowIncoming(false)} />
        )}

        {/* Today's timeline */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("todayBookings")}</h3>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }} className="stagger">
          {todayList.map(b => {
            const svcObj = SERVICES.find(s => s.id === b.svc) || SERVICES[0];
            return (
              <button key={b.id} onClick={() => { app.setServiceBooking(b); go("serviceBookingDetail"); }}
                className="card" style={{ display: "flex", gap: 13, padding: 13, textAlign: "left", width: "100%" }}>
                {/* Time */}
                <div style={{ width: 48, flexShrink: 0, textAlign: "center" }}>
                  <div className="mono" style={{ fontSize: 14, fontWeight: 700 }}>{b.time}</div>
                  <div style={{ width: 1, height: 30, background: "var(--hairline)", margin: "6px auto 0" }} />
                </div>
                {/* Content */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                    <div className="ph" data-label="" style={{ width: 32, height: 32, borderRadius: "50%", flexShrink: 0 }} />
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontSize: 14, fontWeight: 600, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{b.customerName}</div>
                      <div style={{ fontSize: 11.5, color: "var(--text-3)" }}>{t(svcObj.key)}</div>
                    </div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <Plate value={b.plate} />
                    <div style={{ marginLeft: "auto" }}>
                      <StatusChip status={b.status} t={t} />
                    </div>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ---------- Booking detail (service side) ----------
function ServiceBookingDetail({ app }) {
  const { t, lang, go } = app;
  const b = app.serviceBooking || SERVICE_BOOKINGS_TODAY[0];
  const svcObj = SERVICES.find(s => s.id === b.svc) || SERVICES[0];
  const [status, setStatus] = React.useState(b.status);

  const actionMap = {
    pending:     { label: t("confirmBookingAction"), icon: "check",      next: "confirmed",   variant: "primary" },
    confirmed:   { label: t("startService"),          icon: "timerPlay",  next: "in_progress", variant: "primary" },
    in_progress: { label: t("finishService"),         icon: "checkCircle",next: "completed",   variant: "primary" },
    completed:   { label: t("takePayment"),           icon: "cashIn",     next: "payment",     variant: "primary" },
  };
  const action = actionMap[status];

  return (
    <div className="screen">
      <AppBar onBack={() => go("serviceApp")} title={t("bookingDetails")} />
      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        {/* Status banner */}
        <div style={{
          display: "flex", alignItems: "center", gap: 10, padding: "12px 16px",
          borderRadius: "var(--r-md)", marginBottom: 22,
          background: status === "completed" ? "var(--success-dim)" : status === "in_progress" ? "var(--gold-dim)" : status === "confirmed" ? "var(--success-dim)" : "var(--surface-2)",
          color: statusColor(status), fontWeight: 600, fontSize: 14,
        }}>
          <Icon name={status === "in_progress" ? "timerPlay" : status === "completed" ? "checkCircle" : "clock"} size={18} />
          <StatusChip status={status} t={t} />
          <div style={{ flex: 1 }} />
          <span className="mono" style={{ fontSize: 13 }}>{b.time}</span>
        </div>

        {/* Customer */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("customerInfo")}</h3>
        <div className="card" style={{ display: "flex", alignItems: "center", gap: 13, padding: 14, marginBottom: 16 }}>
          <div className="ph" data-label="" style={{ width: 48, height: 48, borderRadius: "50%", flexShrink: 0 }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600 }}>{b.customerName}</div>
            <div className="mono" style={{ fontSize: 13, color: "var(--text-2)" }}>{b.phone}</div>
          </div>
          <button className="icon-btn" style={{ background: "var(--surface-2)", border: "none" }}><Icon name="phone" size={20} /></button>
        </div>

        {/* Vehicle */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("vehicleInfo")}</h3>
        <div className="card" style={{ display: "flex", alignItems: "center", gap: 13, padding: 14, marginBottom: 16 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}>
            <Icon name="car" size={22} />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 600 }}>{b.make}</div>
            <div style={{ fontSize: 12.5, color: "var(--text-2)" }}>G'ildirak o'lchami: R15</div>
          </div>
          <Plate value={b.plate} />
        </div>

        {/* Service */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("chooseService")}</h3>
        <div className="list-card" style={{ marginBottom: 16 }}>
          <div className="row" style={{ padding: "14px 16px" }}>
            <div style={{ width: 38, height: 38, borderRadius: 11, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name={svcObj.icon} size={20} /></div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14.5, fontWeight: 600 }}>{t(svcObj.key)}</div>
              <div style={{ fontSize: 12.5, color: "var(--text-3)" }}>≈ {svcObj.dur} {t("min")}</div>
            </div>
            <div className="mono" style={{ fontSize: 15, fontWeight: 700 }}>{fmtSom(b.price)}</div>
          </div>
        </div>

        {/* Notes */}
        {status !== "completed" && (
          <div style={{ marginBottom: 8 }}>
            <h3 className="sec-label" style={{ marginBottom: 9 }}>{t("notes")}</h3>
            <textarea className="field" placeholder={t("notesPlaceholder")} style={{ height: 80, padding: "12px 16px", resize: "none", lineHeight: 1.5 }} />
          </div>
        )}
      </div>

      {/* Actions */}
      {status !== "completed" && status !== "cancelled" && (
        <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)", display: "flex", gap: 10 }}>
          {status === "pending" && (
            <Button variant="secondary" size="sm" style={{ width: "auto", paddingInline: 18 }} onClick={() => setStatus("cancelled")}>
              <Icon name="x" size={17} /> {t("cancelBooking")}
            </Button>
          )}
          {action && (
            <Button icon={action.icon} onClick={() => {
              if (action.next === "payment") go("servicePaymentReceipt");
              else setStatus(action.next);
            }} style={{ flex: 1 }}>
              {action.label}
            </Button>
          )}
        </div>
      )}
      {status === "completed" && (
        <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)" }}>
          <Button icon="cashIn" onClick={() => go("servicePaymentReceipt")}>{t("takePayment")}</Button>
        </div>
      )}
    </div>
  );
}

// ---------- Payment receipt (service side) ----------
function ServicePaymentReceipt({ app }) {
  const { t, go } = app;
  const b = app.serviceBooking || SERVICE_BOOKINGS_TODAY[0];
  const svcObj = SERVICES.find(s => s.id === b.svc) || SERVICES[0];
  const [method, setMethod] = React.useState("qr");
  const [paid, setPaid] = React.useState(false);

  if (paid) return (
    <div className="screen">
      <div className="screen-body" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 30px", textAlign: "center" }}>
        <div style={{ position: "relative", display: "grid", placeItems: "center", marginBottom: 28 }}>
          <div style={{ position: "absolute", width: 110, height: 110, borderRadius: "50%", background: "var(--success-dim)", animation: "pop-in .5s ease both" }} />
          <div style={{ width: 84, height: 84, borderRadius: "50%", background: "var(--success)", display: "grid", placeItems: "center", color: "#fff", animation: "pop-in .45s cubic-bezier(.16,1.4,.3,1) both .1s" }}>
            <Icon name="check" size={42} stroke={2.6} />
          </div>
        </div>
        <h1 className="rise" style={{ fontSize: 27, fontWeight: 700, letterSpacing: "-0.03em", margin: "0 0 12px" }}>{t("paymentReceived")}</h1>
        <p className="rise" style={{ fontSize: 15.5, lineHeight: 1.5, color: "var(--text-2)", margin: "0 0 26px" }}>
          {b.customerName} · <span className="mono" style={{ fontWeight: 600 }}>{fmtSom(b.price)} {t("som")}</span>
        </p>
      </div>
      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)" }}>
        <Button onClick={() => go("serviceApp")}>{t("done")}</Button>
      </div>
    </div>
  );

  return (
    <div className="screen">
      <AppBar onBack={() => go("serviceBookingDetail")} title={t("paymentReceipt")} />
      <div className="screen-body" style={{ padding: "4px 18px 20px" }}>
        {/* Summary */}
        <div className="card" style={{ padding: 16, marginBottom: 22 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div>
              <div style={{ fontSize: 13, color: "var(--text-2)", marginBottom: 4 }}>{b.customerName} · {t(svcObj.key)}</div>
              <div className="mono" style={{ fontSize: 28, fontWeight: 800, letterSpacing: "-0.02em" }}>{fmtSom(b.price)}</div>
              <div style={{ fontSize: 13, color: "var(--text-3)" }}>{t("som")}</div>
            </div>
            <Plate value={b.plate} />
          </div>
        </div>

        {/* Method tabs */}
        <div className="seg" style={{ marginBottom: 24 }}>
          <button className="seg-item" data-active={method === "qr"} onClick={() => setMethod("qr")}>
            <Icon name="qr" size={15} style={{ marginRight: 5 }} /> {t("qrPayment")}
          </button>
          <button className="seg-item" data-active={method === "cash"} onClick={() => setMethod("cash")}>
            <Icon name="cashIn" size={15} style={{ marginRight: 5 }} /> {t("cashPayment")}
          </button>
        </div>

        {method === "qr" ? (
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
            {/* Mock QR */}
            <div style={{ width: 220, height: 220, borderRadius: 20, background: "var(--bg-elev)", border: "1px solid var(--hairline)", padding: 18, display: "grid", placeItems: "center" }}>
              <svg viewBox="0 0 100 100" width="184" height="184">
                {/* QR corners */}
                {[[2,2],[73,2],[2,73]].map(([x,y],i) => (
                  <g key={i} transform={`translate(${x},${y})`}>
                    <rect width="25" height="25" rx="4" fill="var(--text)" />
                    <rect x="4" y="4" width="17" height="17" rx="2" fill="var(--bg)" />
                    <rect x="7" y="7" width="11" height="11" rx="1" fill="var(--text)" />
                  </g>
                ))}
                {/* QR data blocks (random pattern) */}
                {[
                  [30,2],[34,2],[38,2],[46,2],[50,2],[58,2],[62,2],[66,2],
                  [30,6],[38,6],[42,6],[54,6],[62,6],[70,6],[74,6],[78,6],[82,6],[86,6],[90,6],
                  [30,10],[34,10],[42,10],[50,10],[58,10],[66,10],[70,10],[78,10],[82,10],[90,10],[94,10],
                  [30,14],[38,14],[42,14],[50,14],[62,14],[70,14],[86,14],[94,14],
                  [30,18],[34,18],[38,18],[46,18],[54,18],[58,18],[66,18],[70,18],[78,18],[82,18],[86,18],[90,18],
                  [2,30],[6,30],[14,30],[18,30],[26,30],[30,30],[34,30],[38,30],[46,30],[54,30],[62,30],[66,30],[70,30],[78,30],[82,30],[86,30],[90,30],[94,30],
                  [2,34],[10,34],[18,34],[26,34],[34,34],[42,34],[50,34],[58,34],[66,34],[74,34],[82,34],[90,34],
                  [2,38],[6,38],[10,38],[18,38],[30,38],[38,38],[46,38],[54,38],[66,38],[74,38],[78,38],[86,38],[94,38],
                  [2,42],[10,42],[22,42],[30,42],[42,42],[50,42],[58,42],[66,42],[70,42],[82,42],[90,42],[94,42],
                  [2,46],[6,46],[14,46],[22,46],[26,46],[38,46],[46,46],[54,46],[62,46],[74,46],[78,46],[82,46],
                  [2,50],[10,50],[18,50],[26,50],[34,50],[42,50],[50,50],[62,50],[70,50],[78,50],[86,50],[90,50],[94,50],
                  [73,30],[77,30],[81,30],[85,30],[89,30],[93,30],
                  [73,34],[81,34],[93,34],[73,38],[77,38],[81,38],[85,38],[89,38],[93,38],
                  [73,42],[77,42],[81,42],[85,42],
                  [73,46],[81,46],[85,46],[89,46],[93,46],
                  [73,50],[77,50],[85,50],[89,50],[93,50],
                ].map(([x,y],i) => <rect key={i} x={x} y={y} width="3" height="3" fill="var(--text)" />)}
              </svg>
            </div>
            <p style={{ fontSize: 13.5, color: "var(--text-2)", textAlign: "center", lineHeight: 1.5, margin: 0, maxWidth: 260 }}>
              {t("qrHint")}
            </p>
          </div>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 20 }}>
            <div style={{ width: 120, height: 120, borderRadius: "50%", background: "var(--surface)", border: "1px solid var(--hairline)", display: "grid", placeItems: "center" }}>
              <Icon name="cashIn" size={52} style={{ color: "var(--text-2)" }} />
            </div>
            <div style={{ textAlign: "center" }}>
              <div className="h-eyebrow" style={{ marginBottom: 6 }}>{t("total")}</div>
              <div className="mono" style={{ fontSize: 32, fontWeight: 800, letterSpacing: "-0.03em" }}>{fmtSom(b.price)}</div>
              <div style={{ fontSize: 14, color: "var(--text-3)", marginTop: 4 }}>{t("som")}</div>
            </div>
          </div>
        )}
      </div>

      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)" }}>
        <Button icon="checkCircle" onClick={() => setPaid(true)}>{t("receivePayment")}</Button>
      </div>
    </div>
  );
}

// ---------- All bookings (service) ----------
function ServiceAllBookings({ app }) {
  const { t, lang, go } = app;
  const [statusFilter, setStatusFilter] = React.useState("all");
  const statuses = ["all", "pending", "confirmed", "in_progress", "completed", "cancelled"];
  const statusLabels = { all: "Barchasi", pending: t("bookingPending"), confirmed: t("bookingConfirmed"), in_progress: t("bookingInProgress"), completed: t("bookingCompleted"), cancelled: t("bookingCancelled") };
  const list = statusFilter === "all" ? SERVICE_BOOKINGS_TODAY : SERVICE_BOOKINGS_TODAY.filter(b => b.status === statusFilter);

  return (
    <div className="screen">
      <AppBar large title={t("navAllBooks")} />
      {/* Date selector */}
      <div style={{ padding: "0 18px 10px", display: "flex", gap: 8, overflowX: "auto" }}>
        {DATES.slice(0,5).map((d,i) => (
          <button key={d.d} style={{
            flexShrink: 0, padding: "7px 14px", borderRadius: "var(--r-full)",
            background: i === 0 ? "var(--inverse-bg)" : "var(--surface)",
            color: i === 0 ? "var(--inverse-text)" : "var(--text)",
            border: "1px solid var(--hairline)", fontSize: 13, fontWeight: 600,
          }}>
            {d.label ? t(d.label) : `${d.d} dek`}
          </button>
        ))}
      </div>
      {/* Status filter chips */}
      <div style={{ padding: "0 18px 14px", display: "flex", gap: 8, overflowX: "auto" }}>
        {statuses.map(s => (
          <button key={s} className="chip" data-active={statusFilter === s} onClick={() => setStatusFilter(s)} style={{ flexShrink: 0, fontSize: 12.5 }}>
            {statusLabels[s]}
          </button>
        ))}
      </div>
      <div className="screen-body" style={{ padding: "0 18px 28px" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 11 }} className="stagger">
          {list.map(b => {
            const svcObj = SERVICES.find(s => s.id === b.svc) || SERVICES[0];
            return (
              <button key={b.id} onClick={() => { app.setServiceBooking(b); go("serviceBookingDetail"); }}
                className="card" style={{ display: "flex", gap: 13, padding: 13, textAlign: "left", width: "100%" }}>
                <div className="ph" data-label="" style={{ width: 44, height: 44, borderRadius: "50%", flexShrink: 0 }} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 5 }}>
                    <span style={{ fontSize: 15, fontWeight: 600 }}>{b.customerName}</span>
                    <StatusChip status={b.status} t={t} />
                  </div>
                  <div style={{ fontSize: 12.5, color: "var(--text-2)", marginBottom: 5 }}>{t(svcObj.key)}</div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <Plate value={b.plate} />
                    <span className="mono" style={{ fontSize: 13, color: "var(--text-3)", marginLeft: "auto" }}>{b.time}</span>
                  </div>
                </div>
                <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", justifyContent: "space-between", flexShrink: 0 }}>
                  <Icon name="chevR" size={16} style={{ color: "var(--text-3)" }} />
                  <div className="mono" style={{ fontSize: 14, fontWeight: 600 }}>{fmtSom(b.price)}</div>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ---------- CRM — customer list ----------
function CRMList({ app }) {
  const { t, lang, go } = app;
  const [query, setQuery] = React.useState("");
  const filtered = CRM_CUSTOMERS.filter(c =>
    c.name.toLowerCase().includes(query.toLowerCase()) || c.phone.includes(query)
  );

  return (
    <div className="screen">
      <AppBar large title={t("customers")} />
      <div style={{ padding: "0 18px 10px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, height: 46, padding: "0 14px", borderRadius: "var(--r-full)", background: "var(--surface)", border: "1px solid var(--hairline)" }}>
          <Icon name="search" size={18} style={{ color: "var(--text-3)" }} />
          <input value={query} onChange={e => setQuery(e.target.value)} placeholder={t("searchCustomer")} style={{ flex: 1, background: "transparent", border: "none", outline: "none", fontSize: 14.5, color: "var(--text)" }} />
          {query && <button onClick={() => setQuery("")} style={{ color: "var(--text-3)" }}><Icon name="x" size={18} /></button>}
        </div>
      </div>
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        <div className="list-card">
          {filtered.length === 0 ? (
            <div style={{ padding: "40px 20px", textAlign: "center", color: "var(--text-3)" }}>
              <Icon name="users" size={36} style={{ marginBottom: 10 }} />
              <div style={{ fontSize: 14 }}>{t("noCustomers")}</div>
            </div>
          ) : filtered.map(c => (
            <CustomerRow key={c.id} c={c} lang={lang} t={t} onClick={() => { app.setCustomer(c); go("customerDetail"); }} />
          ))}
        </div>
      </div>
    </div>
  );
}

// ---------- Customer detail ----------
function CustomerDetail({ app }) {
  const { t, lang, go } = app;
  const c = app.customer || CRM_CUSTOMERS[0];
  const [isVip, setIsVip] = React.useState(c.isVip);
  const [notes, setNotes] = React.useState(c.notes);

  return (
    <div className="screen">
      <AppBar onBack={() => go("serviceApp")} title={t("customerCard")} />
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        {/* Customer header */}
        <div className="card" style={{ padding: 18, display: "flex", gap: 16, alignItems: "center", marginBottom: 20 }}>
          <div style={{ position: "relative", flexShrink: 0 }}>
            <div className="ph" data-label="" style={{ width: 60, height: 60, borderRadius: "50%" }} />
            {isVip && (
              <div style={{ position: "absolute", bottom: 0, right: -2, width: 22, height: 22, borderRadius: "50%", background: "var(--gold)", border: "2px solid var(--bg)", display: "grid", placeItems: "center" }}>
                <Icon name="crown" size={12} style={{ color: "#000" }} />
              </div>
            )}
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
              <span style={{ fontSize: 17, fontWeight: 700 }}>{c.name}</span>
              {isVip && <span className="tag gold" style={{ padding: "2px 7px" }}><Icon name="crown" size={10} /> VIP</span>}
            </div>
            <div className="mono" style={{ fontSize: 13.5, color: "var(--text-2)" }}>{c.phone}</div>
          </div>
          <button className="icon-btn ghost"><Icon name="phone" size={20} /></button>
        </div>

        {/* Stats row */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 20 }}>
          <div className="card" style={{ padding: 14, textAlign: "center" }}>
            <div style={{ fontSize: 24, fontWeight: 700, marginBottom: 3 }}>{c.visits}</div>
            <div style={{ fontSize: 12, color: "var(--text-3)", fontWeight: 600 }}>{t("visitCount")}</div>
          </div>
          <div className="card" style={{ padding: 14, textAlign: "center" }}>
            <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 3 }}>{c.lastVisit[lang]}</div>
            <div style={{ fontSize: 12, color: "var(--text-3)", fontWeight: 600 }}>{t("lastVisit")}</div>
          </div>
        </div>

        {/* VIP toggle */}
        <div className="list-card" style={{ marginBottom: 20 }}>
          <div className="row">
            <Icon name="crown" size={20} style={{ color: "var(--gold)" }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15 }}>{isVip ? t("removeVip") : t("vipMark")}</div>
            </div>
            <Toggle on={isVip} onChange={setIsVip} />
          </div>
        </div>

        {/* Notes */}
        <h3 className="sec-label" style={{ marginBottom: 9 }}>{t("notes")}</h3>
        <textarea className="field" value={notes} onChange={e => setNotes(e.target.value)}
          placeholder={t("notesPlaceholder")}
          style={{ height: 96, padding: "12px 16px", resize: "none", lineHeight: 1.55 }} />
      </div>

      <div style={{ padding: "12px 20px calc(env(safe-area-inset-bottom,0) + 16px)", borderTop: "1px solid var(--hairline)", background: "var(--bg)" }}>
        <Button icon="save" onClick={() => go("serviceApp")}>{t("save")}</Button>
      </div>
    </div>
  );
}

// ---------- Statistics ----------
function ServiceStats({ app }) {
  const { t } = app;
  const [period, setPeriod] = React.useState("today");
  const data = STATS[period];

  const chartData = data.chart;
  const maxVal = Math.max(...chartData);

  const topSvcs = [
    { key: "svc_swap",    count: 18, pct: 0.52 },
    { key: "svc_balance", count: 9,  pct: 0.26 },
    { key: "svc_patch",   count: 7,  pct: 0.20 },
  ];

  return (
    <div className="screen">
      <AppBar large title={t("statistics")} />
      <div style={{ padding: "0 18px 16px" }}>
        <div className="seg">
          {[["today", t("statToday")], ["week", t("statWeek")], ["month", t("statMonth")]].map(([k, label]) => (
            <button key={k} className="seg-item" data-active={period === k} onClick={() => setPeriod(k)}>{label}</button>
          ))}
        </div>
      </div>
      <div className="screen-body" style={{ padding: "0 18px 28px" }}>
        {/* Main stats */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 20 }}>
          <div className="card" style={{ padding: 16 }}>
            <Icon name="wallet" size={20} style={{ color: "var(--success)", marginBottom: 8 }} />
            <div className="mono" style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-0.02em" }}>{fmtSom(data.revenue)}</div>
            <div style={{ fontSize: 12, color: "var(--text-3)", marginTop: 3, fontWeight: 600 }}>{t("totalRevenue")}</div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            <div className="card" style={{ padding: 14, flex: 1, display: "flex", gap: 12, alignItems: "center" }}>
              <Icon name="calendar" size={18} style={{ color: "var(--text-2)" }} />
              <div>
                <div style={{ fontSize: 20, fontWeight: 700 }}>{data.bookings}</div>
                <div style={{ fontSize: 11, color: "var(--text-3)", fontWeight: 600 }}>{t("totalBookings")}</div>
              </div>
            </div>
            <div className="card" style={{ padding: 14, flex: 1, display: "flex", gap: 12, alignItems: "center" }}>
              <Icon name="starFill" size={18} style={{ color: "var(--gold)" }} />
              <div>
                <div style={{ fontSize: 20, fontWeight: 700 }}>{data.rating}</div>
                <div style={{ fontSize: 11, color: "var(--text-3)", fontWeight: 600 }}>{t("avgRating")}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Revenue chart */}
        <div className="card" style={{ padding: "16px 16px 8px", marginBottom: 20 }}>
          <h3 className="sec-label" style={{ marginBottom: 14 }}>{t("revenueChart")}</h3>
          <div style={{ display: "flex", alignItems: "flex-end", gap: 4, height: 72 }}>
            {chartData.map((v, i) => (
              <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 4 }}>
                <div style={{
                  width: "100%", borderRadius: "3px 3px 0 0",
                  height: Math.round((v / maxVal) * 64) + "px",
                  background: i === chartData.length - 1 ? "var(--inverse-bg)" : "var(--surface-3)",
                  transition: "height .3s ease",
                }} />
              </div>
            ))}
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 6, paddingTop: 8, borderTop: "1px solid var(--hairline)" }}>
            {period === "week" ? ["Du","Se","Cho","Pa","Ju","Sha","Ya"].map(d => (
              <span key={d} style={{ flex: 1, textAlign: "center", fontSize: 10, color: "var(--text-3)", fontWeight: 600 }}>{d}</span>
            )) : <span style={{ fontSize: 11, color: "var(--text-3)" }}>{period === "today" ? "Bugungi soatlar" : "Oylik kunlar"}</span>}
          </div>
        </div>

        {/* Top services */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("topServices")}</h3>
        <div className="list-card">
          {topSvcs.map((s, i) => {
            const svcObj = SERVICES.find(sv => sv.key === s.key) || SERVICES[0];
            return (
              <div key={i} className="row" style={{ padding: "13px 16px" }}>
                <div style={{ width: 32, height: 32, borderRadius: 9, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}>
                  <Icon name={svcObj.icon} size={17} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{t(s.key)}</div>
                  <div style={{ height: 5, borderRadius: 99, background: "var(--surface-3)", marginTop: 5, overflow: "hidden" }}>
                    <div style={{ height: "100%", width: `${s.pct * 100}%`, borderRadius: 99, background: "var(--text)", transition: "width .4s ease" }} />
                  </div>
                </div>
                <div style={{ textAlign: "right", flexShrink: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 700 }}>{s.count}</div>
                  <div style={{ fontSize: 11, color: "var(--text-3)" }}>{Math.round(s.pct * 100)}%</div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ---------- Service profile (service-side) ----------
function ServiceProfilePage({ app }) {
  const { t, go } = app;
  const shop = SERVICE_SHOPS[0];
  const [editing, setEditing] = React.useState(false);

  return (
    <div className="screen">
      <AppBar large title={t("serviceProfile")} right={
        <button className="icon-btn" onClick={() => setEditing(!editing)}><Icon name="edit" size={20} /></button>
      } />
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        {/* Shop photo */}
        <div style={{ position: "relative", height: 160, borderRadius: "var(--r-xl)", overflow: "hidden", marginBottom: 20 }}>
          <div className="ph" data-label="USTAXONA FOTOSI" style={{ position: "absolute", inset: 0, borderRadius: 0 }} />
          <button className="icon-btn" style={{ position: "absolute", bottom: 12, right: 12, background: "var(--bg-elev)", boxShadow: "var(--shadow-2)" }}>
            <Icon name="camera" size={20} />
          </button>
        </div>

        {/* Info fields */}
        <div className="list-card" style={{ marginBottom: 20 }}>
          {[
            { label: t("serviceName"),   value: shop.name,     icon: "notePad" },
            { label: t("serviceAddress"),value: shop.area,     icon: "pin" },
            { label: t("workingHours"),  value: shop.hours,    icon: "clock" },
          ].map((row, i) => (
            <div key={i} className="row" style={{ padding: "14px 16px" }}>
              <Icon name={row.icon} size={20} style={{ color: "var(--text-2)" }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 11.5, color: "var(--text-3)", fontWeight: 600, marginBottom: 2 }}>{row.label}</div>
                <div style={{ fontSize: 14.5 }}>{row.value}</div>
              </div>
              {editing && <Icon name="chevR" size={16} style={{ color: "var(--text-3)" }} />}
            </div>
          ))}
        </div>

        {/* Service types */}
        <h3 className="sec-label" style={{ marginBottom: 11 }}>{t("serviceTypes")}</h3>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 22 }}>
          {SERVICES.map(s => (
            <div key={s.id} className="chip" data-active="true" style={{ flexShrink: 0, fontSize: 12.5 }}>
              <Icon name={s.icon} size={15} /> {t(s.key)}
            </div>
          ))}
        </div>

        {/* Open/close toggle */}
        <div className="list-card" style={{ marginBottom: 22 }}>
          <div className="row">
            <Icon name="checkCircle" size={20} style={{ color: "var(--success)" }} />
            <div style={{ flex: 1, fontSize: 15 }}>{t("isOpen")}</div>
            <Toggle on={true} />
          </div>
        </div>

        {/* Link to owner app promo */}
        <button className="card" onClick={() => { app.setRole("owner"); app.go("ownerApp"); }}
          style={{ width: "100%", textAlign: "left", display: "flex", alignItems: "center", gap: 13, padding: 16, marginBottom: 22 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: "var(--inverse-bg)", color: "var(--inverse-text)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name="car" size={22} /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14.5, fontWeight: 600 }}>{t("forOwners")}</div>
            <div style={{ fontSize: 12, color: "var(--text-3)" }}>{t("ownerDesc")}</div>
          </div>
          <Icon name="chevR" size={18} style={{ color: "var(--text-3)" }} />
        </button>

        {/* Language & theme */}
        <div className="list-card" style={{ marginBottom: 22 }}>
          <div className="row">
            <Icon name="globe" size={20} style={{ color: "var(--text-2)" }} />
            <span style={{ flex: 1, fontSize: 15 }}>{t("language")}</span>
            <LangToggle app={app} />
          </div>
          <div className="row">
            <Icon name={app.theme === "dark" ? "moon" : "sun"} size={20} style={{ color: "var(--text-2)" }} />
            <span style={{ flex: 1, fontSize: 15 }}>{t("appearance")}</span>
            <div className="seg" style={{ width: 150 }}>
              <button className="seg-item" data-active={app.theme === "light"} onClick={() => app.setTheme("light")} style={{ fontSize: 12.5 }}>{t("themeLight")}</button>
              <button className="seg-item" data-active={app.theme === "dark"}  onClick={() => app.setTheme("dark")}  style={{ fontSize: 12.5 }}>{t("themeDark")}</button>
            </div>
          </div>
        </div>

        <button className="row" style={{ width: "100%", color: "var(--danger)", fontSize: 15, fontWeight: 600, justifyContent: "center", gap: 8 }} onClick={() => { app.setRole(null); app.go("welcome"); }}>
          <Icon name="logout" size={19} /> {t("logout")}
        </button>
      </div>
    </div>
  );
}

// ---------- Service notifications ----------
function ServiceNotifications({ app }) {
  const { t, lang, go } = app;
  return (
    <div className="screen">
      <AppBar onBack={() => go("serviceApp")} title={t("notifications")} />
      <div className="screen-body" style={{ padding: "4px 18px 24px" }}>
        <div className="card rise" style={{ padding: 18, marginBottom: 16, border: "1.5px solid var(--gold)", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", right: -24, top: -24, opacity: .12 }}><Icon name="snow" size={120} style={{ color: "var(--gold)" }} /></div>
          <span className="tag gold" style={{ marginBottom: 12 }}><Icon name="spark" size={12} /> SMART PUSH</span>
          <h3 style={{ fontSize: 17, fontWeight: 700, letterSpacing: "-0.02em", margin: "0 0 7px", position: "relative" }}>{t("seasonTitle")}</h3>
          <p style={{ fontSize: 13.5, lineHeight: 1.5, color: "var(--text-2)", margin: "0 0 15px", position: "relative" }}>{t("seasonBody")}</p>
        </div>

        <div className="list-card">
          {[
            { ic: "checkCircle", c: "var(--success)", title: { uz: "Yangi bron qabul qilindi",   ru: "Новая запись принята"       }, sub: { uz: "Bobur N. · Bugun 18:00",    ru: "Bobur N. · Сегодня 18:00"  }, ago: "5 daq" },
            { ic: "cashIn",      c: "var(--success)", title: { uz: "To'lov qabul qilindi",        ru: "Оплата получена"            }, sub: { uz: "Akmal K. · 80 000 so'm",   ru: "Akmal K. · 80 000 сум"     }, ago: "1 soat" },
            { ic: "star",        c: "var(--gold)",    title: { uz: "Yangi sharh",                  ru: "Новый отзыв"               }, sub: { uz: "Zafar T. · ★★★★★",          ru: "Zafar T. · ★★★★★"          }, ago: "3 soat" },
            { ic: "x",           c: "var(--danger)",  title: { uz: "Bron bekor qilindi",           ru: "Запись отменена"           }, sub: { uz: "Feruza M. · 15:30",         ru: "Feruza M. · 15:30"         }, ago: "Kecha" },
          ].map((n, i) => (
            <div key={i} className="row">
              <div style={{ width: 40, height: 40, borderRadius: 11, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name={n.ic} size={20} style={{ color: n.c }} /></div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14.5, fontWeight: 600 }}>{n.title[lang]}</div>
                <div style={{ fontSize: 12.5, color: "var(--text-2)" }}>{n.sub[lang]}</div>
              </div>
              <span style={{ fontSize: 11.5, color: "var(--text-3)" }}>{n.ago}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ServiceDashboard, ServiceBookingDetail, ServicePaymentReceipt, ServiceAllBookings, CRMList, CustomerDetail, ServiceStats, ServiceProfilePage, ServiceNotifications });
