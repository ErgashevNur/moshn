// shina24-screens-auth.jsx — Welcome, RoleSelect, Onboarding, Auth

// Brand mark: stylized tire ring (concentric circles + spokes)
function BrandMark({ size = 40, color = "currentColor" }) {
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" fill="none">
      <circle cx="24" cy="24" r="21" stroke={color} strokeWidth="2.4" />
      <circle cx="24" cy="24" r="8"  stroke={color} strokeWidth="2.4" />
      <g stroke={color} strokeWidth="2.4" strokeLinecap="round">
        <path d="M24 3v8M24 37v8M3 24h8M37 24h8" />
        <path d="M9 9l5.5 5.5M33.5 33.5L39 39M39 9l-5.5 5.5M14.5 33.5L9 39" opacity="0.5"/>
      </g>
    </svg>
  );
}

function LangToggle({ app, compact }) {
  return (
    <div className="seg" style={{ width: compact ? 96 : 120, padding: 3 }}>
      {["uz","ru"].map(l => (
        <button key={l} className="seg-item" data-active={app.lang === l}
          style={{ padding: "6px 4px", fontSize: 12.5, textTransform: "uppercase" }}
          onClick={() => app.setLang(l)}>{l === "uz" ? "O'z" : "Ру"}</button>
      ))}
    </div>
  );
}

// ---------- Welcome screen ----------
function Welcome({ app }) {
  const { t } = app;
  return (
    <div className="screen" style={{ alignItems: "center" }}>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 32px", textAlign: "center" }}>
        {/* Animated logo */}
        <div style={{ position: "relative", display: "grid", placeItems: "center", marginBottom: 32 }}>
          <div style={{ position: "absolute", width: 120, height: 120, borderRadius: "50%", border: "1.5px solid var(--hairline-2)", animation: "pulse-ring 3s ease-out infinite" }} />
          <div style={{ position: "absolute", width: 90, height: 90, borderRadius: "50%", border: "1.5px solid var(--hairline-2)", animation: "pulse-ring 3s ease-out infinite 1s" }} />
          <div style={{ width: 72, height: 72, borderRadius: 22, background: "var(--inverse-bg)", color: "var(--inverse-text)", display: "grid", placeItems: "center", boxShadow: "var(--shadow-2)" }}>
            <BrandMark size={44} />
          </div>
        </div>
        <h1 style={{ fontSize: 36, fontWeight: 800, letterSpacing: "-0.04em", margin: "0 0 12px", lineHeight: 1 }}>Shina24</h1>
        <p style={{ fontSize: 15.5, lineHeight: 1.55, color: "var(--text-2)", margin: 0, maxWidth: 280, textWrap: "pretty" }}>{t("tagline")}</p>
      </div>
      <div style={{ width: "100%", padding: "0 24px calc(env(safe-area-inset-bottom,0) + 28px)" }}>
        <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 16 }}>
          <LangToggle app={app} />
        </div>
        <Button iconR="arrowR" onClick={() => app.go("roleSelect")}>{t("getStarted")}</Button>
      </div>
    </div>
  );
}

