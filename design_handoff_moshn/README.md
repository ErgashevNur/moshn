# Moshn — Developer Handoff

> **Balon / Shinomontaj xizmatlari agregatori — Mijoz mobil ilovasi**
>
> _"Mashina to'xtadimi? Bir tugma — yordam yo'lda."_

---

## About These Files

Bu papkadagi barcha `.html` va `.jsx` fayllar — **dizayn referenslari** (HTML prototiplari).
Ular ishlab chiqarish uchun tayyor kod emas. Vazifangiz: bu dizaynlarni mavjud yoki yangi
**Flutter / React Native** loyihasida qayta yaratish — mavjud framework patterns va
komponentlaridan foydalangan holda.

Fayllarni brauzerda oching: `Moshn Client App.html` — barcha ekranlar interaktiv,
bosib ko'rib chiqish mumkin.

**Fidelity:** HIGH-FIDELITY — ranglar, tipografiya, spacing, shadow, animatsiyalar
aynan prototip kabi bo'lishi kerak.

---

## Tech Stack (tavsiya)

| Platform | Tavsiya |
|---|---|
| iOS + Android | **Flutter** (Dart) — bitta codebase |
| Faqat bitta platforma | React Native + Expo |
| Backend | Node.js / Django REST — API endpoints |
| Auth | OTP via SMS (Eskiz.uz yoki SMS.uz) |
| To'lov | Payme, Click, Uzum Bank (installment) |
| Karta | Google Maps Flutter / Yandex MapKit |

---

## Design System Tokens

### Ranglar — Dark tema (asosiy)

```dart
// Backgrounds
bg          = #09090A
bgElevated  = #131316
surface     = #1A1A1E
surface2    = #242429
surface3    = #2E2E34

// Text
textPrimary   = #F4F4F2
textSecondary = rgba(244,244,242, 0.60)
textTertiary  = rgba(244,244,242, 0.36)

// Lines
hairline  = rgba(255,255,255, 0.085)
hairline2 = rgba(255,255,255, 0.14)

// Inverse (tugmalar, aktiv holatlar)
inverseBg   = #F4F4F2
inverseText = #0A0A0B

// Semantic
gold        = oklch(0.81 0.115 85)   // ≈ #D4A843 — VIP, yulduzlar
goldDim     = rgba(212,168,67, 0.16)
danger      = oklch(0.64 0.214 25)   // ≈ #E5382B — SOS, xato
dangerDim   = rgba(229,56,43, 0.16)
success     = oklch(0.72 0.16 150)   // ≈ #30D158 — ochiq, tasdiqlash
successDim  = rgba(48,209,88, 0.16)

scrim = rgba(0,0,0, 0.60)
```

### Ranglar — Light tema

```dart
bg          = #F4F3F0
bgElevated  = #FFFFFF
surface     = #FFFFFF
surface2    = #ECEBE7
surface3    = #E3E2DD
hairline    = rgba(20,20,16, 0.09)
hairline2   = rgba(20,20,16, 0.15)
textPrimary = #14140F
textSecondary = rgba(20,20,15, 0.58)
textTertiary  = rgba(20,20,15, 0.40)
inverseBg   = #14140F
inverseText = #F6F5F2
scrim       = rgba(20,18,14, 0.45)
```

### Tipografiya

```dart
fontFamily  = "Sora"         // Google Fonts — barcha UI matni
monoFamily  = "JetBrains Mono" // davlat raqami, narx, OTP kod

// Shkalа
displayLarge  = 29px, weight 700, letterSpacing -0.03em  // Onboarding sarlavha
displayMedium = 26px, weight 700, letterSpacing -0.03em  // Auth sarlavha
titleLarge    = 25px, weight 700, letterSpacing -0.03em  // Ekran sarlavhasi (large appbar)
titleMedium   = 19px, weight 600, letterSpacing -0.02em  // Appbar nomi
bodyLarge     = 16px, weight 400, letterSpacing -0.011em // Asosiy matn
bodyMedium    = 14.5px, weight 400
bodySmall     = 13px, weight 400, color textSecondary
labelLarge    = 16px, weight 600  // Tugma matni
labelMedium   = 13.5px, weight 500 // Chip matni
labelSmall    = 12px, weight 600, letterSpacing 0.07em, UPPERCASE // Sektsiya sarlavhasi
eyebrow       = 11px, weight 600, letterSpacing 0.12em, UPPERCASE, mono yoki sans
```

