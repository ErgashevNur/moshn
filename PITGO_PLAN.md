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

- [ ] **Firebase service account kalitini almashtirish**
  - Repo ildizidagi `shina24-*-firebase-adminsdk-*.json` — bu **private key**.
    U bilan Firebase loyihasiga to'liq admin kirish mumkin.
  - Firebase Console → Project settings → Service accounts → eski kalitni
    **o'chirish (revoke)**, yangisini yaratish
  - Yangi kalit repoga qo'yilmaydi — `.env` yoki secret orqali uzatiladi
  - ⚠️ Faylni git'dan o'chirish yetarli emas — tarixda qoladi.
    Shuning uchun kalit **almashtirilishi shart**.
- [ ] `Moshn.zip` ni repodan olib tashlash (kerak bo'lsa alohida saqlash)
- [ ] `.gitignore` ni to'ldirish: `*.json` firebase kalitlari, `.env`,
      `Moshn.zip`, `uploads/`, `media/`
- [ ] `.env.example` ni tekshirish — ichida haqiqiy qiymat qolmaganiga ishonch hosil qilish

**Tayyor deb hisoblanadi:** repoda birorta ham amaldagi kalit/parol yo'q.

---

## FAZA 1 — Baseline migratsiya

Hozir `prisma/migrations/` bo'sh, `db push` bilan ishlangan. Sxemani
o'zgartirishdan oldin bu tuzatilishi kerak, aks holda prodda ma'lumot
yo'qolishi mumkin va orqaga qaytarish yo'q.

- [ ] Hozirgi `schema.prisma` dan baseline migratsiya yaratish
      (`prisma migrate diff` → birinchi migratsiya fayli)
- [ ] Mavjud bazani shu migratsiyaga `resolve --applied` bilan bog'lash
- [ ] PostGIS kengaytmasini qo'shish: `CREATE EXTENSION IF NOT EXISTS postgis;`
      (SOS uchun kerak, hozirdan qo'yib qo'yilsin)
- [ ] `README` yoki `DEPLOY.md` ga migratsiya tartibini yozish
- [ ] Bundan keyin `db push` ishlatilmasin — faqat `migrate dev` / `migrate deploy`

**Tayyor deb hisoblanadi:** toza bazada `migrate deploy` ishlagach, sxema
hozirgi holatga to'liq mos keladi.

---

## FAZA 2 — Usta (Master) modeli

Eng katta ish. Hozir tizim servis darajasida: `Booking → ShopProfile`.
PitGo talab qiladi: mijoz **aniq ustaga** yoziladi.

### 2.1 Sxema

- [ ] `Master` modeli:
      `id, shopProfileId, userId (login akkaunti), fullName, position,
      isActive, ratingAvg, ratingCount, createdAt`
- [ ] `Master.userId → User` — har bir ustaning alohida logini
- [ ] `User` rollariga `MASTER` qo'shish (mavjud rol enum ko'rilsin)
- [ ] `Booking.masterId` (nullable emas — migratsiyada bosqichma-bosqich)
- [ ] `Review.masterId` — reyting ikki darajali bo'ladi:
      servis reytingi + usta reytingi
- [ ] `MasterServiceType` — qaysi usta qaysi xizmatni bajaradi
      (SOS tarqatishida filtr sifatida kerak bo'ladi)
- [ ] `Booking` uchun kesishish cheklovi (`EXCLUDE USING gist`) — `CLAUDE.md` §8.3

### 2.2 Ma'lumot migratsiyasi

- [ ] Har bir mavjud `ShopProfile` uchun bitta **standart usta** yaratish
      (yakka usta stsenariysi bilan mos)
- [ ] Mavjud `Booking` yozuvlarini shu standart ustaga bog'lash
- [ ] Mavjud `Review` larni ham shunday bog'lash
- [ ] Shundan keyingina `masterId` ni majburiy qilish

### 2.3 Backend

- [ ] `masters` moduli: CRUD (servis egasi o'z ustalarini boshqaradi)
- [ ] Huquqlar: usta **faqat o'z** buyurtmalarini ko'radi; servis egasi hammasini
- [ ] Bandlik hisobi servis emas, **usta** bo'yicha
- [ ] Qidiruvda usta bo'yicha filtr va usta kartochkasi endpointi

### 2.4 Flutter

- [ ] Servis sahifasida ustalar ro'yxati
- [ ] Yozilishda usta tanlash qadami
- [ ] Usta uchun login va o'z kabineti (buyurtmalari, jadvali)
- [ ] Sharh qoldirishda ustaga ham baho

**Tayyor deb hisoblanadi:** mijoz servis ichidagi aniq ustaga yozila oladi,
usta o'z akkauntiga kirib buyurtmasini ko'radi, sharh ikki darajada yoziladi.

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
