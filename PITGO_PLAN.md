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
- [ ] Servis sahifasida (shop_detail) ustalar ro'yxatini ko'rsatish
- [ ] Servis egasi kabineti: usta qo'shish/tahrirlash UI
      (`service/masters` endpointlari tayyor)
- [ ] Usta uchun login va o'z kabineti — role routing (`'master'`) + mechanic
      ekranlari (`master/profile`, `master/bookings` tayyor)
- [ ] Sharh qoldirishda ustaga ham baho (`owner_to_master` tayyor)

**Holat:** ✅ mijoz aniq ustaga yozila oladi (kritik oqim ishlaydi). Qolgan UI
qismlari (usta kabineti, egasi boshqaruvi, usta sharhi) — keyingi bosqichlar.
Backend hammasini qo'llab-quvvatlaydi.

---

## FAZA 3 — SOS moduli

Mavjud WebSocket Gateway ustiga quriladi, yangi kanal kerak emas.

### 3.1 Sxema

- [ ] `SosRequest`: `id, customerId, vehicleId, serviceTypeId, location
      (geography Point 4326), status, acceptedMasterId, createdAt, expiresAt`
- [ ] `SosDispatch`: kimga, qaysi to'lqinda yuborilgani va javobi (jurnal)
- [ ] `ShopProfile.location` → `geography(Point,4326)` + **GiST index**
- [ ] ⚠️ Git tarixida eski `SosRequest` modeli bor edi (o'chirilgan) —
      avval uni topib ko'ring, nol nuqtadan boshlash shart bo'lmasligi mumkin

### 3.2 Geo-qidiruv

- [ ] `ST_DWithin` bilan radius qidiruvi, `$queryRaw` orqali
- [ ] Filtr: xizmat turi + servis ochiqligi + faol usta bor-yo'qligi
- [ ] `ORDER BY masofa formulasi` ishlatilmasin (`CLAUDE.md` §8.1)

### 3.3 Tarqatish

- [ ] To'lqinlar: 3 km → 7 km → 15 km, har biriga ~30 soniya taymer
- [ ] Har bir to'lqin `SosDispatch` ga yoziladi
- [ ] Taymerlar server tomonda (qayta ishga tushirilganda tiklanishi kerak)

### 3.4 Qabul qilish

- [ ] Atomik `UPDATE ... WHERE status='pending'` (`CLAUDE.md` §8.2)
- [ ] `affectedRows = 0` → "kech qoldingiz"
- [ ] Qolganlarga WebSocket orqali "olib bo'lindi" signali

### 3.5 Kuzatuv va yakun

- [ ] Chat (mavjud WebSocket ustiga)
- [ ] Usta yo'lda / yetib keldi / yakunlandi statuslari
- [ ] Hech kim qabul qilmasa: xabar yuborishda davom etish +
      **evakuator chaqirish** varianti + yaqin/o'z ustaxonasiga yozilish

### 3.6 Flutter

- [ ] SOS tugmasi → xizmat turi tanlash → joylashuv → kutish ekrani
- [ ] Usta tomonida SOS so'rovi keladigan ekran + qabul qilish tugmasi

**Tayyor deb hisoblanadi:** ikki qurilmada sinalganda so'rov eng yaqin ustaga
boradi, bittasi qabul qiladi, ikkinchisiga "olib bo'lindi" keladi.

---

## FAZA 4 — Rebrend va tozalash

- [ ] Kod bo'ylab `shina24` / `Shina24` nomlarini `pitgo` / `PitGo` ga
      (paket nomlari, bundle id, deep link sxemasi — ehtiyot bilan)
- [ ] `logos/` — yangi logolar
- [ ] Landing sayti matnlari
- [ ] Firebase loyihasi: yangi nom yoki yangi loyiha (0-fazadagi kalit bilan birga)
- [ ] Meros modellar taqdirini hal qilish: `SeasonalRule`, `CustomerCard`
      — PitGo'ga kerakmi, yoki olib tashlanadimi?

---

## OCHIQ SAVOLLAR (kod yozishdan oldin javob kerak)

Bularni o'zingiz hal qilmang — repo egasidan so'rang:

1. **SOS narxi** qanday hisoblanadi? Chaqiruv haqi bormi, masofaga bog'liqmi?
2. **"Keyinroq to'lash"** — ish tugagach to'lashmi yoki bo'lib to'lashmi?
3. **Daromad modeli** — har buyurtmadan komissiya yoki oylik obuna?
   (Komissiya bo'lsa, `Payment` oqimida pul qayerda ushlanadi?)
4. **Evakuator** — platforma ichidagi xizmatmi yoki tashqi telefon raqammi?
5. `SeasonalRule` va `CustomerCard` PitGo'da qoladimi?