// ---------- Role select ----------
function RoleSelect({ app }) {
  const { t } = app;
  return (
    <div className="screen">
      <AppBar onBack={() => app.go("welcome")} title="" right={<LangToggle app={app} compact />} />
      <div className="screen-body" style={{ padding: "10px 22px 26px", display: "flex", flexDirection: "column" }}>
        <h1 style={{ fontSize: 26, fontWeight: 700, letterSpacing: "-0.03em", margin: "14px 0 28px", lineHeight: 1.15 }}>{t("chooseRole")}</h1>
        <div style={{ display: "flex", flexDirection: "column", gap: 14, flex: 1 }}>
          {/* Owner role */}
          <button onClick={() => { app.setRole("owner"); app.go("onboarding"); }}
            className="card" style={{ padding: 22, textAlign: "left", display: "flex", gap: 18, alignItems: "flex-start" }}>
            <div style={{ width: 52, height: 52, borderRadius: 15, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}>
              <Icon name="car" size={26} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 17, fontWeight: 700, marginBottom: 5 }}>{t("roleOwner")}</div>
              <div style={{ fontSize: 13.5, color: "var(--text-3)", lineHeight: 1.4 }}>{t("roleOwnerDesc")}</div>
            </div>
            <Icon name="chevR" size={20} style={{ color: "var(--text-3)", marginTop: 4 }} />
          </button>

          {/* Service role */}
          <button onClick={() => { app.setRole("service"); app.go("auth"); }}
            className="card" style={{ padding: 22, textAlign: "left", display: "flex", gap: 18, alignItems: "flex-start" }}>
            <div style={{ width: 52, height: 52, borderRadius: 15, background: "var(--surface-2)", display: "grid", placeItems: "center", flexShrink: 0 }}>
              <Icon name="wrench" size={26} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 17, fontWeight: 700, marginBottom: 5 }}>{t("roleService")}</div>
              <div style={{ fontSize: 13.5, color: "var(--text-3)", lineHeight: 1.4 }}>{t("roleServiceDesc")}</div>
            </div>
            <Icon name="chevR" size={20} style={{ color: "var(--text-3)", marginTop: 4 }} />
          </button>
        </div>
      </div>
    </div>
  );
}

// ---------- Onboarding (owner only) ----------
function Onboarding({ app }) {
  const { t } = app;
  const [i, setI] = React.useState(0);
  const slides = [
    { v: "search", title: t("ob1Title"), sub: t("ob1Sub") },
    { v: "book",   title: t("ob2Title"), sub: t("ob2Sub") },
    { v: "pay",    title: t("ob3Title"), sub: t("ob3Sub") },
  ];
  const last = i === slides.length - 1;

  const Visual = ({ v }) => {
    if (v === "book") return (
      <div style={{ position: "relative", width: 200, height: 180, display: "grid", placeItems: "center" }}>
        <div style={{ width: 160, padding: "18px 16px", borderRadius: 20, background: "var(--surface)", border: "1px solid var(--hairline)", display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ height: 8, borderRadius: 99, background: "var(--surface-3)", width: "60%" }} />
          <div style={{ display: "flex", gap: 6 }}>
            {[0,1,2,3,4].map(k => (
              <div key={k} style={{ flex: 1, height: 36, borderRadius: 10, background: k === 2 ? "var(--inverse-bg)" : "var(--surface-2)" }} />
            ))}
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 5 }}>
            {[0,1,2,3,4,5,6,7].map(k => (
              <div key={k} style={{ height: 28, borderRadius: 8, background: k === 5 ? "var(--inverse-bg)" : "var(--surface-2)" }} />
            ))}
          </div>
        </div>
        <div style={{ position: "absolute", top: 12, right: 8, width: 38, height: 38, borderRadius: "50%", background: "var(--inverse-bg)", display: "grid", placeItems: "center", color: "var(--inverse-text)", boxShadow: "var(--shadow-2)" }}>
          <Icon name="check" size={20} stroke={2.4} />
        </div>
      </div>
    );
    if (v === "pay") return (
      <div style={{ position: "relative", width: 200, height: 180, display: "grid", placeItems: "center" }}>
        <div style={{ position: "absolute", transform: "rotate(-8deg) translate(-26px,14px)", width: 150, height: 94, borderRadius: 18, background: "var(--surface-3)", border: "1px solid var(--hairline-2)" }} />
        <div style={{ position: "relative", width: 160, height: 100, borderRadius: 18, background: "var(--inverse-bg)", color: "var(--inverse-text)", padding: 16, display: "flex", flexDirection: "column", justifyContent: "space-between", boxShadow: "var(--shadow-2)" }}>
          <BrandMark size={26} />
          <div className="mono" style={{ fontSize: 14, letterSpacing: "0.12em" }}>•••• 4417</div>
        </div>
      </div>
    );
    // search / default
    return (
      <div style={{ position: "relative", width: 200, height: 180, display: "grid", placeItems: "center" }}>
        <div style={{ width: 150, height: 150, borderRadius: "50%", border: "12px solid var(--surface-3)", display: "grid", placeItems: "center" }}>
          <div style={{ width: 56, height: 56, borderRadius: "50%", border: "10px solid var(--text-3)" }} />
        </div>
        <div style={{ position: "absolute", top: 18, right: 22, width: 48, height: 48, borderRadius: "50%", background: "var(--inverse-bg)", color: "var(--inverse-text)", display: "grid", placeItems: "center", boxShadow: "var(--shadow-2)" }}>
          <Icon name="pin" size={24} />
        </div>
      </div>
    );
  };

  return (
    <div className="screen">
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 18px 0" }}>
        <LangToggle app={app} compact />
        <button className="btn-sm" style={{ color: "var(--text-2)", fontWeight: 600, fontSize: 14 }} onClick={() => app.go("auth")}>{t("skip")}</button>
      </div>
      <div className="screen-body" style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 30px", textAlign: "center" }}>
        <div key={i} className="rise" style={{ marginBottom: 40 }}><Visual v={slides[i].v} /></div>
        <h1 key={"t"+i} className="rise" style={{ fontSize: 29, fontWeight: 700, lineHeight: 1.12, letterSpacing: "-0.03em", margin: "0 0 16px", textWrap: "balance" }}>{slides[i].title}</h1>
        <p key={"s"+i} className="rise" style={{ fontSize: 16, lineHeight: 1.5, color: "var(--text-2)", margin: 0, maxWidth: 320, textWrap: "pretty" }}>{slides[i].sub}</p>
      </div>
      <div style={{ padding: "0 24px calc(env(safe-area-inset-bottom,0) + 26px)" }}>
        <div style={{ display: "flex", gap: 6, justifyContent: "center", marginBottom: 22 }}>
          {slides.map((_, k) => (
            <div key={k} onClick={() => setI(k)} style={{ height: 6, borderRadius: 99, width: k === i ? 22 : 6, background: k === i ? "var(--text)" : "var(--text-3)", transition: "all .3s ease", cursor: "pointer" }} />
          ))}
        </div>
        <Button iconR={last ? "arrowR" : null} onClick={() => last ? app.go("auth") : setI(i + 1)}>
          {last ? t("getStarted") : t("next")}
        </Button>
      </div>
    </div>
  );
}

