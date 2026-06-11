// shina24-screens-account.jsx — Owner Profile, Notifications

// ---------- Owner Profile ----------
function OwnerProfile({ app }) {
  const { t, go } = app;
  return (
    <div className="screen">
      <AppBar large title={t("profile")} />
      <div className="screen-body" style={{ padding: "4px 18px 28px" }}>
        {/* Avatar */}
        <div className="card" style={{ display: "flex", alignItems: "center", gap: 14, padding: 16, marginBottom: 22 }}>
          <div className="ph" data-label="" style={{ width: 60, height: 60, borderRadius: "50%" }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 17, fontWeight: 600 }}>Akmal Karimov</div>
            <div className="mono" style={{ fontSize: 13, color: "var(--text-2)" }}>+998 (90) 123-45-67</div>
          </div>
          <button className="icon-btn ghost"><Icon name="chevR" size={20} /></button>
        </div>

        {/* Language */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 2px 11px" }}>
          <span style={{ display: "flex", alignItems: "center", gap: 11, fontSize: 15 }}><Icon name="globe" size={20} style={{ color: "var(--text-2)" }} /> {t("language")}</span>
          <LangToggle app={app} />
        </div>
        {/* Theme */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "11px 2px 16px" }}>
          <span style={{ display: "flex", alignItems: "center", gap: 11, fontSize: 15 }}><Icon name={app.theme === "dark" ? "moon" : "sun"} size={20} style={{ color: "var(--text-2)" }} /> {t("appearance")}</span>
          <div className="seg" style={{ width: 150 }}>
            <button className="seg-item" data-active={app.theme === "light"} onClick={() => app.setTheme("light")} style={{ fontSize: 12.5 }}>{t("themeLight")}</button>
            <button className="seg-item" data-active={app.theme === "dark"}  onClick={() => app.setTheme("dark")}  style={{ fontSize: 12.5 }}>{t("themeDark")}</button>
          </div>
        </div>

        <div className="list-card" style={{ marginBottom: 22 }}>
          {[
            ["wallet", t("paymentMethods"), null],
            ["chat",   t("myReviews"),      null],
            ["bell",   t("notifications"),  () => go("ownerNotifications")],
            ["shield", t("help"),           null],
          ].map(([ic, label, fn], i) => (
            <button key={i} className="row" style={{ width: "100%", textAlign: "left" }} onClick={fn}>
              <Icon name={ic} size={20} style={{ color: "var(--text-2)" }} />
              <span style={{ flex: 1, fontSize: 15 }}>{label}</span>
              <Icon name="chevR" size={18} style={{ color: "var(--text-3)" }} />
            </button>
          ))}
        </div>

        {/* Partner promo → switch to service view */}
        <button className="card" onClick={() => { app.setRole("service"); app.go("serviceApp"); }}
          style={{ width: "100%", textAlign: "left", display: "flex", alignItems: "center", gap: 13, padding: 16, marginBottom: 22 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: "var(--inverse-bg)", color: "var(--inverse-text)", display: "grid", placeItems: "center", flexShrink: 0 }}><Icon name="wrench" size={22} /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14.5, fontWeight: 600 }}>{t("roleService")}</div>
            <div style={{ fontSize: 12, color: "var(--text-3)" }}>{t("roleServiceDesc")}</div>
          </div>
          <Icon name="chevR" size={18} style={{ color: "var(--text-3)" }} />
        </button>

        <button className="row" style={{ width: "100%", color: "var(--danger)", fontSize: 15, fontWeight: 600, justifyContent: "center", gap: 8 }} onClick={() => { app.setRole(null); app.go("welcome"); }}>
          <Icon name="logout" size={19} /> {t("logout")}
        </button>
      </div>
    </div>
  );
}

// ---------- Owner Notifications ----------
function OwnerNotifications({ app }) {
  const { t, lang, go } = app;
  return (
    <div className="screen">
      <AppBar onBack={() => go("ownerApp")} title={t("notifications")} />
      <div className="screen-body" style={{ padding: "4px 18px 24px" }}>
        {/* Seasonal smart push */}
        <div className="card rise" style={{ padding: 18, marginBottom: 16, border: "1.5px solid var(--gold)", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", right: -24, top: -24, opacity: .12 }}><Icon name="snow" size={120} style={{ color: "var(--gold)" }} /></div>
          <span className="tag gold" style={{ marginBottom: 12 }}><Icon name="spark" size={12} /> SMART PUSH</span>
          <h3 style={{ fontSize: 17, fontWeight: 700, letterSpacing: "-0.02em", margin: "0 0 7px", position: "relative" }}>{t("seasonTitle")}</h3>
          <p style={{ fontSize: 13.5, lineHeight: 1.5, color: "var(--text-2)", margin: "0 0 15px", position: "relative" }}>{t("seasonBody")}</p>
          <Button size="sm" iconR="arrowR" onClick={() => go("ownerHome")} style={{ width: "auto", position: "relative" }}>{t("bookNow")}</Button>
        </div>

        <div className="list-card">
          {[
            { ic: "checkCircle", c: "var(--success)", title: { uz: "Bandlov tasdiqlandi",      ru: "Запись подтверждена"   }, sub: { uz: "Shinmaster Pro · Bugun 16:30",  ru: "Shinmaster Pro · Сегодня 16:30" }, ago: "1 soat" },
            { ic: "heart",       c: "var(--danger)",  title: { uz: "Ustaga rahmat aytildi",    ru: "Мастеру отправлены чаевые" }, sub: { uz: "10 000 so'm chaevoy",          ru: "Чаевые 10 000 сум"             }, ago: "2 kun"  },
            { ic: "star",        c: "var(--gold)",    title: { uz: "Sharhingizni qoldiring",   ru: "Оставьте отзыв"       }, sub: { uz: "Avto Shina 24/7",              ru: "Avto Shina 24/7"                }, ago: "3 kun"  },
            { ic: "snow",        c: "var(--text-2)",  title: { uz: "Mavsum almashdi",          ru: "Смена сезона"         }, sub: { uz: "Qish shinasiga o'ting",        ru: "Пора переходить на зимнюю"      }, ago: "5 kun"  },
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

Object.assign(window, { OwnerProfile, OwnerNotifications });
