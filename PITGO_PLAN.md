# PitGo — ish rejasi

> Kontekst: `CLAUDE.md`.
> Fazalar tartib bilan bajariladi. Har bir vazifa tugagach, shu fayldagi
> katakchani belgilang va qisqacha nima qilinganini yozing.

**Tartib:** 0 → 1 → 2 → 3 → 4
**Bog'liqlik:** 3-faza (SOS) 2-fazasiz yozilmasin — SOS ham ustaga so'rov yuboradi,
usta modeli bo'lmasa keyin qayta yozishga to'g'ri keladi.

---

## FAZA 0 — Xavfsizlik (birinchi navbatda, bugun)

Repoda maxfiy ma'lumot ochiq yotibdi.

- [x] **Firebase service account kalitini almashtirish** — yangi kalit
      (`0c94837fc7`) yaratildi, `nest-backend/.env`ga bir qatorlik JSON qilib
      ulandi (backend `FIREBASE_SERVICE_ACCOUNT` env'dan o'qiydi). Eski/yangi
      `.json` fayllar diskdan o'chirildi.
      - ⚠️ **Qoldi:** Firebase Console'da eski kalitni (`fcf8e90332`) revoke qilish.
        Muhim: eski fayl git tarixida **umuman bo'lmagan** (`.gitignore` qamragan).
      - ℹ️ Serverga deploy'da kalit `Backend/.env` (compose) ga qo'yiladi.
- [x] `Moshn.zip` — git kuzatuvidan chiqarildi, lokal fayl saqlandi.
      (Tarixda `c9c84ef` da qolgan; to'liq o'chirish = tarix qayta yozish, past ustuvorlik.)
- [x] `.gitignore` — `Moshn.zip` qo'shildi (firebase/`.env`/uploads/media allaqachon bor edi).
- [x] `.env.example` tekshirildi — faqat placeholder qiymatlar, haqiqiy sir yo'q.

**Holat:** repoda amaldagi kalit/parol yo'q. Qolgan yagona ish — Console'da eski
kalitni revoke qilish (lokal loyiha uchun shoshilinch emas).

---

## FAZA 1 — Baseline migratsiya

Hozir `prisma/migrations/` bo'sh, `db push` bilan ishlangan. Sxemani
o'zgartirishdan oldin bu tuzatilishi kerak, aks holda prodda ma'lumot
yo'qolishi mumkin va orqaga qaytarish yo'q.

- [x] Baseline migratsiya `0_init` yaratildi (15 jadval, `migrate diff --from-empty`).
- [x] Mavjud baza `resolve --applied 0_init` bilan bog'landi (DDL ishlamadi).
- [ ] ⏸️ PostGIS **keyinga qoldirildi** — bu postgres imijida postgis paketi yo'q
      **va** `moshn` user superuser emas (`CREATE EXTENSION` ruxsat bermaydi).
      Faza 3'da `postgis/postgis:16-3.4` imijiga o'tilganda qo'shiladi.
- [x] `DEPLOY.md` §3.1 — migratsiya tartibi yozildi, "avtomatik" degan xato tuzatildi.
- [x] Qoida o'rnatildi: `db push` emas, `migrate dev` / `migrate deploy`.

**Holat:** `migrate status` → "Database schema is up to date". Baseline ishlaydi.
PostGIS Faza 3 ochilishida hal qilinadi.

---

## FAZA 2 — Usta (Master) modeli

Eng katta ish. Hozir tizim servis darajasida: `Booking → ShopProfile`.
PitGo talab qiladi: mijoz **aniq ustaga** yoziladi.

### 2.1 Sxema

- [x] `Master` modeli yaratildi: `id, shopId, userId, fullName, position,
      avatarUrl, isActive, ratingAvg, ratingCount, createdAt, updatedAt`.
- [x] `Master.userId → User` (@unique) — har bir ustaning alohida logini.
- [~] Rol: mavjud rollar `'owner'/'service'/'admin'` (kichik harf). Yangi rol
      **`'master'`** bo'ladi — hali sxemada emas, backend (2.3) da qo'llanadi.
- [x] `Booking.masterId` **nullable** qilib qo'shildi (2.2 backfill'dan keyin majburiy).
- [x] ~~`Review.masterId`~~ — QILINMADI. Mavjud polimorf Review ishlatiladi:
      yangi `reviewType='owner_to_master'` (`targetId=masterId`). Reyting
      `Master.ratingAvg/ratingCount` da yig'iladi.
- [x] `MasterServiceType` yaratildi (SOS filtri uchun) + `service_type_id` indeksi.
- [ ] ⏸️ `EXCLUDE USING gist` cheklovi **keyinga qoldirildi**: `Booking`da tugash
      vaqti yo'q (faqat `scheduledAt`) + `btree_gist` superuser talab qiladi.
      Booking'ga davomiylik/`endAt` qo'shilgach alohida bosqichda.
- Migratsiya: `20260807190817_add_master` (qo'llandi). FK indekslari qo'shildi.

### 2.2 Ma'lumot migratsiyasi

- [x] Har bir `ShopProfile` uchun standart usta yaratildi (userId = servis egasi).
      6 servis → 6 usta. Migratsiya: `20260807191300_backfill_masters`.
- [x] Mavjud 8 `Booking` standart ustaga bog'landi (`masterId` bo'sh 0 ta).
- [x] `master_service_types` `shop_service_prices`'dan to'ldirildi (6 yozuv).
- [~] Mavjud `Review` larni bog'lash — KERAK EMAS. Master reytingi yangi
      `reviewType='owner_to_master'` orqali; eski review'lar `owner_to_shop`/
      `shop_to_owner`, ular tegishli emas.
