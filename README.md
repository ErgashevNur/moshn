# PitGo

> Farg'ona vodiysi mashina egalari uchun **VIN-markazli servis tarixi platformasi**.

Mashina egalari va ustalar birgalikda avtomobilning texnik tarixini yuritadi. Mashina sotilganda butun tarix yangi egaga o'tadi. Ustalar xarita orqali topiladi va verifikatsiyalanadi.

**Asosiy g'oya:** e'lon platformasi emas — *servis tarixi va ishonch infratuzilmasi*. VIN o'zgarmas, ma'lumot abadiy.

---

## Mundarija

- [Imkoniyatlar](#imkoniyatlar)
- [Arxitektura](#arxitektura)
- [Texnologiyalar](#texnologiyalar)
- [Repo tuzilishi](#repo-tuzilishi)
- [Lokal ishga tushirish](#lokal-ishga-tushirish)
- [Muhit oʻzgaruvchilari (.env)](#muhit-ozgaruvchilari-env)
- [Serverga deploy](#serverga-deploy)
- [APK build](#apk-build)
- [API qisqacha](#api-qisqacha)
- [Ma'lumotlar modeli](#malumotlar-modeli)

---

## Imkoniyatlar

### Mashina egasi
- **Avtomobil ro'yxati** — VIN/davlat raqami orqali, texpasport **OCR** bilan avtomatik to'ldirish (Claude API)
- **Servis tarixi** — har bir mashinaning to'liq texnik tarixi
- **Egalik o'tkazish** (`transfer`) — sotuvda tarix bilan birga yangi egaga
- **Usta qidirish** — xarita (Yandex/OSM) orqali yaqin va verifikatsiyalangan ustalar
- **Sharhlar** (review) — ustalarga baho
- **Kafolat da'vosi** (warranty claim)
- **SOS** — favqulodda yo'l yordami (joylashuv bilan, real-time)
- **Tamirlash so'rovi** — ustani tanlab so'rov yuborish
- **Push bildirishnoma** (FCM), ko'p tillilik (uz/ru)

### Usta (mechanic)
- Servis yozuvlarini yaratish — shu jumladan **ovozli kiritish** (UzbekVoice STT + Claude parsing)
- Foto biriktirish
- O'ziga yo'naltirilgan SOS/tamirlash so'rovlarini ko'rish
- Profil va xizmatlarni boshqarish

### Admin / operator panel
- Statistika dashboard
- Ustalarni qo'shish va **verifikatsiya** qilish
- Foydalanuvchi, mashina, servis, sharhlarni boshqarish va moderatsiya
- **SOS va tamirlash so'rovlarini ustaga taqsimlash** (real-time WebSocket)
- Ommaviy bildirishnoma yuborish (broadcast)

---

## Arxitektura

```
                       ┌─────────────────────────────┐
   Android APK ───────►│  api.pitgo.uz   (nginx :443) │──► backend  (Go/Gin :8080) ──┐
                       │                              │                              │
   Admin (brauzer) ───►│  admin.pitgo.uz              │──► admin   (Next.js :3000)   │
                       │                              │                              ▼
   APK yuklab olish ──►│  media.pitgo.uz  → pitgo.apk │                       postgres :5432
                       └─────────────────────────────┘
   pitgo.uz / www  →  Vercel (landing, alohida)
```

Hammasi bitta serverda **Docker Compose** orqali: `postgres` + `backend` + `admin` + `nginx`. Fayllar (`uploads`) va DB (`pgdata`) Docker volume'larida.

---

## Texnologiyalar

| Qatlam | Texnologiya |
|--------|-------------|
| **Backend** | Go 1.21, Gin, GORM, PostgreSQL 16, JWT, bcrypt |
| **Admin** | Next.js 14 (standalone), React 18, Axios |
| **Mobile** | Flutter (Riverpod, go_router, Dio, flutter_map, geolocator, firebase_messaging, easy_localization) |
| **Integratsiyalar** | Claude API (OCR + voice parsing), UzbekVoice (STT), Firebase FCM (push), Yandex Maps, SMTP (email/OTP) |
| **Infra** | Docker Compose, Nginx (reverse proxy), Let's Encrypt (SSL) |

Xavfsizlik: global rate-limit (120 req/min/IP), auth endpointlarda qattiqroq (10 req/min/IP), JWT access+refresh, rolga asoslangan ruxsat (`AdminOnly`, `MechanicOnly`).

---

## Repo tuzilishi

```
pitgo/
├── Backend/
│   ├── docker-compose.yml      # postgres + backend + admin + nginx
│   ├── .env.example            # muhit o'zgaruvchilari namunasi
│   ├── DEPLOY.md               # deploy qo'llanmasi
│   ├── nginx/nginx.conf        # 3 subdomen + SSL
│   ├── backend/                # Go/Gin API
│   │   ├── main.go             # auto-migrate + server
│   │   ├── config/ models/ handlers/ services/ middleware/ routes/ utils/
│   │   └── tools/              # createadmin, seed
│   ├── admin/                  # Next.js admin panel
│   └── media/                  # media.pitgo.uz: index.html + pitgo.apk
└── Flutter/                    # Android ilova
    ├── lib/                    # services/api.dart (API_BASE_URL override)
    └── android/                # release signing (key.properties)
```

---

## Lokal ishga tushirish

### Talablar
Go 1.21+, Node 20+, Flutter, PostgreSQL 16 (yoki Docker), Android SDK.

### Backend (`:8080`)
```bash
cd Backend/backend
cp ../.env.example ../.env     # qiymatlarni to'ldiring (lokal uchun DATABASE_URL)
go run .                       # auto-migrate + server
# admin yaratish:
go run ./tools/createadmin --phone "+998..." --email "admin@pitgo.uz" --password "..."
go run ./tools/seed           # (ixtiyoriy) test ma'lumotlari
```

### Admin panel (`:3000`)
```bash
cd Backend/admin
npm install
NEXT_PUBLIC_API_URL=http://localhost:8080/v1 npm run dev
```

### Flutter (Android)
```bash
cd Flutter
flutter pub get
# Emulyator avtomatik http://10.0.2.2:8080/v1 ga ulanadi.
# Haqiqiy qurilma uchun LAN IP:
flutter run --dart-define=API_HOST=192.168.x.x
# (adb reverse tcp:8080 tcp:8080 ham ishlatish mumkin)
```

### Docker bilan (lokal to'liq stack)
```bash
cd Backend
cp .env.example .env           # DB_PASSWORD, JWT_SECRET, ... to'ldiring
docker compose up -d --build
```

---

## Muhit oʻzgaruvchilari (.env)

`Backend/.env.example` dan nusxa oling. Asosiylari:

| O'zgaruvchi | Tavsif | Majburiy |
|-------------|--------|:--------:|
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | PostgreSQL (compose) | ✅ |
| `JWT_SECRET` | uzun tasodifiy satr | ✅ |
| `CLAUDE_API_KEY` | OCR va ovoz parsing | ✅ (shu funksiyalar uchun) |
| `NEXT_PUBLIC_API_URL` | admin build-time API URL | ✅ |
| `ALLOWED_ORIGINS` | CORS origin(lar)i | ✅ |
| `UZBEKVOICE_API_KEY` | nutqni matnga | ixtiyoriy |
| `FCM_SERVER_KEY` | push bildirishnoma | ixtiyoriy |
| `YANDEX_MAPS_API_KEY` | xarita | ixtiyoriy |
| `SMTP_*` | email/OTP yuborish | ixtiyoriy |

> ⚠️ `.env`, `key.properties`, `*.jks`, `google-services.json` — **commit qilinmaydi** (`.gitignore` da).

---

## Serverga deploy

To'liq qo'llanma: [`Backend/DEPLOY.md`](Backend/DEPLOY.md).

Qisqacha (Ubuntu server):
```bash
# 1) Docker o'rnatish
curl -fsSL https://get.docker.com | sh

# 2) Kodni ko'chirish (rsync — .env ni clobber qilmaslik uchun exclude qiling)
rsync -az --exclude '.env' --exclude 'node_modules' --exclude '.next' \
  Backend/ root@SERVER:/opt/pitgo/Backend/

# 3) Production .env tayyorlash va ishga tushirish
cd /opt/pitgo/Backend
cp .env.example .env && nano .env
docker compose up -d --build

# 4) Admin yaratish
docker compose exec backend ./createadmin --phone "+998..." --email "..." --password "..."

# 5) SSL (DNS server IP ga ishora qilgach)
docker run --rm -v $PWD/certbot/conf:/etc/letsencrypt -v $PWD/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d api.pitgo.uz -d admin.pitgo.uz -d media.pitgo.uz --email you@pitgo.uz --agree-tos
```

**DNS (A yozuvlar → server IP):** `api.pitgo.uz`, `admin.pitgo.uz`, `media.pitgo.uz`.
SSL avtomatik yangilanadi (`/opt/pitgo/renew-cert.sh` cron).

---

## APK build

```bash
cd Flutter
flutter build apk --release --dart-define=API_BASE_URL=https://api.pitgo.uz/v1
# natija: build/app/outputs/flutter-apk/app-release.apk
```

Release imzo `android/key.properties` orqali (`*.jks` keystore). APK `media.pitgo.uz/pitgo.apk` ga joylanadi.

---

## API qisqacha

Bazaviy URL: `https://api.pitgo.uz/v1` · Sog'liq: `GET /health`

| Guruh | Asosiy endpointlar |
|-------|--------------------|
| **Auth** | `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/send-otp`, `/auth/verify-otp` |
| **Profil** | `GET/PUT /profile`, `/profile/language`, `/profile/avatar` |
| **Mashina** | `POST/GET /vehicles`, `/vehicles/:id`, `/vehicles/ocr`, `/vehicles/:id/history`, `/vehicles/:id/transfer` |
| **Servis** | `POST /services` (usta), `/services/voice`, `/services/:id/confirm|reject`, `/services/pending` |
| **Usta** | `GET /mechanics`, `/mechanics/:id`, `/mechanics/:id/reviews`, `/mechanics/my-services` |
| **Sharh** | `POST /reviews`, `GET /reviews/:id` |
| **Kafolat** | `POST/GET /warranty` |
| **SOS / Tamir** | `POST/GET /sos`, `/repair-requests`, `/mechanic/assignments` |
| **Bildirishnoma** | `GET /notifications`, `/notifications/fcm-token` |
| **Real-time** | `GET /ws` (WebSocket, token query bilan) |
| **Admin** | `/admin/stats`, `/admin/mechanics`, `/admin/services`, `/admin/sos`, `/admin/repair-requests`, ... (`AdminOnly`) |

---

## Ma'lumotlar modeli

`User`, `Mechanic`, `Vehicle`, `PlateHistory`, `OwnershipHistory`, `ServiceRecord`, `Review`, `WarrantyClaim`, `Notification`, `FCMToken`, `SosRequest`, `RepairRequest`.

Migratsiya backend ishga tushganda **avtomatik** bajariladi (GORM AutoMigrate).

---

## Litsenziya

Xususiy loyiha (proprietary). Barcha huquqlar himoyalangan.
