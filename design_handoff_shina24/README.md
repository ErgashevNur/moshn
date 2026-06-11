# Shina24 — Developer Handoff

> **Shinomontaj servislar uchun bron va boshqaruv platformasi**
>
> _"Shinomontaj — tez, qulay, ishonchli."_

---

## Haqida

Bu papkadagi barcha `.html` va `.jsx` fayllar — **dizayn referenslari** (HTML prototiplari).
Ular ishlab chiqarish uchun tayyor kod emas. Vazifangiz: bu dizaynlarni mavjud
**Flutter** loyihasida qayta yaratish — mavjud framework patterns va komponentlaridan foydalangan holda.

Fayllarni brauzerda oching: **`Shina24 App.html`** — ikkita telefon yonma-yon:
- **Chap** — Mijoz (Car Owner) ilovasi
- **O'ng** — Shinomontaj (Service) ilovasi

**Fidelity:** HIGH-FIDELITY — ranglar, tipografiya, spacing, shadow, animatsiyalar
aynan prototip kabi bo'lishi kerak.

---

## Tech Stack

| Platform | Tavsiya |
|---|---|
| iOS + Android | **Flutter** (Dart) — bitta codebase, ikki rol |
| Backend | Go + Gin + PostgreSQL (mavjud kod) |
| Auth | OTP via SMS (Eskiz.uz yoki SMS.uz) |
| To'lov (MVP) | QR mock UI — haqiqiy bank API keyinroq |
| Xarita | Google Maps Flutter / Yandex MapKit |
| Real-time | WebSocket (servis planshetiga bron bildirshnomalar) |

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
danger      = oklch(0.64 0.214 25)   // ≈ #E5382B — xato, bekor
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
fontFamily  = "Sora"           // Google Fonts — barcha UI matni
monoFamily  = "JetBrains Mono" // davlat raqami, narx, vaqt, OTP kod

// Shkala
displayLarge  = 29px, weight 700, letterSpacing -0.03em  // Onboarding sarlavha
displayMedium = 26px, weight 700, letterSpacing -0.03em  // Auth sarlavha
titleLarge    = 27px, weight 700, letterSpacing -0.03em  // Ekran sarlavhasi (large appbar)
titleMedium   = 19px, weight 600, letterSpacing -0.02em  // Appbar nomi
bodyLarge     = 16px, weight 400, letterSpacing -0.011em // Asosiy matn
bodyMedium    = 14.5px, weight 400
bodySmall     = 13px, weight 400, color textSecondary
labelLarge    = 16px, weight 600  // Tugma matni
labelMedium   = 13.5px, weight 500 // Chip matni
labelSmall    = 12px, weight 600, letterSpacing 0.07em, UPPERCASE // Sektsiya sarlavhasi
eyebrow       = 11px, weight 600, letterSpacing 0.12em, UPPERCASE, mono
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
shadow1   = (0, 1, 2,  0, rgba(0,0,0,0.18))
shadow2   = (0, 8, 30, 0, rgba(0,0,0,0.28))
shadowPop = (0, 18, 50, 0, rgba(0,0,0,0.40))
```

---

## Ekranlar va Oqimlar

### Mijoz (Car Owner) oqimi

```
Welcome → Rol tanlash → Onboarding (3 slayd) → Auth (OTP)
  └─ Bosh ekran [Home tab]
      ├─ Xizmat turi tanlash (3×2 grid, chip uslubi)
      │   └─ [Map pin] → Xarita + yaqin servislar bottom sheet
      │       └─ Servis profili
      │           └─ Vaqtga yozilish
      │               └─ Sana/vaqt tanlash → To'lovga o'tish
      │                   └─ Karta/QR/Keyinroq + Chaevoy → Tasdiqlash
      ├─ Yozuvlar [Bookings tab] — Kelgusi / O'tgan
      │   └─ Yo'nalish, Qo'ng'iroq, Sharh qoldirish, Qayta yozilish
      ├─ [Map center] → Xarita to'g'ridan-to'g'ri
      ├─ Avtomobil [Vehicles tab] — Mening avtomobillarim
      │   └─ Qo'shish (plaka + foto + o'lcham)
      └─ Profil [Profile tab] — Til, Tema, Chiqish