- [x] `masterId` NOT NULL qilindi (backend ulangach). FK SET NULL → RESTRICT.
      Migratsiya: `20260807192829_booking_master_required`.

### 2.3 Backend

- [x] `masters` moduli: CRUD — `GET/POST /v1/service/masters`,
      `PUT/DELETE /v1/service/masters/:id`. Usta qo'shishда `'master'` rolli User
      login yaratiladi (bcrypt parol, tranzaksiyada).
- [x] Huquqlar: `MasterRoleGuard`. Usta `GET /v1/master/bookings` orqali faqat
      o'z bronlarini ko'radi; egasi `service/bookings` orqali hammasini.
- [x] Bandlik hisobi usta bo'yicha: `GET /v1/masters/:id/booked-slots`.
- [x] Ommaviy: `GET /v1/shops/:id/masters`, `/v1/masters/:id` (kartochka),
      `/v1/masters/:id/reviews`. Usta kabineti: `GET /v1/master/profile`.
      Reyting ikki darajali: `owner_to_master` review → `Master.ratingAvg`.
      Tekshirildi: `nest build` ✓, boot ✓, 10 route ✓, ommaviy endpoint ✓.

### 2.4 Flutter

- [x] **Yozilishda usta tanlash qadami** — `create_booking_screen`da usta bo'limi
      (xizmatga qarab filtr, reyting). `booking_service` `master_id` yuboradi,
      bandlik usta bo'yicha (`/masters/:id/booked-slots`).
      Model: `master.dart`, service: `master_service.dart`.
      ⚠️ Bu **kritik yo'l** edi — backend `masterId`ni majburiy qilgach, booking
      buzilgan edi; endi tiklandi. `flutter analyze` toza.
- [x] Servis sahifasida (shop_detail) ustalar ro'yxatini ko'rsatish — "Мастера"
      bo'limi (ism, lavozim, reyting).
- [x] Servis egasi kabineti: usta qo'shish/tahrirlash UI — menyu → "Мастера",
      `masters_screen` (ro'yxat + forma: telefon/email/parol/ism/lavozim +
      xizmatlar multi-select, nofaol qilish). Qo'shishда `'master'` login yaratiladi.
