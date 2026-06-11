# Shina24 — Loyiha hujjati

> Shinomontaj servislar uchun bron va boshqaruv platformasi

---

## Loyiha haqida

**Shina24** — shinomontaj nuqtalari va mijozlar o'rtasidagi raqamli ko'prik.

- **Mijoz (Car owner):** ilovaga kiradi → xizmat turini tanlaydi → shinomontaj topadi → bron qiladi → to'laydi
- **Servis (Shinomontaj):** planshet/telefonda bronlar keladi → qabul qiladi → xizmat ko'rsatadi → to'lov oladi → mijozni baholaydi
- **Admin:** servislarni ro'yxatga oladi, mavsum bildirishnomalarini boshqaradi, statistika ko'radi

**Asosiy farq (Moshn → Shina24):**  
Moshn umumiy xizmat tarixi edi. Shina24 — bron tizimi + to'lov + CRM, faqat shinomontaj uchun.

**Kod bazasi:** mavjud Moshn kodi asosida refactor  
**App:** bitta Flutter app, ikki rol (owner / service)  
**To'lov (MVP):** faqat QR/karta UI — haqiqiy bank API keyinroq

---

## Arxitektura

```
moshn/  (Shina24 loyihasi)
├── Backend/
│   ├── backend/        # Go + Gin API serveri (:8080)
│   ├── admin/          # Next.js 14 admin panel (:3000)
│   ├── nginx/          # Reverse proxy + SSL
│   ├── media/          # Statik fayllar (APK)
│   ├── docker-compose.yml
│   └── .env.example
└── Flutter/            # Android ilovasi — mijoz + servis (ikki rol)
```

### Texnologiyalar

