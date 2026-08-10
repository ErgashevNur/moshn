# PitGo — Serverga Docker bilan deploy

Backend (NestJS API), Admin (Next.js), PostgreSQL va Nginx — hammasi Docker Compose orqali.

## 1. Talablar (serverda)
- Docker + Docker Compose (`docker compose version` ishlashi kerak)
- Ochiq portlar: 80, 443
- DNS yozuvlari server IP ga yo'naltirilgan (A-yozuv, `nginx/nginx.conf` bilan bir xil):
  - `api.pitgo.uz`   → backend API (APK va admin shu manzilga ulanadi)
  - `admin.pitgo.uz` → admin panel
  - `media.pitgo.uz` → APK/statik fayllar (ixtiyoriy, agar shu server orqali tarqatilsa)
  - `pitgo.uz`, `www.pitgo.uz` — bu yerda EMAS, Vercel'da landing (alohida deploy)

## 2. Sozlash
```bash
cd Backend
cp .env.example .env
nano .env          # DB_PASSWORD, JWT_SECRET, CLAUDE_API_KEY, SMTP_* ni to'ldiring
```
`.env` da muhim:
- `DB_PASSWORD`, `JWT_SECRET` — kuchli tasodifiy qiymatlar
- `NEXT_PUBLIC_API_URL=https://api.pitgo.uz/v1`
- `ALLOWED_ORIGINS=https://pitgo.uz,https://www.pitgo.uz`

## 3. Ishga tushirish
```bash
docker compose up -d --build
docker compose ps          # hammasi "running"/"healthy" bo'lishi kerak
docker compose logs -f backend
```

## 3.1 Ma'lumotlar bazasi migratsiyasi (Prisma)

> ⚠️ Migratsiya **avtomatik bajarilmaydi** — backend faqat `node dist/main`
> bilan ishga tushadi. Migratsiyani alohida ishga tushirish kerak.

**Prod / server (yangi jadval qo'shish, sxema o'zgarishi):**
```bash
docker compose exec backend npx prisma migrate deploy
```
Bu `prisma/migrations/` dagi barcha migratsiyalarni tartib bilan qo'llaydi.
Yangi backend imijini deploy qilganda, konteyner yangilangandan keyin shu buyruqni
ishga tushiring (yoki Dockerfile CMD ichida `prisma migrate deploy && node dist/main`
qilib qo'ying).

**Lokal ishlab chiqish (sxema o'zgartirganda):**
```bash
cd Backend/nest-backend
npx prisma migrate dev --name <ozgarish_nomi>
```

**Qoidalar:**
- `prisma db push` **ishlatilmaydi** — har bir sxema o'zgarishi migratsiya fayli
  bo'lishi shart (aks holda prodda ma'lumot yo'qolishi mumkin).
- Baseline migratsiya (`0_init`) mavjud bazadan yaratilgan va `resolve --applied`
  bilan bog'langan. Toza bazada `migrate deploy` to'liq sxemani quradi.
- Migratsiya holatini tekshirish: `npx prisma migrate status`.

> **PostGIS (Faza 3, 2026-08-08 dan boshlab faol):** `postgres` xizmati
> `postgis/postgis:16-3.4` imijiga o'tkazildi (`docker-compose.yml`). Prodga
> birinchi marta deploy qilinganda: konteyner qayta yaratiladi (imij
> almashgani uchun `docker compose up -d --build` yetarli, ma'lumot volume'da
> saqlanadi), so'ng `docker compose exec postgres psql -U $DB_USER -d $DB_NAME
> -c "CREATE EXTENSION IF NOT EXISTS postgis;"` bir marta qo'lda ishga
> tushiriladi (extension migratsiya faylida emas — superuser talab qilishi
> mumkin, `pitgo` prod user superuser emas bo'lsa buyruqni `postgres` superuser
> bilan bajaring). Shundan keyin oddiy `migrate deploy` davom etadi.
>
> Lokal dev: `Backend/docker-compose.dev.yml` — alohida `postgis/postgis:16-3.4`
> konteyner (port 5433), tizim Postgres'iga tegilmaydi.
>
> ⚠️ **GiST indekslar har safar `migrate dev --create-only` chaqirganda
> xavf ostida:** `shop_profiles_location_gist_idx` va
> `sos_requests_location_gist_idx` qo'lda (raw SQL) yaratilgan — Prisma bu
> haqda schema.prisma orqali bilmaydi, shuning uchun **har bir yangi
> migratsiyada** ularni "ortiqcha" deb `DROP INDEX` taklif qiladi. Har safar
> generatsiya qilingan `migration.sql`ni qo'llashdan oldin ko'zdan
> kechiring — bu ikki `DROP INDEX` qatori bo'lsa, o'chirib tashlang (misol:
> `20260808104446_faza3_5_sos_chat/migration.sql`dagi izoh).

## 4. Admin foydalanuvchi yaratish
API orqali admin ro'yxatdan o'tmaydi. Parolni `backend` konteyneri ichida
(bcrypt kutubxonasi shu yerda mavjud) hash qilib, to'g'ridan-to'g'ri bazaga
yozamiz:
```bash
HASH=$(docker compose exec -T backend node -e "require('bcrypt').hash(process.argv[1],12).then(h=>console.log(h))" "KUCHLI_PAROL")
docker compose exec -T postgres psql -U "$DB_USER" -d "$DB_NAME" -c "
INSERT INTO users (id, phone, email, password_hash, role, full_name, language, email_verified, created_at, updated_at)
VALUES (gen_random_uuid(), '+998900000000', 'admin@pitgo.uz', '$HASH', 'admin', 'Super Admin', 'uz', true, now(), now())
ON CONFLICT (phone) DO UPDATE SET password_hash = EXCLUDED.password_hash;
"
```
Telefon/email/parolni o'zingizga moslab o'zgartiring. Keyinroq parolni
yangilash uchun ham xuddi shu ikki buyruqni qayta ishga tushirasiz (yangi
parol bilan) — `ON CONFLICT` mavjud yozuvni yangilaydi.

## 5. SSL (Let's Encrypt)
Avval HTTP ishlayotganini tekshiring, keyin:
```bash
docker run --rm -v $PWD/certbot/conf:/etc/letsencrypt -v $PWD/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d api.pitgo.uz -d pitgo.uz -d www.pitgo.uz --email you@pitgo.uz --agree-tos --no-eff-email
```
So'ng `nginx/nginx.conf` dagi `443` (HTTPS) bloklarini oching va:
```bash
docker compose restart nginx
```
Avtomatik yangilash uchun cron: `docker run ... certbot renew && docker compose restart nginx`.

## 6. Yangilash
```bash
git pull
docker compose up -d --build
```

## Arxitektura
```
APK ─┐
     ├─ https://api.pitgo.uz/v1  ─► nginx ─► backend:8080 ─► postgres:5432
Web ─┘  https://pitgo.uz        ─► nginx ─► admin:3000
```
Fayllar (`uploads`) va DB (`pgdata`) Docker volume'larida saqlanadi.
