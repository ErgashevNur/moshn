# Moshn — Serverga Docker bilan deploy

Backend (Go API), Admin (Next.js), PostgreSQL va Nginx — hammasi Docker Compose orqali.

## 1. Talablar (serverda)
- Docker + Docker Compose (`docker compose version` ishlashi kerak)
- Ochiq portlar: 80, 443
- DNS yozuvlari server IP ga yo'naltirilgan:
  - `api.moshn.uz`  → backend API (APK shu manzilga ulanadi)
  - `moshn.uz`, `www.moshn.uz` → admin panel

## 2. Sozlash
```bash
cd Backend
cp .env.example .env
nano .env          # DB_PASSWORD, JWT_SECRET, CLAUDE_API_KEY, SMTP_* ni to'ldiring
```
`.env` da muhim:
- `DB_PASSWORD`, `JWT_SECRET` — kuchli tasodifiy qiymatlar
- `NEXT_PUBLIC_API_URL=https://api.moshn.uz/v1`
- `ALLOWED_ORIGINS=https://moshn.uz,https://www.moshn.uz`

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

> **Eslatma:** SOS moduli (Faza 3) uchun PostGIS kerak bo'ladi. Hozircha
> postgres imijida postgis paketi yo'q. O'sha vaqtda `postgres:16-alpine` o'rniga
> `postgis/postgis:16-3.4` imijiga o'tiladi va migratsiyada
> `CREATE EXTENSION IF NOT EXISTS postgis;` qo'shiladi.

## 4. Admin foydalanuvchi yaratish
API orqali admin ro'yxatdan o'tmaydi — konteynerda yaratamiz:
```bash
docker compose exec backend ./server --help 2>/dev/null || true
# Yoki createadmin tool'ini host'da ishga tushiring (DATABASE_URL ni serverga moslab):
#   cd backend && go run ./tools/createadmin --phone "+998..." --email "admin@moshn.uz" --password "..."
```
(Test ma'lumotlari uchun `go run ./tools/seed`.)

## 5. SSL (Let's Encrypt)
Avval HTTP ishlayotganini tekshiring, keyin:
```bash
docker run --rm -v $PWD/certbot/conf:/etc/letsencrypt -v $PWD/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d api.moshn.uz -d moshn.uz -d www.moshn.uz --email you@moshn.uz --agree-tos --no-eff-email
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
     ├─ https://api.moshn.uz/v1  ─► nginx ─► backend:8080 ─► postgres:5432
Web ─┘  https://moshn.uz        ─► nginx ─► admin:3000
```
Fayllar (`uploads`) va DB (`pgdata`) Docker volume'larida saqlanadi.