### Border Radius

```dart
r_xs   = 8
r_sm   = 12
r_md   = 16
r_lg   = 22
r_xl   = 28
r_2xl  = 34
r_full = 9999  // pill / doira
```

### Shadows

```dart
shadow1  = (0, 1, 2,  0, rgba(0,0,0,0.18))
shadow2  = (0, 8, 30, 0, rgba(0,0,0,0.28))
shadowPop = (0, 18, 50, 0, rgba(0,0,0,0.40))
// SOS tugmasi uchun qo'shimcha:
sosShadow = (0, 8, 22, -4, dangerColor)
```

---

## Ekranlar va Oqimlar

### 1. Onboarding (3 slayd)

**Maqsad:** Ilovaning 3 asosiy afzalligini ko'rsatish.

**Layout:**
- Yuqori: til toggle (O'z / Ру) + "O'tkazib yuborish" tugmasi — `space-between`
- Markaz: vizual animatsiya (har slayd o'ziga xos) + sarlavha (29px) + tavsif (16px, lineHeight 1.5)
- Pastki: progress dots (aktiv = 22px keng, nofaol = 6px, r_full) + "Keyingi" / "Boshlash" tugmasi

**3 slayd vizuali:**
1. `search` — aylana shaklidagi "g'ildirak" icon + pin badge (inverseBg fon)
2. `sos` — pulsirlovchi 3 ta aylana halqa (danger rang, `pulse-ring` animatsiya, 2s infinite, staggered) + qizil SOS markaziy to'p
3. `pay` — plastik karta ustiga bir oz burish bilan ikkinchi karta (rotateZ -8deg)

**Animatsiya:** Har slayd almashinishida vizual va matn `rise` animatsiya (opacity 0→1 + translateY 10→0, 0.4s ease)

---

### 2. Auth — Telefon + OTP

**Maqsad:** +998 formati bilan SMS orqali kirish.

**Phone step:**
- Yuqori: back tugma + til toggle
- Brend belgisi: 56×56, r=18, inverseBg fon, ichida Moshn tire logo (SVG: tashqi aylana + ichki aylana + 4 chiziq N/S/E/W)
- Sarlavha: "Telefon raqamingiz" 26px 700
- Tavsif: "Kirish uchun SMS-kod yuboramiz" — textSecondary
- Input row: `+998` prefiks bloki (92px keng, field uslubi) + format input `(XX) XXX-XX-XX` (mono font)
- "Kod yuborish" tugmasi — 9 raqam to'lgunga qadar disabled
- Pastda: shartlarga rozilik matni — 12px, textTertiary, markazda

**OTP step:**
- Sarlavha: "Tasdiqlash kodi"
- Tavsif: "Kod yuborildi: +998 XX..." — telefon qismi bold
- 5 ta input box: 54×64, r=16, mono 26px 700, markazlashgan; to'ldirilgan = border textTertiary, bo'sh = hairline
- Auto-focus: raqam kiritilganda keyingi boxga o'tish; backspace = oldingiga qaytish
- Oxirgi raqam kiritilganda 350ms dan so'ng `go("app")`
- Qayta yuborish: 59s taymeri, nol bo'lgach tugma faollashadi
- **Demo eslatma:** "Istalgan 5 raqam" — mono uslubda

---

### 3. Home (asosiy tab)

**Appbar:**
- Chap: joylashuv qatori — "Yaqin atrofda" (eyebrow) + "Toshkent, Yunusobod" (15px bold) + chevDown icon; bosib kengaytirish (keyinchalik)
- O'ng: qo'ng'iroq belgisi (qizil nuqta badge, 8px, danger rang, bg border) + avatar doira (42px)

**Qidiruv maydoni:**
- 52px balandlik, r_md, surface fon, hairline border
- Chap: search icon (textTertiary) + placeholder matn; bosilganda → map ekrani

**Xizmat gridi:**
- 3 ustun, gap 10, surface fon, r_lg
- Har katak: icon (26px, stroke 1.7) + qisqa nom (12px, textAlign center)
- Aktiv holat: inverseBg fon, inverseText rang
- Xizmatlar: G'ildirak almashtirish, Havo to'ldirish, Teshik yamash, Balanslash, Disk ta'mirlash, Mavsumiy saqlash

**Promo banner:**
- r_xl, inverseBg fon, inversText rang, 116px min balandlik
- Orqa fonda: 2 ta katta aylana chiziq (low opacity, absolute positioned)
- Chap yuqori: gold chip "MAVSUM"
- Matn: "−20% G'ildirak almashtirish" — 19px bold
- Animatsiya: `rise` kirish effekti

**Eng yaxshi servislar:**
- Header: "Shahardagi top servislar" (18px 700) + "Xaritada ko'rish →" (13.5px, right)
- Vertikal ro'yxat — workshop kartochkalari (quyida tavsif)

---

### 4. Workshop Card (qayta ishlatiladigan komponent)

```
[FOTO 78x78, r=15]  [Nom (16px 700)]              [VIP crown agar mavjud]
                    [★ 4.9 · 342 sharh]
                    [📍 Yunusobod, Amir Temur 108]
                    [Ochiq · 0.8 km · 4 daq]
```

- Karta: surface fon, r_lg, hairline border, width 100%
- Foto: `ph` (placeholder) class, 78×78, r=15
- Nom: textOverflow ellipsis, nowrap
- Yulduz: starFill icon, gold rang; raqam bold; sharh soni textTertiary
- Holat: Ochiq = success rang, Yopiq = danger rang; bold 600

---

### 5. Map (karta) Ekrani

**Layout:** To'liq ekran, map foni — SVG stilizatsiya yoki haqiqiy Google/Yandex Maps

**Floating appbar (z-index yuqori):**
- back tugma (bg_elevated, shadow2) + qidiruv bar (flex 1, bg_elevated, shadow2) + filter tugma

**Map pinlar (price bubble):**
```
┌──────────────┐
│ 👑 70 000    │   ← inverseBg fon (aktiv) / bgElevated (nofaol)
└──────────────┘
       ▼          ← kichik uchburchak "pointer"
```
- Aktiv pin: kattaroq (13px), inverseBg fon, bold

**Mening joylashuvim tugmasi:** icon_btn, o'ng tomonda, 48% pastda

**Pastki panel (bottom sheet):**
- Balandlik: kengaytirilmagan = 44%, kengaytirilgan = 82%
- bgElevated fon, r_2xl yuqori burchaklar, shadowPop
- Grip bar: 38×5px, r_full, hairline2 rang; bosib kengaytirish/kichraytirish
- Header: "4 ta yaqin atrofda" + "★ Top"
- Workshop kartochkalari ro'yxati (vertikal, scroll)

---

### 6. Workshop Detail

**Hero (260px balandlik):**
- Rasm placeholder (to'liq kenglik)
- Gradient: scrim yuqoridan + scrim pastdan (bg rangga o'tish)
- Yuqori: back + yoqtirish tugmalari (bgElevated, shadow2)
- Pastki o'ngda: 3 slayd dots (aktiv = 16px keng, qolganlar 6px)

**Kontent (padding 20px):**
- Nom: 24px 700 + VIP/24h teglar (o'ng tomonda)
- ★ reyting + holat + masofa qatori
- 📍 manzil + km
- Tugmalar qatori: "Yo'nalish" + "Qo'ng'iroq" (secondary, sm, flex 1 each)
- **Haqida:** 14.5px, lineHeight 1.55, textSecondary
- **Xizmatlar va narxlar:** list_card — har qator: icon (38×38, r=11, surface2) + nom + davomiyligi + narx (mono)
- **Sharhlar:** 3 ta karta — avatar (34px doira) + ism + vaqt + yulduzlar + matn

**Sticky pastki tugma:**
- bg fon, hairline yuqori chegara
- Chap: "dan" eyebrow + narx (mono 19px 700)
- O'ng: "Vaqtga yozilish →" tugmasi (flex 1)

---

### 7. Booking (Bron qilish)

**Sektsiyalar (vertikal scroll):**

1. **Servis xona mini-karta** — foto (46×46) + nom + manzil; VIP crown
2. **Xizmat tanlash** — gorizontal scroll chips; aktiv = inverseBg
3. **Avtomobil** — har avto uchun karta:
   - Rang bloki (42×42, r=11, avto rangi) + icon
   - Nom + g'ildirak o'lchami + davlat raqami badge
   - Radio doira (22px) — aktiv = to'ldirilgan inverseBg nuqta
4. **Sana** — gorizontal scroll, 58px keng kartochkalar:
   - Kunduzgi nomi (11px, 65% opacity) + kun raqami (19px 700)
   - Aktiv: inverseBg fon
5. **Bo'sh vaqtlar** — 4 ustun grid, mono 14px 700:
   - Band = line-through, opacity 0.45, disabled
   - Aktiv = inverseBg
   - Slot band bo'lganda: gold sariq banner "Slot 5 daqiqaga band qilindi" (rise animatsiya)

**Sticky CTA:** narx + "To'lovga o'tish →" (disabled agar vaqt tanlanmagan)

---

### 8. Payment (To'lov)

**Buyurtma summary kartochkasi:**
- Servis fotosi + nom + xizmat·raqam qatori
- Separator + 📅 sana + ⏰ vaqt (mono, bold)

**To'lov vaqti (3 variant, radio karta):**
| ID | Icon | Sarlavha | Tavsif |
|---|---|---|---|
| now | card | Hozir to'lash | To'lov usuli |
| later | clock | Keyin to'lash | 14 kun ichida |
| split | wallet | Bo'lib to'lash | 3–6 oy, bank/MKO |

**Karta tanlash (faqat "now" aktiv bo'lsa):**
- Gorizontal scroll: har karta 150×100, r_md
  - Yuqori: bank nomi + card icon
  - Pastki: `•••• 4417` (mono, letterSpacing 0.08em)
  - Aktiv: inverseBg fon, inverseText
- + QR tugmasi (88px, dashed border)

**Chaevoy:**
- Header: ❤️ icon (danger) + "Ustaga chaevoy"
- 4 tugma grid: 0 (Yo'q), 10k, 20k, 50k
- Aktiv = inverseBg

**Sticky CTA:**
- "Bo'lib to'lash" tanlangan bo'lsa: "Mablag' xizmat tasdiqlangach yechiladi" eslatma (12px, textTertiary)
- Chap: jami narx (mono 19px) + "Jami" eyebrow
- O'ng: "Bandlovni tasdiqlash" tugmasi (agar now → shield icon)

---

### 9. Confirmation (Tasdiqlash)

**Markazlashgan layout:**
- Animatsiya: yashil doira (successDim) + yashil to'p (pop-in, scale 0.9→1, 0.45s cubic) + check icon (stroke 2.6)
- "Yozildingiz!" — 27px 700
- Tavsif: 15.5px, textSecondary
- Buyurtma karta: servis + manzil + sana/vaqt (separator bilan)
- Tugmalar: "Kalendarga qo'shish" (outline) + "Bandlovni ko'rish" (primary)

---

### 10. SOS Ekrani

**Idle holat:**
- 2 ta pulsirlovchi aylana halqa (danger rang, `pulse-ring` 2.4s infinite, staggered)
- Markaziy to'p: 150×150, r_full, danger fon, "SOS" matni (34px 800, letterSpacing 0.08em)
- Sabab tanlash: 2 ustun grid (4 xil sabab)
- Pastda: "Yordam chaqirish uchun bosib turing" — 13px, textTertiary

**Calling holat (bosilgandan keyin):**
- To'liq danger rang fon
- 3 ta pulsirlovchi aylana (staggered, 2.2s infinite)
- "Eng yaqin usta qidirilmoqda…"
- "Bekor qilish" tugmasi
- **2600ms dan keyin → Connected holat**

**Connected holat:**
- To'liq qora fon (#0C0C0D) + SVG karta
- Gradient overlay (scrim → transparent → transparent → dark)
- 2 ta pin: yashil usta marker (46px doira, wrench icon) + ko'k "siz" nuqta (18px, border 3px white)
- Pastki panel (blur backdrop):
  - "Joylashuvingiz uzatilmoqda" — yashil nuqta + matn
  - Usta info: avatar + "Bobur — usta topildi" + ★4.9 + "3 daq"
  - Tugmalar: "Video aloqa" (semi-transparent) + "Tugatish" (danger)

---

### 11. Garaj

**Har avto kartochkasi:**
- 130px balandlik rasm placeholder
- "Asosiy" tegi (chap yuqori, bgElevated) — asosiy avto uchun
- Davlat raqami badge (o'ng pastda, KATTA o'lcham — Plate lg)
- Pastki: nom + g'ildirak o'lchami + settings icon

**"Raqam orqali bog'lanish" toggle qatori:**
- phone icon + sarlavha + tavsif + toggle switch (yashil/off animatsiya)

**"Avtomobil qo'shish" sheet:**
- Foto drag-drop area (120px, dashed border)
- Davlat raqami field (mono, uppercase, `01 A 000 AA` placeholder)
- Marka va model field
- G'ildirak o'lchami field (mono)

**Plate badge dizayni:**
```
╔═══════════════╗
║ 01 A 777 AA   ║   bg: #F4F4F2, text: #111
╚═══════════════╝
font: JetBrains Mono, weight 700
border: 1px rgba(0,0,0,0.2)
box-shadow: inset 0 0 0 2px #fff, 0 1px 2px rgba(0,0,0,.2)
padding: sm=4px 9px, lg=7px 14px
```

---

### 12. Bookings (Yozuvlar)

**Segmented control:** "Kelgusi" / "O'tgan"

**Har buyurtma kartochkasi:**
- Servis fotosi + nom + xizmat·raqam + status tegi (yoki yulduzlar)
- Separator + 📅 sana + narx (mono, right)
- Kelgusi → "Yo'nalish" + "Qo'ng'iroq" tugmalari
- O'tgan, baholanmagan → "Sharh qoldirish" + "Qayta yozilish"
- O'tgan, baholangan → yulduzlar ko'rinadi

---

### 13. Profile

**Avatar qatori:** 60px doira + ism (17px 600) + telefon (mono 13px, textSecondary) + chevR

**Sozlamalar:**
- Til toggle (inline, o'ng tomonda)
- Tema: Light/Dark segmented control (inline, o'ng tomonda)

**List card (menyu):**
- To'lov usullari, Sharhlarim, Bildirishnomalar, Yordam
- Har qator: icon + matn + chevR

**Partnyorlar promo banner:**
- inverseBg doira (44px, wrench icon) + matn + chevR
- Bosilganda → Servis planshet demo

**Chiqish:** danger rang, logout icon, markazda

---

### 14. Notifications

**Mavsumiy Smart Push (featured karta):**
- border: 1.5px gold rang
- Orqa fon: katta snow icon (opacity 0.12, absolute right-top)
- "SMART PUSH" gold chip
- Sarlavha + matn + "Hoziroq yozilish →" tugmasi (sm)

**Oddiy bildirishnomalar list:**
- icon (40×40, r=11, surface2) + sarlavha + tavsif + vaqt

---

## Komponentlar

### Button

```
Primary:   bg=inverseBg, text=inverseText
Secondary: bg=surface2, text=textPrimary
Outline:   bg=transparent, border=1.5px hairline2
Danger:    bg=danger, text=#FFF
Size full: height=54px, borderRadius=r_full, font 16px 600
Size sm:   height=42px, font 14px, width=auto
Active: scale(0.975), transition 120ms
```

### Chip

```
Default: bg=surface, border=hairline, text=textSecondary, padding 9px 15px, r_full
Active:  bg=inverseBg, text=inverseText, no border
Font: 13.5px 500
Active: scale(0.95)
```

### Bottom Nav

```
5 element: Home | Bookings | [SOS] | Garage | Profile
SOS tugmasi: 60px doira, danger fon, 5px ring (bg rang), margin-top=-22px
  font: 9px 700, letterSpacing 0.08em
  box-shadow: 0 8px 22px -4px dangerColor
Nav item: 10.5px 500, textTertiary (nofaol), textPrimary (aktiv)
Icon stroke: 2 (aktiv), 1.7 (nofaol)
Backdrop: blur(20px) saturate(180%), borderTop hairline
```

### App Bar (Standart)

```
Height: ~60px, padding 8px 18px 12px
Back: icon_btn (42×42, r_full, surface fon, hairline border)
Title: 19px 600, letterSpacing -0.02em
Large variant: title 27px 700, letterSpacing -0.03em
```

### Bottom Sheet

```
Backdrop: scrim + blur(2px)
Panel: bgElevated, r_2xl yuqori, shadowPop
Grip: 38×5px, r_full, hairline2; margin auto
Animatsiya: translateY(100%) → 0, 340ms cubic-bezier(0.16,1,0.3,1)
```

### Toggle Switch

```
Width: 48px, Height: 29px, r_full
On: success fon; Off: surface3 fon
Knob: 23×23, bg #fff, translateX 19px (on) / 0 (off)
Transition: 200ms ease
```

### Segmented Control

```
Container: surface2 fon, r_full, padding 4px, gap 2px
Item: r_full, 13.5px 600, textSecondary
Active: bgElevated fon, textPrimary, shadow1
Transition: all 200ms ease
```

---

## Animatsiyalar

```css
/* Ekran kirishi */
screen-in:      opacity 0→1 + translateX 22→0,  320ms cubic-bezier(0.16,1,0.3,1)
screen-in-back: opacity 0→1 + translateX -22→0, 320ms cubic-bezier(0.16,1,0.3,1)

/* Element ko'tarilishi */
rise: opacity 0→1 + translateY 10→0, 400ms cubic-bezier(0.16,1,0.3,1)

/* Stagger (ro'yxat elementlari) */
item[n]: rise + delay n*40ms (max 310ms)

/* SOS pulse halqasi */
pulse-ring: scale(0.75)→scale(2.2), opacity 0.7→0, 2.2s ease-out infinite

/* Confirmation pop */
pop-in: scale(0.9)→scale(1) + opacity 0→1, 450ms cubic-bezier(0.16,1.4,0.3,1)

/* Sheet kirishi */
sheet-up: translateY(100%)→0, 340ms cubic-bezier(0.16,1,0.3,1)
```

> **Muhim:** Animatsiyalarni faqat `requestAnimationFrame` ishlaganda faollashtiring.
> Frozen/offscreen holatlarda kontent ko'rinishi kerak (opacity:0 da yashirilib qolmasin).

---

## Internationalization (i18n)

- **Ikki til:** O'zbek (lotin) va Rus
- Barcha matnlar `moshn-i18n.jsx` faylidagi `STR` obyektida
- Interfeys → `makeT(lang)` → `t("key")` pattern
- Til toggle: Profile ekranida + Auth ekranida
- Til saqlanadi: `localStorage` / `SharedPreferences`
- O'zbek til kodi: `"uz"`, Rus: `"ru"`

---

## State Management

```dart
// Global app state
String lang          // "uz" | "ru", persisted
String theme         // "dark" | "light", persisted
String route         // joriy ekran nomi
String tab           // joriy bottom nav tab
String? selectedSvc  // tanlangan xizmat ID
Workshop? selectedShop
Order? currentOrder

// Booking flow
String? selectedServiceId
String? selectedCarId
int? selectedDate
String? selectedTime

// Payment
String paymentTiming   // "now" | "later" | "split"
String? selectedCard
int tipAmount          // so'mda

// Auth
String phoneInput
List<String> otpDigits // 5 ta
int resendTimer        // 59→0, keyin qayta yoqish

// SOS
String sosState // "idle" | "calling" | "connected"
String? sosReason
```

---

## API Endpoints (Taxminiy)

```
POST /auth/send-otp         { phone: "+998901234567" }
POST /auth/verify-otp       { phone, code }

GET  /workshops              ?lat=&lon=&service=&radius=
GET  /workshops/:id
GET  /workshops/:id/slots    ?date=&service=

POST /bookings               { workshopId, serviceId, carId, date, time }
GET  /bookings               ?status=upcoming|past
GET  /bookings/:id

POST /payments               { bookingId, method, timing, tipAmount }

GET  /cars                   (auth required)
POST /cars                   { plate, make, model, wheelSize }

GET  /notifications
```

---

## Muhim UX qoidalar

1. **SOS har doim bir marta bosish** — bottom nav markazida, alohida tab emas
2. **Davlat raqami** — har doim mono font, UPPERCASE, `01 A 000 AA` format
3. **Narxlar** — JetBrains Mono, minglar ajratgich bo'sh joy: `80 000 so'm`
4. **OTP** — oxirgi raqam kiritilganda avtomatik yuborish (350ms delay)
5. **Slot tanlash** — vaqt tanlanmagan holda "To'lovga o'tish" disabled
6. **Tema** — system preference'dan boshlash, keyin foydalanuvchi o'zgartirishi mumkin
7. **Karta saqlash** — localStorage / SharedPreferences orqali barcha tanlovlar saqlanadi
8. **Mavsumiy eslatma** — server-side push: qish→yoz (mart/aprel), yoz→qish (oktyabr/noyabr)

---

## Fayllar

| Fayl | Tavsif |
|---|---|
| `Moshn Client App.html` | Asosiy prototip — brauzerda oching |
| `moshn.css` | Dizayn system tokenlari va CSS utility klasslari |
| `moshn-i18n.jsx` | Barcha UI matnlar (O'z/Ru) |
| `moshn-data.jsx` | Mock ma'lumotlar (servislar, ustaxonalar, bronlar) |
| `moshn-icons.jsx` | 40+ SVG icon (24px line) |
| `moshn-ui.jsx` | Umumiy komponentlar (Button, Card, Map, WorkshopCard...) |
| `moshn-screens-auth.jsx` | Onboarding + OTP ekranlari |
| `moshn-screens-discover.jsx` | Home, Map, WorkshopDetail |
| `moshn-screens-booking.jsx` | Booking, Payment, Confirmation |
| `moshn-screens-account.jsx` | SOS, Garage, Bookings, Profile, Notifications |

---

## Keyingi bosqich (Servis-Partnyor Planshet)

TZ'da belgilangan, hali dizayn qilinmagan:
- Planshet UI: yozuvlar + bildirishnomalar (real-time)
- Terminal to'lov: karta tegish / QR kod
- Bo'lib to'lash qabul qilish
- Mijozlar bazasi + VIP belgi
- Mijozni baholash (1–5 yulduz)
- Analitika dashboard

---

*Yaratilgan: Moshn Design System v1.0 — Claude Sonnet bilan*
*Sana: 2026-yil iyun*