| Qism | Texnologiya |
|------|-------------|
| Backend | Go 1.21, Gin, GORM, PostgreSQL 16 |
| Admin panel | Next.js 14 (App Router), React 18, Tailwind CSS, Axios |
| Mobile | Flutter, Dart 3.11, Riverpod 2.6, go_router, Dio |
| Deployment | Docker Compose, Nginx, Let's Encrypt |
| AI (kerak bo'lsa) | Claude API |

---

## TZ — Texnik Topshiriq (Shina24)

### Mijoz (Car Owner) funksiyalari

| # | Funksiya | Tavsif | Holat |
|---|----------|--------|-------|
| C-1 | **Avtomobil ro'yxatga olish** | Plaka raqami + foto. Kelajakda plaka bo'yicha egasiga qo'ng'iroq ("autosignal" — Real24 dagi kabi) | Loyihalash |
| C-2 | **Kirgan zahoti qidiruv + xizmat turi tanlash** | Bosh ekranda darhol xizmat turi (podkachka, perezobuvka, disk ta'mir, ...) tanlash, keyin yaqin servislar | Loyihalash |
| C-3 | **Mavsum bildirshnomalari** | Qish/yoz almashganda "shinani almashtirish vaqti" push bildirishnomasi | Loyihalash |
| C-4 | **Keyinroq to'lash** | Bank / MFO bilan integratsiya — xizmatni olib, keyinroq to'lash | MVP: UI only |
| C-5 | **Chayivoye (tips)** | Xizmat ko'rsatgach mexanikka qo'shimcha tip qoldirish | Loyihalash |

### Servis (Shinomontaj) funksiyalari

| # | Funksiya | Tavsif | Holat |
|---|----------|--------|-------|
| S-1 | **Planshet + telefon bildirshnomalar** | Servis nuqtasida planshet bor; bron, bekor qilish, yangi so'rov — hammasiga real-vaqt bildirshnoma | Loyihalash |
| S-2 | **Planshetda to'lov** | Karta yaqinlashtirish (terminal kabi) **yoki** QR kod — mijoz skanerlab to'laydi | MVP: QR UI |
| S-3 | **Bo'lib to'lash** | Mushtariy xizmatni bo'lib to'lash rejasida oladi | MVP: UI only |
| S-4 | **Mijozni baholash** | Servis mijozga yulduz qo'yadi (ikki tomonlama reyting) | Loyihalash |
| S-5 | **Mijozlar bazasi** | Telefon raqam, ism, avtomobil, VIP belgisi, tashrif tarixi — servis o'z CRM'iga ega | Loyihalash |

---

## Ma'lumotlar Bazasi — Yangi va O'zgaradigan Modellar

### Qoladigan modellar (refactor bilan)

| Model | O'zgarish |
|-------|-----------|
| `User` | Rol: `owner` / `service` / `admin` (mechanic → service) |
| `Vehicle` | VIN o'chadi → plaka raqami asosiy. Autosignal uchun eganing telefoni ko'rsatiladi |
| `Notification` | Qoladi, mavsum bildirshnomasi tipi qo'shiladi |
| `FCMToken` | O'zgarmaydi |
| `Review` | Ikki tomonlama: owner→service **va** service→owner |

### Yangi modellar

```go
// Shinomontaj servis profili (hozirgi Mechanic o'rniga)
type Service struct {
    ID          uuid.UUID
    UserID      uuid.UUID   // service roli bilan User
    Name        string      // "Shina24 Yunusobod"
    Address     string
    Lat, Lng    float64
    Phone       string
    WorkingHours string     // "08:00-20:00"
    ServiceTypes pq.StringArray // ["podkachka","perezobuvka","disk_repair"]
    IsVerified  bool
    Rating      float64
    CreatedAt   time.Time
}

// Xizmat turlari (katalog)
type ServiceType struct {
    ID       uuid.UUID
    Slug     string   // "podkachka"
    NameUz   string   // "Podkachka"
    NameRu   string   // "Подкачка"
    Icon     string   // emoji yoki icon nomi
    BasePrice int     // taxminiy narx (UZS)
}

// Bron / Appointment
type Booking struct {
    ID            uuid.UUID
    CustomerID    uuid.UUID   // User (owner)
    ServiceID     uuid.UUID   // Service (shinomontaj)
    VehicleID     uuid.UUID
    ServiceTypeID uuid.UUID
    ScheduledAt   time.Time
    Notes         string
    Status        string      // pending / confirmed / in_progress / completed / cancelled
    TotalPrice    int
    CreatedAt     time.Time
}

// To'lov
type Payment struct {
    ID         uuid.UUID
    BookingID  uuid.UUID
    Amount     int         // UZS
    Method     string      // "card_qr" / "cash" / "installment"
    Status     string      // "pending" / "paid" / "failed"
    QRCode     string      // To'lov QR (MVPda mock)
    PaidAt     *time.Time
    CreatedAt  time.Time
}

// Bo'lib to'lash rejasi (MVP: UI only)
type Installment struct {
    ID         uuid.UUID
    PaymentID  uuid.UUID
    Parts      int         // necha qismga
    PartAmount int
    DueDate    time.Time
    PaidAt     *time.Time
    Status     string      // "pending" / "paid"
}

// Chayivoye / Tip
type Tip struct {
    ID        uuid.UUID
    BookingID uuid.UUID
    Amount    int
    CreatedAt time.Time
}

// Servisning mijoz CRM kartochkasi
type CustomerCard struct {
    ID           uuid.UUID
    ServiceID    uuid.UUID   // qaysi servisga tegishli
    CustomerID   uuid.UUID   // User (owner)
    IsVip        bool
    Notes        string
    VisitCount   int
    LastVisitAt  *time.Time
    CreatedAt    time.Time
}

// Mavsum bildirshnomalari qoidasi
type SeasonalRule struct {
    ID          uuid.UUID
    Name        string      // "Qish shinasi almashtiruvi"
    SendMonth   int         // 10 (oktyabr) yoki 4 (aprel)
    SendDay     int
    MessageUz   string
    MessageRu   string
    IsActive    bool
    LastSentAt  *time.Time
}
```

### O'chiriladigan modellar

```
- Mechanic           → Service ga almashadi
- ServiceRecord      → Booking ga almashadi (shinomontaj kontekstida)
- WarrantyClaim      → o'chadi
- SosRequest         → o'chadi
- RepairRequest      → o'chadi (Booking qoplaydiu)
- PlateHistory       → o'chadi (VIN yo'q endi)
- OwnershipHistory   → o'chadi
```

---

## API Endpointlar — Yangi Tuzilma

**Asosiy URL:** `/v1`

### Autentifikatsiya (o'zgarmaydi)
```
POST /auth/register
POST /auth/login
POST /auth/refresh
POST /auth/send-otp
POST /auth/verify-otp
```

### Avtomobil (soddalashadi)
```
POST   /vehicles            — Plaka + foto qo'shish
GET    /vehicles            — Mening avtomobillarim
GET    /vehicles/:id        — Avtomobil tafsilotlari
PUT    /vehicles/:id        — Yangilash
DELETE /vehicles/:id        — O'chirish
GET    /vehicles/lookup/:plate — Plaka bo'yicha qidirish (autosignal)
```

### Servis turları (katalog)
```
GET /service-types          — Barcha xizmat turlari (podkachka, ...)
```

### Shinomontaj Servislar
```
GET  /services              — Qidiruv (geo + xizmat turi filtri)
GET  /services/:id          — Servis profili + narxlar
PUT  /services/profile      — Servis profilini yangilash (service roli)
GET  /services/my           — Mening servisim (service roli)
```

### Bronlar
```
POST /bookings              — Bron yaratish (owner)
GET  /bookings              — Mening bronlarim
GET  /bookings/:id          — Bron tafsilotlari
PUT  /bookings/:id/cancel   — Bekor qilish (owner)

GET  /service/bookings      — Servisga kelgan bronlar (service roli)
PUT  /service/bookings/:id/confirm   — Tasdiqlash
PUT  /service/bookings/:id/complete  — Bajarildi
PUT  /service/bookings/:id/cancel    — Servis tomonidan bekor qilish
```

### To'lov
```
POST /payments/:booking_id          — To'lov boshlash
GET  /payments/:booking_id          — To'lov holati
POST /payments/:booking_id/qr       — QR kod generatsiya (MVPda mock)
POST /payments/:booking_id/tip      — Chayivoye qo'shish
POST /payments/:booking_id/installment — Bo'lib to'lash rejasi (UI only)
```

### Baholash
```
POST /reviews               — Baholash (owner → service YOKI service → owner)
GET  /reviews/service/:id   — Servis sharhlari
GET  /reviews/customer/:id  — Mijoz sharhlari (servis ko'radi)
```

### Servisning Mijozlar CRM
```
GET  /service/customers          — Barcha mijozlar ro'yxati
GET  /service/customers/:id      — Mijoz kartochkasi
PUT  /service/customers/:id/vip  — VIP belgilash/olib tashlash
PUT  /service/customers/:id      — Eslatma qo'shish
```

### Bildirishnomalar
```
GET  /notifications              — Mening bildirishnomalarim
PUT  /notifications/:id/read     — O'qildi
POST /notifications/fcm-token    — FCM token ro'yxatga olish
```

### Real-vaqt (WebSocket)
```
GET /ws?token=<JWT>   — Servis planshetiga jonli bron bildirshnomalar
```

### Admin
```
GET    /admin/stats
GET    /admin/services                — Barcha servislar
PUT    /admin/services/:id/verify     — Servisni tasdiqlash
GET    /admin/bookings                — Barcha bronlar
GET    /admin/users                   — Foydalanuvchilar
GET    /admin/seasonal-rules          — Mavsum qoidalari
POST   /admin/seasonal-rules          — Yangi qoida yaratish
PUT    /admin/seasonal-rules/:id      — Tahrirlash
POST   /admin/notifications/broadcast — Barcha foydalanuvchilarga push
POST   /admin/notifications/season    — Mavsum pushini qo'lda yuborish
```

---

## Flutter App — Yangi Ekranlar

### Owner (Mijoz) oqimi

```
Xush kelibsiz → Rol tanlash → Ro'yxat/Kirish
  └─ Bosh ekran
      ├─ Xizmat turi tanlash (chip/card)
      │   └─ Yaqin servislar ro'yxati + xarita
      │       └─ Servis profili → Bron qilish
      │           └─ Sana/vaqt tanlash → Tasdiqlash → To'lov
      │               └─ QR kod yoki "Keyinroq to'lash"
      ├─ Mening bronlarim (joriy + tarix)
      │   └─ Bron tafsilotlari → Baholash → Tip qoldirish
      ├─ Avtomobillarim
      │   └─ Qo'shish (plaka + foto)
      ├─ Bildirishnomalar
      └─ Profil
```

### Service (Shinomontaj) oqimi

```
Kirish (service roli)
  └─ Bosh ekran — bugungi bronlar
      ├─ Yangi bron kartochkasi (real-vaqt WebSocket)
      │   └─ Tasdiqlash / Bekor qilish
      ├─ Barcha bronlar (sana filtri)
      │   └─ Bron tafsilotlari → Bajarildi → To'lov olish
      │       └─ QR generatsiya YOKI Naqd
      ├─ Mijozlar bazasi (CRM)
      │   └─ Mijoz kartochkasi → VIP belgilash → Eslatma
      ├─ Statistika (bugun/hafta/oy)
      └─ Profil (ustaxona ma'lumotlari, ish vaqti, xizmat turlari)
```

---

## Admin Panel — Yangi Sahifalar

| Yo'l | Maqsad |
|------|--------|
| `/dashboard` | Statistika: bronlar, to'lovlar, foydalanuvchilar |
| `/services` | Shinomontajlar ro'yxati + tasdiqlash |
| `/bookings` | Barcha bronlar + filtrlash |
| `/users` | Foydalanuvchilar |
| `/seasonal` | Mavsum bildirshnoma qoidalari boshqaruvi |
| `/reviews` | Sharhlar moderasiyasi |
| `/notifications` | Broadcast push |

---

## Ishga Tushirish (o'zgarmaydi)

```bash
# Backend
cd Backend/backend && go run .

# Admin
cd Backend/admin && npm run dev

# Flutter
cd Flutter && flutter run

# Docker (production)
cd Backend && docker compose up -d --build
```

---

## O'zgarishlar Jurnali

| Sana | Soha | O'zgarish | Sabab |
|------|------|-----------|-------|
| 2026-06-06 | Hujjat | CLAUDE.md birinchi versiya (Moshn) | Loyihani o'rganib tahlil |
| 2026-06-06 | TZ | Shina24 TZ qo'shildi, barcha modellar va ekranlar rejalashtirildi | Loyiha Moshn → Shina24 ga pivot |
| 2026-06-06 | Backend | **1-bosqich to'liq refactor** — models, services, handlers, routes, middleware yangilandi. `go build` 0 xato | Shina24 TZ asosida |

---

## Refactor Rejasi (Navbat bo'yicha)

### 1-bosqich — Backend yadro
- [ ] `Mechanic` modeli → `Service` ga refactor
- [ ] `ServiceRecord` → `Booking` ga refactor
- [ ] Yangi modellar qo'shish: `Booking`, `Payment`, `Tip`, `CustomerCard`, `SeasonalRule`
- [ ] `SosRequest`, `RepairRequest`, `WarrantyClaim` endpointlari o'chirish
- [ ] `/vehicles` — VIN olib tashlash, plaka asosiy, `/lookup/:plate` qo'shish
- [ ] `/services` qidiruv — xizmat turi filtri
- [ ] WebSocket — servisga bron bildirshnomalari

### 2-bosqich — Flutter UI
- [ ] Bosh ekran — xizmat turi tanlash chip-lari
- [ ] Servis qidiruv + xarita
- [ ] Bron qilish oqimi (sana/vaqt)
- [ ] To'lov ekrani (QR mock)
- [ ] Servis roli: bosh ekran (bronlar), CRM, to'lov olish
- [ ] Tip qoldirish ekrani
- [ ] Ikki tomonlama reyting

### 3-bosqich — Admin Panel
- [ ] Seasonal rules sahifasi
- [ ] Servislar sahifasi (yangi format)
- [ ] Bronlar statistikasi

### 4-bosqich — Kelajak (MVP dan keyin)
- [ ] Haqiqiy bank/MFO integratsiya (Payme / Click)
- [ ] Bo'lib to'lash haqiqiy logikasi
- [ ] Plaka bo'yicha qo'ng'iroq (autosignal)
- [ ] Mavsum cron bildirshnomasi

---

## Ma'lum Cheklovlar (MVP)

| Muammo | Hozirgi holat | Kelajak |
|--------|--------------|---------|
| To'lov | QR mock UI, haqiqiy integratsiya yo'q | Payme / Click API |
| Bo'lib to'lash | UI only | Bank/MFO API |
| Autosignal (plaka qo'ng'irog'i) | Loyihalash bosqichi | Keyinroq |
| Mavsum cron | Qo'lda admin trigger | Avtomatik scheduler |
| Karta terminal | UI only | Hardware terminal integratsiya |