// ---------- Auth: phone + OTP ----------
function Auth({ app }) {
  const { t } = app;
  const [step, setStep] = React.useState("phone");
  const [phone, setPhone] = React.useState("");
  const [code, setCode] = React.useState(["","","","",""]);
  const [timer, setTimer] = React.useState(0);
  const inputs = React.useRef([]);

  const fmtPhone = (raw) => {
    const d = raw.replace(/\D/g, "").slice(0, 9);
    let out = "";
    if (d.length > 0) out += "(" + d.slice(0,2);
    if (d.length >= 2) out += ") " + d.slice(2,5);
    if (d.length >= 5) out += "-" + d.slice(5,7);
    if (d.length >= 7) out += "-" + d.slice(7,9);
    return out;
  };
  const digits = phone.replace(/\D/g, "").length;

  React.useEffect(() => {
    if (step === "code") { setTimer(59); inputs.current[0]?.focus(); }
  }, [step]);
  React.useEffect(() => {
    if (timer <= 0) return;
    const id = setTimeout(() => setTimer(timer - 1), 1000);
    return () => clearTimeout(id);
  }, [timer]);

  const setDigit = (idx, val) => {
    const v = val.replace(/\D/g, "").slice(-1);
    const nc = [...code]; nc[idx] = v; setCode(nc);
    if (v && idx < 4) inputs.current[idx + 1]?.focus();
    if (nc.every(x => x)) setTimeout(() => app.go("app"), 350);
  };
  const onKey = (idx, e) => {
    if (e.key === "Backspace" && !code[idx] && idx > 0) inputs.current[idx - 1]?.focus();
  };

  return (
    <div className="screen">
      <AppBar onBack={() => step === "code" ? setStep("phone") : app.go("roleSelect")}
        title="" right={<LangToggle app={app} compact />} />
      <div className="screen-body" style={{ padding: "10px 26px 26px", display: "flex", flexDirection: "column" }}>
        <div style={{ width: 56, height: 56, borderRadius: 18, background: "var(--inverse-bg)", color: "var(--inverse-text)", display: "grid", placeItems: "center", marginBottom: 26 }}>
          <BrandMark size={32} />
        </div>
        {step === "phone" ? (
          <div className="anim-in" style={{ flex: 1, display: "flex", flexDirection: "column" }}>
            <h1 style={{ fontSize: 26, fontWeight: 700, letterSpacing: "-0.03em", margin: "0 0 8px" }}>{t("enterPhone")}</h1>
            <p style={{ color: "var(--text-2)", fontSize: 15, margin: "0 0 28px" }}>{t("phoneHint")}</p>
            <div style={{ display: "flex", gap: 10 }}>
              <div className="field" style={{ width: 92, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontWeight: 600 }}>+998</div>
              <input className="field mono" inputMode="numeric" autoFocus placeholder="(__) ___-__-__"
                value={fmtPhone(phone)} onChange={e => setPhone(e.target.value)} style={{ flex: 1, letterSpacing: "0.02em" }} />
            </div>
            <div style={{ flex: 1 }} />
            <p style={{ fontSize: 12, color: "var(--text-3)", textAlign: "center", margin: "0 0 14px", lineHeight: 1.4 }}>{t("byContinuing")}</p>
            <Button disabled={digits < 9} onClick={() => setStep("code")}>{t("sendCode")}</Button>
          </div>
        ) : (
          <div className="anim-in" style={{ flex: 1, display: "flex", flexDirection: "column" }}>
            <h1 style={{ fontSize: 26, fontWeight: 700, letterSpacing: "-0.03em", margin: "0 0 8px" }}>{t("enterCode")}</h1>
            <p style={{ color: "var(--text-2)", fontSize: 15, margin: "0 0 28px" }}>{t("codeSentTo")} <b style={{ color: "var(--text)" }}>+998 {fmtPhone(phone)}</b></p>
            <div style={{ display: "flex", gap: 10, justifyContent: "space-between" }}>
              {code.map((c, idx) => (
                <input key={idx} ref={el => inputs.current[idx] = el} className="mono"
                  inputMode="numeric" maxLength={1} value={c}
                  onChange={e => setDigit(idx, e.target.value)} onKeyDown={e => onKey(idx, e)}
                  style={{ width: 54, height: 64, textAlign: "center", fontSize: 26, fontWeight: 700, borderRadius: 16, background: "var(--surface)", color: "var(--text)", border: `1.5px solid ${c ? "var(--text-3)" : "var(--hairline)"}`, outline: "none" }} />
              ))}
            </div>
            <div style={{ marginTop: 22, textAlign: "center" }}>
              {timer > 0
                ? <span style={{ color: "var(--text-3)", fontSize: 14 }}>{t("resendIn")} 0:{String(timer).padStart(2,"0")}</span>
                : <button style={{ color: "var(--text)", fontWeight: 600, fontSize: 14 }} onClick={() => setTimer(59)}>{t("resend")}</button>}
            </div>
            <div style={{ flex: 1 }} />
            <p style={{ fontSize: 13, color: "var(--text-3)", textAlign: "center", margin: 0 }}>
              <span className="mono">Demo: </span>istalgan 5 raqamni kiriting
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { Welcome, RoleSelect, Onboarding, Auth, BrandMark, LangToggle });