- [x] Usta uchun login va o'z kabineti — `UserRole.master`, router `master →
      /mechanic` (otp_screen ham), `mechanic_root` (2 tab: Записи + Профиль),
      usta bronlari ekrani (`master/bookings`). Ilgari usta `role=none` bo'lib
      `/role-select`da qamalardi — tuzatildi. `flutter analyze`: 0 error.
- [x] Sharh qoldirishda ustaga ham baho — `booking_detail` sharh oynasida
      servis + usta bahosi (bitta oynada), `owner_to_master` yuboriladi.

**✅ FAZA 2 TO'LIQ TUGADI (backend + Flutter):** egasi usta qo'shadi (login
yaratiladi) → usta `/mechanic` kabinetiga kiradi va bronlarini ko'radi → mijoz
servis sahifasida ustalarni ko'rib, aniq ustaga yoziladi → xizmatdan keyin servis
va ustani alohida baholaydi. Reyting ikki darajali. `flutter analyze`: 0 error.

---

## FAZA 3 — SOS moduli

Mavjud WebSocket Gateway ustiga quriladi, yangi kanal kerak emas.

### 3.1 Sxema

- [x] **PostGIS yoqildi.** Prod `docker-compose.yml`: `postgres:16-alpine` →
      `postgis/postgis:16-3.4` (`DEPLOY.md`da prod uchun bir martalik
      `CREATE EXTENSION` qadami yozildi). Lokal dev: tizim Postgres'iga
      tegilmadi — alohida `Backend/docker-compose.dev.yml` (postgis, port
      5433), mavjud `moshn` bazasi shu yerga ko'chirildi (`pg_dump`/`pg_restore`,
      6 servis + 8 booking saqlanib qoldi). `.env` shu portga yo'naltirildi.
- [x] `ShopProfile.location` → `geography(Point,4326)` + **GiST index**,
      mavjud 6 servisning `latitude/longitude`si backfill qilindi.
- [x] `SosRequest`: `id, customerId, vehicleId, serviceTypeId, location
      (geography Point 4326, GiST index), status, acceptedMasterId,
      expiresAt, createdAt, updatedAt`.
- [x] `SosDispatch`: `id, sosRequestId, shopId, wave, distanceMeters, status,
      sentAt, respondedAt` — **shopId** ga yuboriladi (usta emas): geo-qidiruv
      `ShopProfile.location` darajasida, servisdagi istalgan faol usta qabul
      qila oladi (`SosRequest.acceptedMasterId` orqali kim qabul qilgani
      qayd etiladi). Sabab: `Master`ning o'z joylashuvi yo'q, u shop'dan meros.
- [x] ⚠️ Eski Go/GORM `SosRequest` (Shina24, commit `333ad7a^`) tekshirildi —
      juda sodda edi (`UserID, Phone, Lat/Lng, Address, Status,
      AssignedMechanic`, admin qo'lda tayinlagan, to'lqin/geo-index yo'q).
      Qayta ishlatib bo'lmadi, nol nuqtadan yozildi.
- Migratsiya: `20260808101424_faza3_sos_sxema` (qo'llandi, `nest build` +
      boot ✓). `EXCLUDE USING gist` bandlik cheklovi hali Faza 2.1'dagi kabi
      keyinga qoldirilgan (Booking'da `endAt` yo'q).

### 3.2 Geo-qidiruv

- [x] `SosModule`/`SosService.findNearbyShops(lat, lng, radiusMeters,
      serviceTypeId)` — `ST_DWithin` bilan radius qidiruvi, `$queryRaw` orqali.
      `EXPLAIN ANALYZE` bilan tekshirildi: `Index Scan using
      shop_profiles_location_gist_idx` (seq scan emas).
- [x] Filtr: xizmat turi (`master_service_types` orqali `EXISTS`) + faol usta
      bor-yo'qligi (`masters.is_active`) + servis ochiqligi (`working_hours`
      "HH:MM-HH:MM" formatini parslovchi `isShopOpenNow()`, tungi smenani
      ham qo'llab-quvvatlaydi; format tanilmasa "ochiq" deb hisoblanadi —
      noto'g'ri ma'lumot servisni yashirmasin). `verification_status IN
      ('verified','pending')` — `ShopsService.findMany` bilan bir xil
      "ommaviy ko'rinadigan servis" qoidasi.
- [x] `ORDER BY masofa formulasi` **ishlatilmadi** (`CLAUDE.md` §8.1) — SQL
      faqat `ST_DWithin` bilan filtrlaydi, masofa bo'yicha saralash ilova
      kodida (natija radius bilan cheklangani uchun kichik va xavfsiz).
      Qo'lda tekshirildi: 6 test holati (radius ichida/tashqarida, mos
      xizmat turi bor/yo'q, uzoq nuqta) kutilganidek natija berdi.

### 3.3 Tarqatish

- [x] `SosService.createSosRequest()` — mijoz SOS ochadi (`Vehicle` egaligi va
      `ServiceType` tekshiriladi), so'rov `$executeRaw` bilan yoziladi
      (`location` Unsupported turi uchun), darhol 1-to'lqin ishga tushadi.
- [x] To'lqinlar: 3km → 7km → 15km, har biriga ~30s (`WAVES` konstantasi).
      Oxirgi to'lqindan yana ~30s (jami 90s) javob bo'lmasa —
      `status='no_master_found'`, ochiq `sos_dispatches` `expired`ga o'tadi.
- [x] Har bir to'lqin `SosDispatch`ga yoziladi (`shopId, wave,
      distanceMeters`); keyingi to'lqinlar avval xabar berilgan servislarni
      qayta chaqirmaydi (`excludeShopIds`).
- [x] **Taymerlar server tomonda, DB holatidan hisoblanadi — in-memory
      `setTimeout` emas.** `@Interval(10s)` tsikli barcha faol
      (`pending`/`dispatching`) so'rovlarni qayta ko'radi, qaysi to'lqinda
      turishini `now() - createdAt` dan hisoblaydi. Server qayta ishga
      tushsa — keyingi tsiklda holat bazadan xuddi shu joydan tiklanadi.
- [x] Dispatch bo'lganda servis egasi + shu servisning faol ustalariga
      `WsHub.broadcastToUser` (`sos_dispatch` event) + FCM push
      (`NotificationsService`, mavjud `bookings` moduli bilan bir xil andoza).
- [x] Qo'lda tekshirildi (haqiqiy DB, `created_at` orqaga suriladi — real
      vaqt kutilmadi): (A) 1km — darhol wave 1, (B) 5km — wave 1'da topilmadi,
      35s'dan keyin wave 2'da topildi, (C) Toshkentdan (uzoq) — 95s'dan keyin
      `no_master_found`. `nest build` + boot ✓.
- HTTP endpoint hali yo'q (mijoz uchun `POST /v1/sos` — Faza 3.6/3.4 bilan
      birga qo'shiladi, chunki qabul qilish oqimisiz yakka o'zi foydasiz).

### 3.4 Qabul qilish

- [x] `SosService.acceptSosRequest()` — atomik `UPDATE sos_requests SET
      status='accepted', accepted_master_id=... WHERE status IN
      ('pending','dispatching')` (`CLAUDE.md` §8.2). Usta faqat o'ziga
      (`shopId`ga) haqiqatan yuborilgan so'rovni qabul qila oladi
      (`SosDispatch` orqali tekshiriladi).
- [x] `affectedRows = 0` → `409 Conflict` "Kech qoldingiz — bu so'rovni
      boshqa usta oldi yoki u tugagan".
- [x] Qabul qilingandan keyin qolgan servislarning `SosDispatch`lari
      `taken`ga o'tadi + `WsHub.broadcastToUser` orqali `sos_taken` signali
      (§3.5'ning bir qismi, shu yerda tabiiy joylashgani uchun birga qilindi).
- [x] **HTTP endpointlar qo'shildi** (3.3'da va'da qilinganidek, chunki
      dispatch qabulsiz sinalmaydi): `POST /v1/sos` [owner] — SOS ochish;
      `GET /v1/sos/:id` — holat (kutish ekrani uchun poll); `GET
      /v1/master/sos-requests` [master] — menga yuborilgan javobsiz
      so'rovlar; `POST /v1/master/sos-requests/:id/accept` [master].
- [x] **Haqiqiy HTTP orqali (curl, real JWT) uchtadan-uchta oqim
      tekshirildi:** (1) mijoz ochadi → usta ro'yxatda ko'radi → qabul
      qiladi → mijoz `accepted` holatini ko'radi; (2) qayta accept urinishi
      → `409`; (3) **haqiqiy parallel** (`&` bilan bir vaqtda ikkita
      so'rov) ikki usta bir xil so'rovni qabul qilishga urindi — faqat
      bittasi `201`, ikkinchisi `409` oldi, yakuniy holatda bitta
      `acceptedMasterId`. Test uchun yaratilgan vaqtinchalik `master` rolli
      hisoblar va SOS yozuvlari testdan keyin butunlay tozalandi (baza
      dastlabki holatga qaytdi: 13 user, 6 master, 0 sos_request).
- ⚠️ Ma'lum cheklov (yangi emas, Faza 2.2'dan meros): backfill qilingan
      "standart usta" hisoblari servis egasining o'z akkaunti bo'lib,
      `role='service'` (`role='master'` emas) — shuning uchun
      `MasterRoleGuard` talab qiladigan `/v1/master/...` endpointlariga
      kira olmaydi (xuddi shu cheklov `GET /v1/master/bookings`da ham bor,
      Faza 2.3). Amalda muammo emas: servis o'z egasi sifatida emas, alohida
      `master` login yaratib ishlaydi (Faza 2.4 UI shuni qo'llab-quvvatlaydi).

### 3.5 Kuzatuv va yakun

**2026-08-08 qaror:** 3.5 haqiqatda 3 ta deyarli mustaqil qism edi — status
kuzatuvi+chat, evakuator (o'z dispatch-tizimi), to'lov (QR/NFC). Repo egasi
birinchi qismdan boshlashni tanladi; evakuator va to'lov **keyingi alohida
bosqichlarga** qoldirildi (pastga qarang).

- [x] **Status kuzatuvi.** `SosService.updateProgress()` — qabul qilgan
      usta holatni faqat tartib bilan suradi: `accepted → on_the_way →
      arrived → completed` (oralab o'tishga urinish `400`). Har bir
      o'tishda mijozga WS (`sos_status`) + FCM push.
- [x] **Chat** — mavjud WebSocket Gateway ustiga (`WsHub`, yangi kanal
      yo'q), tarix uchun yangi `SosMessage` modeli (migratsiya
      `20260808104446_faza3_5_sos_chat`). Faqat mijoz ↔ **qabul qilgan**
      usta yoza oladi; qabul qilinmagunicha chat yopiq (`400`).
- [x] **Bekor qilish** — `cancelSosRequest()`: mijoz istalgan bosqichda
      (yakunlanmagan bo'lsa) bekor qila oladi; hali javob kelmagan
      dispatchlar `expired`ga o'tadi, tegishli tomon(lar)ga WS signali.
- [x] **"Men mashinamga nima bo'lganini bilmayman" tugmasi**
      (2026-08-08 jamoa qarori) — `POST /v1/sos/:id/support`: ichki
      texqo'llab-quvvatlash (barcha `role='admin'` userlarga WS
      `broadcastToAdmins` + FCM push), tashqi raqam emas.
- [x] Yangi endpointlar: `POST /v1/sos/:id/status` [master], `POST
      /v1/sos/:id/cancel` [owner], `POST /v1/sos/:id/support` [owner],
      `POST` va `GET /v1/sos/:id/messages`.
- [x] **Haqiqiy HTTP orqali tekshirildi:** to'liq hayot davri (ochish →
      qabul → chat ikki tomonlama → status ketma-ketligi → yakunlanish),
      oralab o'tishga urinish rad etildi, tugagandan keyin bekor qilishga
      urinish rad etildi, boshqa mijozning support so'rovi `403`, hali
      qabul qilinmagan so'rovga chat yozish `400`, bekor qilingan so'rovda
      dispatch `expired`ga o'tgani tasdiqlandi. **Muhim:** test paytida
      "Расторопша" egasining haqiqiy `notifications` yozuvlariga tasodifan
      7 ta test push (`sos_dispatch`) qo'shilib qolgani sezildi va butun
      bazani asl `pg_dump` zaxirasi bilan jadval-jadval solishtirib
      tuzatildi (baza to'liq asl holatga qaytarildi).

**Keyingi alohida bosqichlar (3.5'dan chiqarildi):**
- [x] **Evakuator** — bajarildi, §3.7'ga qarang.
- [x] **To'lov (QR/NFC)** — MVP darajasida bajarildi, §3.8'ga qarang.

### 3.6 Flutter

- [x] **Backend to'ldirishlar:** `SosService.getStatus()`ga `serviceType`,
      `customer`, `vehicle`, `acceptedMaster.shop` qo'shildi (mijoz/usta
      ekranlariga kerakli ma'lumot uchun) + `GET
      /v1/master/sos-requests/active` — usta ilovani qayta ochsa, joriy
      qabul qilingan ishini topib olishi uchun.
- [x] SOS tugmasi (mijoz bosh ekrani, qo'ng'iroq belgisi yonida, qizil
      doira) → `sos_request_screen.dart` (xizmat turi + avtomobil tanlash,
      `LocationService` — mavjud `map_screen.dart`dagi joylashuv-so'rash
      bloki qayta ishlatildi) → `sos_tracking_screen.dart` (kutish holati:
      to'lqin/nechta servisga yuborilgani, qabul qilingach usta/servis
      kartochkasi + qo'ng'iroq tugmasi + status-bosqichlar, `no_master_found`
      holati, bekor qilish).
- [x] Usta tomonida: `mechanic_root.dart`ga 3-tab ("SOS") qo'shildi.
      `mechanic_sos_screen.dart` — joriy ish kartochkasi (bo'lsa) + javobsiz
      so'rovlar ro'yxati, qabul qilish tugmasi. `mechanic_sos_detail_screen.dart`
      — mijoz/mashina ma'lumoti, ketma-ket status tugmalari
      (yo'ldaman/yetib keldim/yakunlash), chat.
- [x] "Men mashinamga nima bo'lganini bilmayman" tugmasi — kutish ekranida,
      `requestUnknownIssueSupport` chaqiradi.
- [x] Chat — `SosChat` umumiy vidjeti (mijoz va usta ekranlarida qayta
      ishlatiladi), mavjud `WsHub`/`WsService` ustiga.
- [x] `SosNotifier` (Riverpod) — yaratish/kuzatish/bekor qilish, WS hodisasi
      + 6s zaxira poll, `AuthNotifier` andozasi bilan bir xil.
- [x] Lokalizatsiya: `assets/translations/{ru,uz}.json`ga `"sos"` bo'limi
      (40 kalit) qo'shildi.
- [x] To'lov ekrani (QR/NFC) — bajarildi, §3.8'ga qarang.
- [x] Evakuator UI — bajarildi, §3.7'ga qarang.

**Tekshirildi:**
- `flutter analyze`: loyihada oldindan bor 5 ta `info` darajasidagi
  (mening o'zgarishlarimga aloqasi yo'q) dan boshqa **0 xato/ogohlantirish**.
- `flutter build web --release`: muvaffaqiyatli.
- Backend: barcha yangi endpointlar haqiqiy HTTP orqali (3.3–3.5 sessiyalarida)
  to'liq sinaldi — shu jumladan haqiqiy parallel race condition.
- ⚠️ **Flutter UI'ni brauzerda jonli sinab bo'lmadi.** Sabab — ilovaning
  o'zi (SOS'ga aloqasiz, butun ilova darajasida): shu muhitning ichki
  Electron-brauzerida Flutter Web CanvasKit renderer yuklanadi va
  `window.flutterCanvasKit` obyekti hosil bo'ladi, lekin birinchi kadr hech
  qachon chizilmaydi (`<flt-scene>` doim bo'sh, hech qanday `<canvas>` paydo
  bo'lmaydi, konsolda xato yo'q) — hatto boshlang'ich onboarding ekrani ham.
  Bu SOS kodiga bog'liq emas — loyiha ilgari hech qachon web nishonida
  ishga tushirilmagan va sinalmagan ko'rinadi. Android/iOS/haqiqiy Chrome'da
  tekshirish tavsiya etiladi.

**Tayyor deb hisoblanadi (qisman — yuqoriga qarang):** backend hayot davri
to'liq HTTP orqali tasdiqlangan; Flutter UI kodi mavjud kodbaza
konventsiyalariga mos yozilgan va statik tekshiruvlardan (`analyze`, `build`)
o'tgan, lekin interaktiv (real qurilma/brauzer) UI sinovi muhit sababli
bajarilmadi.

### 3.7 Evakuator (2026-08-09)

Mavjud SOS dispatch/qabul/kuzatuv/chat mexanizmi qayta ishlatildi —
alohida "evakuator tizimi" yozilmadi, `dispatchMode` diskriminatori orqali
bitta SosRequest/SosDispatch dvigateli ikkala rejimga (`shop`/`evacuator`)
xizmat qiladi.

- [x] **Sxema:** yangi `Evacuator` modeli (`fullName, phone, vehiclePlate,
      isActive, isAvailable, location geography+GiST`). `SosRequest`ga
      `dispatchMode, acceptedEvacuatorId, evacuatorRequestedAt`; `SosDispatch`ga
      `evacuatorId` (endi `shopId` ixtiyoriy — dispatch yo servisga, yo
      evakuatorga). Migratsiya `20260809150135_faza3_7_evacuator`.
- [x] **Backend:** `EvacuatorsModule` (profil yaratish/olish, joylashuv va
      onlayn/oflayn holatini yangilash). `SosService`: `findNearbyEvacuators`,
      `requestEvacuator` (faqat `no_master_found`dan keyin, mijoz chaqiradi),
      `acceptAsEvacuator` (atomik, §8.2 bilan bir xil himoya), evakuator
      to'lqinlari (5km/15km/30km, 90s timeout → `no_evacuator_found`).
      Status kuzatuvi/chat/bekor qilish endi usta va evakuator uchun umumiy
      (`getAcceptedActorUserId` orqali generallashtirildi).
- [x] **Haqiqiy HTTP orqali tekshirildi:** to'liq hayot davri (usta
      topilmadi → evakuator chaqirildi → tarqatildi → qabul qilindi → chat →
      status ketma-ketligi → yakunlash) + **haqiqiy parallel** ikki
      evakuatorning bir so'rovni olishga urinishi (bittasi `201`, ikkinchisi
      `409`). Test ma'lumotlari to'liq tozalandi.
- [x] **Flutter:** ro'yxatdan o'tishda 3-rol ("Evakuator"), evakuator
      kabineti (`evacuator_root.dart` — 2 tab: SOS + Profil,
      `evacuator_sos_screen.dart` — onlayn/oflayn switch, joriy ish,
      javobsiz so'rovlar). Mijoz tomonida: `sos_tracking_screen.dart`da
      `no_master_found` holatida "Evakuator chaqirish" tugmasi
      (`_NoMasterCard`), evakuator qabul qilgach `_EvacuatorCard`
      (mashina raqami, reyting, qo'ng'iroq). Usta va evakuator uchun bitta
      `MechanicSosDetailScreen` qayta ishlatildi (to'liq aktyor-agnostik
      ekan). `flutter analyze`: 0 yangi xato.

### 3.8 To'lov — MVP (2026-08-09)

Jamoa qarori (§"HAL QILINGAN SAVOLLAR"): xizmat `completed` bo'lgach qabul
qilgan tomon (usta/evakuator) narxni kiritadi, mijoz shu summani QR/NFC
orqali — ilova tashqarisida, to'g'ridan-to'g'ri usta hisobiga ("Pay to
phone" andozasi) — to'laydi. **Haqiqiy to'lov provayderi (Payme/Click/
Uzcard/bank NFC SDK) hali tanlanmagan va ulanmagan** — repo egasi ataylab
MVP qamrovini tanladi (real pul harakati bo'lmagan holda): narx kiritish +
mock QR-satr + mijozning o'zi "to'ladim" deb tasdiqlashi, xuddi mavjud
Booking to'lov ekrani (`PaymentScreen`/`PaymentsService`, avvaldan shu
andozada, "MVP mock" deb belgilangan) bilan bir xil.

- [x] **Sxema:** `Payment`/`Tip` modellari `SosRequest`ga ham bog'lanadigan
      qilib kengaytirildi (`bookingId`/`sosRequestId` — ikkalasi ham
      ixtiyoriy, DB **CHECK cheklovi** aynan bittasi to'lishini ta'minlaydi —
      CLAUDE.md ruhidagi butunlik qoidasi). Migratsiya
      `20260809184045_faza3_8_sos_payment`.
      ⚠️ Migratsiya yaratish jarayonida Prisma interaktiv so'rovi (`Enter a
      name for the new migration`) kutilmagan holda GiST indekslarni qayta
      DROP qildirib yuborgan edi (§DEPLOY.md'dagi ma'lum muammoning yangi
      ko'rinishi) — darhol aniqlanib, indekslar tiklandi va xato migratsiya
      yozuvi butunlay tozalandi (`migrate status`: toza).
- [x] **Backend:** `SosService.setPrice` (faqat qabul qilgan tomon, faqat
      `completed` holatda, faqat bir marta), `confirmPayment` (mijoz,
      qayta chaqirilsa idempotent), `addTip`. `getStatus()`ga `payment`
      qo'shildi. Yangi endpointlar: `POST sos/:id/price`,
      `POST sos/:id/payment/confirm`, `POST sos/:id/tip`.
- [x] **Haqiqiy HTTP orqali to'liq tekshirildi** (yangi test usta/mijoz/
      servis bilan, real registratsiya → SOS → qabul → yakunlash oqimi):
      narx kiritish ✓, qayta kiritish rad etildi (400) ✓, mijoz
      `getStatus`da narxni ko'radi ✓, begona aktyor (mijoz) narx kirita
      olmaydi (403) ✓, mijoz to'lovni tasdiqlaydi ✓, qayta tasdiqlash
      idempotent ✓, chayevoy qo'shiladi ✓, boshqa mijoz na chayevoy na
      tasdiqlay olmaydi (403, egalik tekshiruvi) ✓, `completed`gacha narx
      kiritishga urinish rad etiladi (400) ✓. Test ma'lumotlari to'liq
      tozalandi, baza asl holatga qaytarildi.
- [x] **Flutter:** `SosPayment` modeli, `SosService`ga
      `setPrice/confirmPayment/addTip`. Usta/evakuator tomonida
      (`mechanic_sos_detail_screen.dart`, ikkalasiga umumiy): `completed`
      holatida narx-kiritish formasi, keyin narx/holat kartochkasi. Mijoz
      tomonida (`sos_tracking_screen.dart`): `_PaymentCard` — narx, "To'ladim"
      tugmasi, ixtiyoriy chayevoy (10k/20k/50k). Yangi
      `SosRequest.needsLiveUpdates` getter — `completed` bo'lgandan keyin ham
      to'lov kutilayotgan bo'lsa WS/poll kuzatuvi davom etadi (usta narx
      kiritganda mijoz darhol bilishi uchun), to'langach to'xtaydi.
      "Tayyor" tugmasi to'lov kutilayotganda ko'rsatilmaydi (mijoz to'lamay
      chiqib ketmasin). `flutter analyze`: 0 yangi xato (avvalgi 5 ta
      `info` bundan mustasno).

---

## FAZA 4 — Rebrend va tozalash

- [x] **Yangi logolar** (`logos/1(2).png` oq wordmark, `2(2).png` qora
      wordmark, `3.png`/`4.png` oq/qora "P" gayka-kalit belgisi) — barcha
      qo'llanish nuqtalariga tarqatildi: Flutter Android/iOS/web ilova
      belgilari (qorong'i fon `#09090A` + oq belgi, eski shina24-icon
      andozasi bilan bir xil), welcome ekran logotipi, Admin `Brand.tsx`
      (ikkala tema varianti), Landing navbar/footer, Admin/Landing
      `icon.png`/`favicon.ico`. Orfan/ishlatilmagan eski fayllar
      (`logo-cream.png` va h.k.) tegilmadi.
