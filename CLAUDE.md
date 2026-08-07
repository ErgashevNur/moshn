# PitGo — loyiha konteksti

> Bu fayl loyihaning maqsadi, biznes mantig'i va texnik holatini tavsiflaydi.
> Ish boshlashdan oldin shu faylni va `PITGO_PLAN.md` ni o'qing.
>
> **Diqqat:** bu fayl avvalgi `CLAUDE.md` o'rniga keladi. Eski fayl noto'g'ri
> ma'lumot berardi (backend "Go + Gin + GORM" deb yozilgan edi — aslida
> NestJS + Prisma). Eski hujjatga ishonmang.

---

## 1. Mahsulot nima?

**PitGo** — avtomobil servis ustalarini bir joyga yig'adigan platforma (marketplace).

Mijoz ilova orqali kerakli xizmatni topadi, ustaga yoziladi va belgilangan vaqtda
boradi. Yo'lda muammo yuz bersa — SOS orqali eng yaqin ustani chaqiradi.

**Bozor:** O'zbekiston.

### Rebrend

PitGo — avvalgi **Shina24** loyihasining rebrendi.

| | Shina24 (eski) | PitGo (yangi) |
|---|---|---|
| Qamrov | faqat shinomontaj | barcha avtoservis xizmatlari |
| Birlik | servis (ustaxona) | servis **+ ichidagi ustalar** |
| SOS | yo'q | yadro funksiya |

Kod bazasi Shina24 dan meros. Nomlar, logolar va ba'zi modellar hali eskicha.

---

## 2. Texnik holat (repo faktlari)

### Struktura (monorepo)

```
Backend/
  nest-backend/     ← asosiy backend: NestJS 10 + Prisma 5
    prisma/schema.prisma
  admin/            ← admin panel (Next.js)
  nginx/
  media/  uploads/
  docker-compose.yml
  DEPLOY.md
Flutter/            ← mobil ilova (mijoz + servis)
Landing/            ← marketing sayt (Next.js + Tailwind)
logos/
```

| Qism | Stack |
|---|---|
| Backend | **NestJS 10 + Prisma 5 + PostgreSQL** |
| Mobil | Flutter |
| Admin | Next.js |
| Landing | Next.js + Tailwind |
| Deploy | Docker Compose + Nginx |

Repoda **Go kodi yo'q** — `go.mod` ham, `.go` fayl ham topilmadi.

### Prisma modellari (hozirgi holat)

```
User, ShopProfile, Vehicle, ServiceType, Promo, AppConfig,
ShopServicePrice, Booking, Payment, Tip, CustomerCard,
Review, SeasonalRule, Notification, FCMToken
```

**Muhim:** `Master` (Usta) modeli **yo'q**. Hozir tizim servis darajasida
ishlaydi: `Booking → ShopProfile`. PitGo talab qiladigan "aniq ustaga yozilish"
hali yo'q. Bu 2-fazada qo'shiladi (`PITGO_PLAN.md`).

`SeasonalRule` va `CustomerCard` — Shina24 merosi, taqdiri hal qilinmagan.

### Migratsiyalar

`prisma/migrations/` **bo'sh** — hozirgacha `db push` bilan ishlangan.
Sxemaga jiddiy o'zgarish kiritishdan oldin baseline migratsiya kerak (1-faza).

---

## 3. Foydalanuvchi rollari (maqsadli model)

| Rol | Tavsif |
|---|---|
| **Mijoz** | Mashina egasi. Ro'yxat: ism-familiya, telefon, mashina ma'lumotlari. |
| **Servis** | Ustaxona. Ro'yxat: nomi, manzili, telefoni. O'z ustalarini qo'shadi. |
| **Usta** | Servisga tegishli. **Har bir ustaning alohida login akkaunti bor.** |

### Yakka usta ham "servis"

Garajda yolg'iz ishlaydigan usta ham **servis** sifatida ro'yxatdan o'tadi —
o'zi yagona usta bo'ladi. Keyin ishchi olsa, o'z servisiga usta qo'shadi.

> `ShopProfile` universal birlik bo'lib qoladi. Alohida "yakka usta" entity
> yaratilmasin.

---