```

### Shinomontaj (Service) oqimi

```
Auth (OTP, service roli)
  └─ Bugungi bronlar [Today tab]
      ├─ Quick stats (daromad, bron soni, reyting)
      ├─ Yangi bron kartochkasi (real-time, pulsing indicator)
      │   └─ Qabul qilish / Rad etish
      └─ Kunlik jadval (vaqt bo'yicha)
          └─ Bron tafsilotlari
              ├─ Tasdiqlash → Boshlash → Bajarildi → To'lovni olish
              │   └─ QR generatsiya YOKI Naqd qabul
              └─ Bekor qilish
  ├─ Barcha bronlar [Bookings tab]
  │   ├─ Sana filtri (gorizontal chips)
  │   └─ Status filtri (barchasi/kutilmoqda/tasdiqlangan/...)
  ├─ [Stat center] → Statistika
  │   ├─ Bugun/Hafta/Oy segmented control
  │   ├─ Daromad + Bronlar + Reyting katta kartalar
  │   ├─ Revenue bar chart
  │   └─ Top xizmatlar progress list
  ├─ Mijozlar [Customers tab] — CRM
  │   ├─ Qidiruv
  │   └─ Mijoz kartochkasi → VIP belgilash → Eslatma
  └─ Profil [Profile tab]
      ├─ Ustaxona fotosi + nomi + manzil + ish vaqti
      ├─ Xizmat turlari (active chips)
      └─ Hozir ochiq toggle
```

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
```

### Bottom Nav — Owner

```
5 ta: Home | Bookings | [Map center] | Vehicles | Profile
Center: 60px doira, inverseBg fon, margin-top=-22px, shadow-2
Nav item: 10.5px 500, textTertiary (nofaol), textPrimary (aktiv)
```

### Bottom Nav — Service

```
5 ta: Today | Bookings | [Stats center] | Customers | Profile
Center: 60px doira, success fon (#30D158), shadow-success, margin-top=-22px
```

### Status Chip

```
pending:     bg=surface2,    text=textSecondary
confirmed:   bg=successDim,  text=success
in_progress: bg=goldDim,     text=gold
completed:   bg=surface2,    text=textTertiary
cancelled:   bg=dangerDim,   text=danger
```

### Plate badge

```
bg: #F4F4F2, text: #111
font: JetBrains Mono, weight 700
border: 1px rgba(0,0,0,0.2)
box-shadow: inset 0 0 0 2px #fff, 0 1px 2px rgba(0,0,0,.2)
size sm: padding 4px 9px, font 13px
size lg: padding 7px 14px, font 18px
```

---

## Animatsiyalar

```css
/* Ekran kirishi */
screen-in:   opacity 0→1 + translateX 22→0,  320ms cubic-bezier(0.16,1,0.3,1)

/* Element ko'tarilishi */
rise: opacity 0→1 + translateY 10→0, 400ms cubic-bezier(0.16,1,0.3,1)

/* Stagger (ro'yxat elementlari) */
item[n]: rise + delay n*40ms

/* Confirmation pop */
pop-in: scale(0.9)→scale(1) + opacity 0→1, 450ms cubic-bezier(0.16,1.4,0.3,1)

/* Sheet kirishi */
sheet-up: translateY(100%)→0, 340ms cubic-bezier(0.16,1,0.3,1)

/* Incoming booking pulse */
pulse-ring: scale(0.75)→scale(2.2), opacity 0.7→0, 1.8s ease-out infinite
```

> **Muhim:** Animatsiyalarni faqat `requestAnimationFrame` ishlaganda faollashtiring.
> Frozen/offscreen holatlarda kontent ko'rinishi kerak.

---

## Internationalization

- **Ikki til:** O'zbek (lotin) va Rus
- Barcha matnlar `shina24-i18n.jsx` dagi `STR` obyektida
- `makeT(lang)` → `t("key")` pattern
- Til toggle: Profil ekranida + Auth ekranida

---

## State Management (Flutter hint)

```dart
// Global state (Riverpod)
String lang           // "uz" | "ru"
String theme          // "dark" | "light"
String role           // "owner" | "service"
String route          // joriy ekran
String tab            // joriy bottom nav tab

// Owner booking flow
String? selectedSvcId
String? selectedShopId
String? selectedVehicleId
int?    selectedDate
String? selectedTime
int     tipAmount

// Payment
String paymentTiming  // "now" | "later" | "split"
String? selectedCard

// Service side
String? activeBookingId
String? activeCustomerId
String serviceBookingFilter  // "all" | status
String statsPeriod  // "today" | "week" | "month"
```

---

## API Endpointlar (Backend bilan moslashtirish)

```
POST /auth/send-otp
POST /auth/verify-otp

GET  /service-types           — Xizmat turlari katalog
GET  /services                ?lat=&lon=&service_type=&radius=
GET  /services/:id
GET  /services/:id/slots      ?date=&service_type=
PUT  /services/profile        — Servis profili yangilash

POST /bookings                { serviceId, serviceTypeId, vehicleId, scheduledAt }
GET  /bookings                ?status=upcoming|past
GET  /bookings/:id
PUT  /bookings/:id/cancel

GET  /service/bookings        ?date=&status=
PUT  /service/bookings/:id/confirm
PUT  /service/bookings/:id/start
PUT  /service/bookings/:id/complete
PUT  /service/bookings/:id/cancel

POST /payments/:booking_id
POST /payments/:booking_id/qr
POST /payments/:booking_id/tip

GET  /service/customers
GET  /service/customers/:id
PUT  /service/customers/:id
PUT  /service/customers/:id/vip

GET  /vehicles
POST /vehicles              { plate, make, wheelSize, photo }
DELETE /vehicles/:id

GET  /notifications
GET  /ws?token=<JWT>        — Real-time bron bildirshnomalar
```

---

## Fayllar

| Fayl | Tavsif |
|---|---|
| `Shina24 App.html` | **Asosiy prototip** — brauzerda oching, ikkita telefon |
| `shina24.css` | Dizayn system tokenlari va CSS utility klasslari |
| `shina24-i18n.jsx` | Barcha UI matnlar (O'z/Ru) |
| `shina24-data.jsx` | Mock ma'lumotlar (servislar, bronlar, CRM) |
| `shina24-icons.jsx` | 45+ SVG icon (24px line) |
| `shina24-ui.jsx` | Umumiy komponentlar (Button, ServiceCard, Plate, Toggle...) |
| `shina24-screens-auth.jsx` | Welcome, RoleSelect, Onboarding, Auth (OTP) |
| `shina24-screens-owner.jsx` | Home, Map, ServiceDetail, Booking, Payment, Confirm, Bookings, Vehicles |
| `shina24-screens-service.jsx` | Dashboard, BookingDetail, PaymentReceipt, AllBookings, CRM, Stats, Profile |
| `shina24-screens-account.jsx` | OwnerProfile, OwnerNotifications |
| `ios-frame.jsx` | iPhone 14 Pro ramkasi (identik Moshn bilan) |

---

## UX Qoidalar

1. **Davlat raqami** — har doim `JetBrains Mono`, UPPERCASE, `01 A 000 AA` format
2. **Narxlar** — `JetBrains Mono`, minglar bo'sh joy bilan: `80 000 so'm`
3. **OTP** — 5 ta box, oxirgi raqam kiritilganda 350ms da avtomatik yuborish
4. **Slot tanlash** — vaqt tanlanmagan holda "To'lovga o'tish" disabled
5. **Yangi bron (servis)** — har doim pulsing indicator + yuqorida floating card
6. **Status o'zgarishi** — servis tomonida: pending → confirmed → in_progress → completed → to'lov
7. **VIP mijoz** — crown badge + gold chip, CRM da ajralib turishi kerak
8. **Tema** — system preference'dan boshlash, keyin foydalanuvchi o'zgartira oladi
9. **Mavsum push** — server-side: oktyabr (qish), mart (yoz) — owner bildirshnomalar

---

## MVP Cheklovlari

| Funksiya | Holat | Kelajak |
|---|---|---|
| To'lov | QR mock UI | Payme / Click API |
| Bo'lib to'lash | UI only | Bank/MFO API |
| Real-time WebSocket | Mock (UI simulatsiya) | Haqiqiy WS |
| Xarita | SVG stilizatsiya | Google Maps / Yandex MapKit |
| Push notifications | Mock UI | FCM |

---

*Yaratilgan: Shina24 Design System v1.0 — Claude Sonnet bilan*  
*Sana: 2026-yil iyun*