- [x] **Kod bo'ylab `shina24`/`Shina24`/`moshn`/`Moshn` nomlari `pitgo`/`PitGo`
      ga o'zgartirildi** — 2026-08-09:
  - Flutter: `pubspec.yaml`, `MoshnApp→PitGoApp`, `MoshnIcon→PitGoIcon`
    (fayl ham qayta nomlandi), notification channel, barcha ekran matnlari,
    tarjimalar (`ru.json`/`uz.json`).
  - **Android `applicationId`**: `uz.moshn.moshn` → `uz.pitgo.pitgo`
    (foydalanuvchi tasdiqlagandan keyin). Kotlin manba papkasi
    `android/app/src/main/kotlin/uz/pitgo/pitgo/` ga ko'chirildi.
    ⚠️ **Qoldi:** `google-services.json` hali eski paket nomiga
    (`uz.moshn.moshn`, Firebase loyihasi `shina24-78f98`) bog'langan —
    Firebase Console'da yangi paket nomi qo'shilib, fayl yangilanmaguncha
    **Android build ishlamaydi** (`google-services` plagini xato beradi).
  - **iOS bundle id**: `uz.moshn.moshn` → `uz.pitgo.pitgo` (6 ta joyda,
    `project.pbxproj`). iOS'da Firebase konfiguratsiyasi umuman yo'q edi —
    bog'liqlik yo'q.
  - Backend: `package.json`, Swagger sarlavhasi, email/SMS matni, deep-link
    QR satri (`pitgo://pay/...` — bu haqiqiy ro'yxatdan o'tgan OS-darajali
    scheme emas, faqat QR-kodda ko'rsatiladigan satr edi), FCM channel id.
  - **DB nomi/foydalanuvchisi**: `moshn` → `pitgo` (foydalanuvchi
    tasdiqlagandan keyin). Lokal dev bazasi `ALTER ROLE`/`ALTER DATABASE`
    bilan ma'lumot yo'qotmasdan qayta nomlandi (13 user, 6 servis — barchasi
    saqlanib qoldi); `docker-compose.yml`/`.env.example` standart qiymatlari
    ham yangilandi. **Haqiqiy production bazasi bu bilan avtomatik
    o'zgarmaydi** — agar deploy qilingan bo'lsa, alohida qo'lda ko'chirish
    kerak.
  - Admin + Landing: `package.json`, sahifa sarlavhalari, ko'rinadigan
    matnlar (navbar/footer/"SHINA24 PARTNER" yorliqlari va h.k.).
  - **Ataylab tegilmadi** (jonli tashqi manzillar/hujjatlar): `shina24.uz`
    APK yuklab olish havolasi, `support@shina24.uz` email, `shina24.vercel.app`
    (`ALLOWED_ORIGINS`), ngrok tunnel URL, `google-services.json`,
    `CLAUDE.md`/`PITGO_PLAN.md`dagi tarixiy "Shina24 (eski)" izohlari.
  - Tekshirildi: `nest build` ✓, backend `pitgo` bazasiga ulanib boot bo'ldi ✓,
    `flutter analyze` — 0 yangi xato ✓, Admin/Landing brauzerda jonli
    tekshirildi (sarlavha, matnlar to'g'ri "PitGo" ko'rsatmoqda) ✓.
- [ ] ⚠️ **Qoldi — sizning tomoningizda:** Firebase Console'da `uz.pitgo.pitgo`
      paketini qo'shib, yangi `google-services.json`ni yuklab, faylni
      almashtirish (aks holda Android build ishlamaydi).
- [ ] ⚠️ **Qoldi:** haqiqiy deploy qilingan production muhitlar bo'lsa —
      u yerdagi Postgres bazasini/foydalanuvchisini qo'lda ko'chirish,
      va agar kerak bo'lsa `pitgo.uz` domenini sozlab, APK/support
      manzillarini ko'chirish.
- [ ] Meros modellar taqdirini hal qilish: `SeasonalRule`, `CustomerCard`
      — PitGo'ga kerakmi, yoki olib tashlanadimi?
- [ ] ℹ️ Ochiq topilma (rebrend doirasidan tashqari): repo ildizidagi
      `README.md` hali "Moshn" davridagi butunlay boshqa mahsulot
      konsepsiyasini tavsiflaydi (Go/Gin backend, VIN-markazli tarix,
      `Mechanic`/`ServiceRecord`/`WarrantyClaim` kabi hozir mavjud bo'lmagan
      modellar) — nomlar PitGo'ga almashtirildi, lekin mazmuni hali eskicha
      va CLAUDE.md bilan mos emas. Qayta yozish alohida vazifa.

---

## XIZMAT TURLARI — dinamik katalog + narx diapazoni (2026-08-09)

Reja tashqarisidagi, foydalanuvchi savoli asosida chiqqan tuzatish: "biz endi
faqat shina emas, mashinaga oid barcha ustalar bilan ishlaymiz" — demak
xizmat turlari katalogi endi shinaga cheklanmasligi, va admin yangi
kategoriya qo'shsa, u ilovada **kod o'zgartirmasdan** to'g'ri icon bilan
ko'rinishi kerak edi.

- [x] **Aniqlandi:** admin panelda xizmat turlari CRUD + 20 ta icon-tanlagich
      allaqachon bor edi, lekin Flutter ilovasi (`home_screen.dart`,
      `sos_request_screen.dart`) `ServiceType.icon` maydonini butunlay
      e'tiborsiz qoldirib, faqat 6 ta eski slug uchun qattiq yozilgan
      jadvaldan foydalanardi — yangi turlar doim bitta umumiy "gayka kalit"
      belgisi bilan chiqardi.
- [x] Flutter `PitGoIcon` kutubxonasi admin'ning 20 ta icon nomi bilan **bir
      xil kalitlarga** kengaytirildi (`m_pitgo_icon.dart`); admin'ga ham
      Flutter'da avvaldan chiroyli chizilgan 4 ta shina-maxsus icon
      qo'shildi (`diskWrench`, `tireSwap`, `tireStack`, `flame`) — ikki
      tomon endi bir xil lug'atdan foydalanadi.
- [x] `home_screen.dart`, `sos_request_screen.dart`,
      `service_category_screen.dart`, `create_booking_screen.dart`,
      `profile_setup_screen.dart` — qattiq yozilgan slug→icon jadvallari va
      eski emoji-xarita olib tashlandi, hammasi `serviceType.icon`dan
      to'g'ridan-to'g'ri o'qiydi. Noma'lum icon nomi kelsa `PitGoIcon`
      ichida "wrench"ga qaytadi (bo'sh joy chiqmaydi).
- [x] Mavjud 6 ta xizmatning DB'dagi eskirgan `icon` qiymatlari
      (`tire_inflate`, `tire_change`...) yangi lug'atga moslab yangilandi.
- [x] `ServiceType.basePrice` (bitta raqam) → **`priceMin`/`priceMax`**
      (diapazon) — migratsiya `20260809133719_service_type_price_range`,
      mavjud qiymatlar yo'qotilmadi (min=max=eski qiymat qilib backfill).
      Admin formasida ikkita input, mijoz tomonida `service_category_screen`
      sarlavhasida "20 000 – 80 000 сум" ko'rinishida chiqadi.
- [x] **Yon-effekt sifatida topilgan va tuzatilgan 2 ta eski xato**
      (`Backend/admin/src/app/service-types/page.tsx`): (1) interfeys
      `snake_case` (`name_uz`, `is_active`) kutar edi, backend esa
      `camelCase` qaytaradi — shuning uchun bu sahifada xizmat nomlari va
      faollik holati **hech qachon to'g'ri ko'rsatilmagan**; (2) admin
      ro'yxati serverda `isActive: true` bilan filtrlanardi — nofaol
      qilingan turni admin qayta yoqib bo'lmasdi. Ikkalasi ham tuzatildi.
- [x] **Haqiqiy admin UI orqali (brauzerda, login qilib) uchdan-uchga
      tekshirildi:** yangi "Elektrika ta'mirlash" turi `zap` iconi va
      40 000–150 000 so'm diapazon bilan qo'shildi, ro'yxatda va ommaviy
      `/v1/service-types`da to'g'ri chiqdi, keyin test yozuvi o'chirildi.
      `nest build` ✓, `flutter analyze` — 0 yangi xato ✓.
- [x] **Ro'yxatdan o'tishga 5-qadam qo'shildi: "Ustalarni qo'shish"**
      (`profile_setup_screen.dart`). Servis egasi ism→nomi→manzil→xizmat
      turlari qadamlaridan keyin, endi ixtiyoriy "Ustalar" qadamiga
      tushadi — shu yerdan chiqmasdan bir nechta usta qo'sha oladi yoki
      "Пропустить/Готово" bosib keyinroqqa qoldirsa bo'ladi.
      `masters_screen.dart`dagi forma (`_MasterFormSheet`) va provider
      (`_myMastersProvider`) **public** qilindi (`MasterFormSheet`,
      `myMastersProvider`) va shu yangi qadamda qayta ishlatildi —
      dublikat kod yozilmadi.
      ⚠️ **Router tuzatildi:** avval rol `'service'`ga o'zgarishi bilan
      `/profile-setup`dan **majburan** `/service`ga otilib ketilardi
      (5-qadamni ko'rsatishga ulgurmasdan) — `router.dart`da endi
      `role=='service' && loc=='/profile-setup'` alohida istisno
      qilingan, ekranning o'zi tugagach `context.go('/service')` chaqiradi.
      `flutter analyze` — 0 yangi xato ✓ (brauzerda Flutter Web CanvasKit
      muammosi tufayli jonli sinalmadi, oldingi sessiyalarda qayd etilgan).
- [x] **Haqiqiy qidiruv qo'shildi — "servisni ham, ustani ham qidirish"**
      (`CLAUDE.md` §4'da rejalashtirilgan, hali qurilmagan edi). Avval bosh
      ekrandagi qidiruv paneli shunchaki xarita ekraniga o'tkazuvchi tugma
      edi — endi haqiqiy matnli qidiruv:
      - Backend: `GET /v1/search?q=...` (`ShopsService.search`) — servis
        nomi va usta ismi bo'yicha (case-insensitive) parallel qidiradi,
        har biri 10 tagacha, faqat faol/ko'rinadigan yozuvlar orasidan.
        Curl bilan tekshirildi ("Tony" → "Tony Stark" ustasi + uning
        servisi topildi).
      - Flutter: yangi `search_screen.dart` (`/owner/search`) — 350ms
        debounce, "Ustalar"/"Servislar" bo'limlari alohida, usta natijasi
        bosilsa uning servisiga o'tadi (alohida usta-profil ekrani hali
        yo'q — bu ataylab qisqartirilgan qamrov, servis sahifasida
        "Мастера" bo'limida u allaqachon ko'rinadi).
      - `Master` modeliga ixtiyoriy `shopName` maydoni qo'shildi (faqat
        qidiruv javobidagi nested `shop` obyektidan to'ladi).
      `nest build` ✓, `flutter analyze` — 0 yangi xato ✓.

---

## HAL QILINGAN SAVOLLAR (jamoa bilan 2026-08-08 muhokamasi)

1. **Daromad modeli** — komissiya (oylik obuna emas).
2. **To'lov oqimi** — xizmat tugagach: usta ilovada narxni kiritadi →
   mijoz shu summani **QR yoki NFC** orqali to'laydi, hammasi ilova ichida
   (referens: "Pay to phone" — Android, ИП/ООО, Т-Business hisobi orqali
   telefonni to'lov terminaliga aylantiradi).
3. **Naqd pul + komissiya** — hali **hal qilinmagan**: naqd to'lovda
   komissiyani qanday ushlab qolish noaniq. Qaror: **dastlab komissiyasiz
   (bepul) ishga tushiriladi**, ilova jarayon davomida takomillashtiriladi.
4. **Evakuator** — **ichki** (platforma ichida), tashqi raqam emas.
   Taksi-uslubidagi so'rov: evakuatorlar platformada ro'yxatdan o'tadi,
   so'rov kelganda kim birinchi qabul qilsa — o'sha boradi.
5. **Qo'shimcha talab (yangi):** SOS oqimiga "Men mashinamga nima
   bo'lganini bilmayman" tugmasi qo'shilsin — bosilganda texqo'llab-
   quvvatlashga (ichki) qo'ng'iroq qiladi.
6. **SOS narxi** — aniq formula hali yo'q, komissiya modeliga bog'liq
   holda keyinroq hal qilinadi.

## OCHIQ QOLGAN SAVOLLAR

1. `SeasonalRule` va `CustomerCard` PitGo'da qoladimi?
2. Naqd to'lovda komissiya qanday ushlanadi (yuqoridagi 3-bandga qarang) —
   MVP'dan keyin qaytib ko'riladi.