## 4. Oqim №1 — rejalashtirilgan xizmat

1. Mijoz xizmat turini tanlaydi (masalan, moy almashtirish)
2. Servis/ustani topadi: yaqinligi / reytingi / tanish usta bo'yicha
3. Servis ichidagi **aniq ustaga** yoziladi
4. Kun va soatni belgilaydi
5. Belgilangan vaqtda boradi

Qidiruvda mijoz servisni ham, aniq ustani ham ko'ra oladi.

**Reyting ikki darajali:** servisning umumiy reytingi + har bir ustaning
shaxsiy reytingi.

---

## 5. Oqim №2 — SOS (hali yozilmagan)

1. Mijoz SOS bosadi
2. **Avval qanday xizmat kerakligini tanlaydi**
3. So'rov shu xizmatni ko'rsatadigan **eng yaqin ustaxonalarga** yuboriladi
4. **Kim birinchi qabul qilsa — o'sha boradi**
5. Chat orqali xabarlashish

**Eng muhim talab:** so'rov joylashuvga eng yaqin ustalarga borishi kerak.

### Hech kim qabul qilmasa

- Ustaxonalarga qabul qilinmaguncha xabar yuborilib turiladi
- **Evakuator chaqirish** imkoni ochiladi
- Mijoz yaqin yoki o'z ustaxonasiga yozilib, mashinani o'sha yerga olib boradi

---

## 6. Narxlar

- Narxni **har bir servis o'zi belgilaydi** (`ShopServicePrice`)
- Narx aniq raqam emas, **diapazon**: `...dan — ...gacha`
- Sabab: mashina rusumi va modeli ko'p, ish hajmi shunga qarab o'zgaradi
- **SOS narxi qanday hisoblanishi hali hal qilinmagan**

---

## 7. To'lov

- To'lov **ilova orqali**
- Keyinroq to'lash imkoni bor *(aniq shakli hal qilinmagan)*
- Mijoz ustaga **chayevoy** qoldirishi mumkin (`Tip` modeli mavjud)
- **Yozilishda oldindan to'lov YO'Q** — mijoz shunchaki yoziladi

**Daromad:** ustalardan olinadi. Komissiya yoki obuna — hal qilinmagan.

---

## 8. Majburiy texnik qoidalar

### 8.1 Geo — PostGIS

- `ST_DWithin` + **GiST index** ishlatilsin
- `ORDER BY <masofa formulasi>` yozilmasin — index ishlamaydi, jadval to'liq skanerlanadi
- Prisma PostGIS ni to'g'ridan-to'g'ri qo'llamaydi:
  maydon `Unsupported("geography(Point, 4326)")` deb e'lon qilinadi,
  qidiruv `$queryRaw` bilan yoziladi

### 8.2 SOS qabul qilish — race condition

WebSocket darajasida hal qilinmasin. DB tranzaksiyasida:

```sql
UPDATE sos_request
   SET status = 'accepted', master_id = $1
 WHERE id = $2 AND status = 'pending';
```

`affectedRows = 0` → "kech qoldingiz". Aks holda ikki usta bir vaqtda oladi.

### 8.3 Bandlik — kesishishni baza taqiqlasin

```sql
ALTER TABLE "Booking"
  ADD CONSTRAINT booking_no_overlap
  EXCLUDE USING gist (
    master_id WITH =,
    tstzrange(start_at, end_at) WITH &&
  );
```

Kod darajasidagi tekshiruv race condition qoldiradi.

### 8.4 Migratsiya

`db push` bilan ishlanmasin. Har bir sxema o'zgarishi migratsiya fayli bo'lsin.

---

## 9. Jamoa va til

2 investor, 2 dasturchi, 1 AI mutaxassisi va boshqaruvchi.
Bu repo egasi — asosiy dasturchi (Flutter + NestJS).

**Muloqot o'zbek tilida.** Kod va o'zgaruvchi nomlari — mavjud kod uslubiga mos.

---

## 10. Ish tartibi

Vazifalar va ularning ketma-ketligi: **`PITGO_PLAN.md`**.
Fazalarni tartibsiz bajarmang — 3-faza (SOS) 2-fazaga bog'liq.
