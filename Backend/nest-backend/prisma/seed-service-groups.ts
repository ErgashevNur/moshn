// Bosh sahifa kategoriya taksonomiyasini 7 tekis kategoriyadan 5 chuqur
// guruhga o'tkazish (2026-08, "Bosh sahifani qayta qurish" rejasi).
// Qayta ishga tushirish xavfsiz — slug bo'yicha upsert qilinadi.
// DIQQAT: bu fayl `seed-service-groups.js` dan ko'chiriladi — mantiqni O'SHA
// faylda tahrirlang (konteynerda tsconfig yo'qligi sababli amalda `.js`
// varianti ishga tushiriladi), keyin bu nusxani yangilang.
//
// Ishga tushirish: DATABASE_URL to'g'ri o'rnatilgan holda
//   npx ts-node prisma/seed-service-groups.ts

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const ICON = {
  service: 'wrench',
  oil: 'droplet',
  body: 'car',
  electrics: 'zap',
};

type Seed = {
  slug: string;
  nameUz: string;
  nameRu: string;
  category: string;
  icon: string;
};

const SEED: Seed[] = [
  // ── Авто сервис ──────────────────────────────────────────────
  { slug: 'motor', nameUz: 'Motor', nameRu: 'Мотор', category: 'service', icon: ICON.service },
  { slug: 'hodovaya', nameUz: 'Yurish qismi (podveska)', nameRu: 'Ходовая часть', category: 'service', icon: ICON.service },
  { slug: 'to-dokument', nameUz: 'TO va hujjatlar', nameRu: 'ТО и документы', category: 'service', icon: ICON.service },
  { slug: 'diagnostika-umumiy', nameUz: 'Umumiy diagnostika', nameRu: 'Общая диагностика', category: 'service', icon: ICON.service },
  { slug: 'rul-kolonkasi', nameUz: 'Rul kolonkasi', nameRu: 'Рулевая колонка', category: 'service', icon: ICON.service },
  { slug: 'korobka-peredach', nameUz: 'Uzatmalar qutisi (KPP)', nameRu: 'Коробка передач', category: 'service', icon: ICON.service },
  { slug: 'tormoz-tizimi', nameUz: 'Tormoz tizimi', nameRu: 'Тормозная система', category: 'service', icon: ICON.service },
  { slug: 'service-boshqa', nameUz: 'Boshqa', nameRu: 'Другое', category: 'service', icon: ICON.service },

  // ── Замена масла ─────────────────────────────────────────────
  { slug: 'motor-moyi', nameUz: 'Motor moyini almashtirish', nameRu: 'Замена моторного масла', category: 'oil', icon: ICON.oil },
  { slug: 'kpp-moyi', nameUz: 'KPP moyini almashtirish', nameRu: 'Замена масла коробки', category: 'oil', icon: ICON.oil },
  { slug: 'antifriz', nameUz: 'Antifriz almashtirish', nameRu: 'Замена антифриза', category: 'oil', icon: ICON.oil },
  { slug: 'tormoz-suyuqligi', nameUz: 'Tormoz suyuqligi', nameRu: 'Тормозная жидкость', category: 'oil', icon: ICON.oil },
  { slug: 'reduktor-moyi', nameUz: 'Reduktor moyini almashtirish', nameRu: 'Замена масла редуктора', category: 'oil', icon: ICON.oil },
  { slug: 'oil-boshqa', nameUz: 'Boshqa', nameRu: 'Другое', category: 'oil', icon: ICON.oil },

  // ── Кузовщик ─────────────────────────────────────────────────
  { slug: 'vmyatiny-vakuum', nameUz: "Botiqlarni vakuum bilan tuzatish (PDR)", nameRu: 'Удаление вмятин (PDR)', category: 'body', icon: ICON.body },
  { slug: 'posle-avarii', nameUz: "Avariyadan keyin ta'mirlash", nameRu: 'Ремонт после аварии', category: 'body', icon: ICON.body },
  { slug: 'polirovka', nameUz: 'Polirovka', nameRu: 'Полировка', category: 'body', icon: ICON.body },
  { slug: 'pokraska', nameUz: "Bo'yash", nameRu: 'Покраска', category: 'body', icon: ICON.body },
  { slug: 'steklo-treshiny', nameUz: "Oyna yorig'ini tuzatish", nameRu: 'Ремонт трещин стекла', category: 'body', icon: ICON.body },
  { slug: 'nastroyka-dver-kapot', nameUz: 'Eshik/kapot/banaj sozlash', nameRu: 'Регулировка дверей, капота, бампера', category: 'body', icon: ICON.body },
  { slug: 'body-boshqa', nameUz: 'Boshqa', nameRu: 'Другое', category: 'body', icon: ICON.body },

  // ── Электрик ─────────────────────────────────────────────────
  { slug: 'diagnostika-elektrik', nameUz: 'Elektrik diagnostika', nameRu: 'Электродиагностика', category: 'electrics', icon: ICON.electrics },
  { slug: 'akkumulyator', nameUz: 'Akkumulyator', nameRu: 'Аккумулятор', category: 'electrics', icon: ICON.electrics },
  {
    slug: 'dop-apparatura',
    nameUz: "Qo'shimcha apparatura o'rnatish (signalizatsiya, fara, kamera, radar)",
    nameRu: 'Установка доп. оборудования (сигнализация, фары, камера, радар)',
    category: 'electrics',
    icon: ICON.electrics,
  },
  { slug: 'svet-fary', nameUz: "Yorug'lik (faralar)", nameRu: 'Свет (фары)', category: 'electrics', icon: ICON.electrics },
  { slug: 'chip-computer-datchik', nameUz: 'Avto chip, kompyuter, datchiklar', nameRu: 'Авточип, компьютер, датчики', category: 'electrics', icon: ICON.electrics },
  { slug: 'electrics-boshqa', nameUz: 'Boshqa', nameRu: 'Другое', category: 'electrics', icon: ICON.electrics },
];

// Eski taksonomiyadagi xizmatlar YO'QOTILMAYDI — ular yangi guruhga
// ko'chiriladi. Sabab: `ShopServicePrice` (servislar qo'ygan narxlar) va
// `Booking` yozuvlari o'sha `ServiceType` qatoriga bog'langan; yangisini
// yaratib eskisini o'chirsak, servislar narxlarni qaytadan kiritishi kerak
// bo'lardi va tarix uzilardi.
//
// Har bir eski xizmat yangi ro'yxatdagi ekvivalentiga aylantiriladi
// (`replaces` — o'sha yozuv qayta yaratilmaydi, dublikat chiqmasin).
// ⚠️ `slug` ATAYLAB o'zgartirilmaydi: `ShopProfile.serviceTypes` massivi
// slug'larni saqlaydi, uni o'zgartirish servis profillarini buzardi.
const MIGRATIONS = [
  { slug: 'oil_change',     category: 'oil',     nameUz: 'Motor moyini almashtirish', nameRu: 'Замена моторного масла', icon: ICON.oil,     replaces: 'motor-moyi' },
  { slug: 'engine_repair',  category: 'service', nameUz: 'Motor',                     nameRu: 'Мотор',                  icon: ICON.service, replaces: 'motor' },
  { slug: 'brake_repair',   category: 'service', nameUz: 'Tormoz tizimi',             nameRu: 'Тормозная система',      icon: ICON.service, replaces: 'tormoz-tizimi' },
  { slug: 'gearbox_repair', category: 'service', nameUz: 'Uzatmalar qutisi (KPP)',    nameRu: 'Коробка передач',        icon: ICON.service, replaces: 'korobka-peredach' },
];

// Ko'chirilmagan, eski taksonomiyada qolib ketgan yozuvlar shu kategoriyalarda
// nofaol qilinadi (o'chirilmaydi — FK butunligi saqlanadi). `tires`ga tegilmaydi.
const RETIRING_CATEGORIES = ['engine', 'brakes', 'transmission', 'other', 'body', 'electrics'];

const DRY_RUN = process.argv.includes('--dry-run');

async function main() {
  if (DRY_RUN) console.log('*** DRY RUN — bazaga hech narsa yozilmaydi ***\n');

  // 1) Eski xizmatlarni yangi guruhga ko'chirish (mavjud bo'lsa).
  const replaced = new Set<string>();
  for (const m of MIGRATIONS) {
    const existing = await prisma.serviceType.findUnique({ where: { slug: m.slug } });
    if (!existing) {
      console.log(`skip    ${m.slug} — bu bazada yo'q, o'rniga '${m.replaces}' yaratiladi`);
      continue;
    }
    replaced.add(m.replaces);
    if (!DRY_RUN) {
      await prisma.serviceType.update({
        where: { slug: m.slug },
        data: {
          category: m.category,
          nameUz: m.nameUz,
          nameRu: m.nameRu,
          icon: m.icon,
          isActive: true,
        },
      });
    }
    console.log(
      `migrate ${m.slug.padEnd(16)} ${existing.category} → ${m.category}   ("${existing.nameRu}" → "${m.nameRu}")`,
    );
  }

  // 2) Yangi xizmatlarni yaratish — 1-qadamda ko'chirilganlari o'tkazib yuboriladi.
  let created = 0;
  for (const s of SEED) {
    if (replaced.has(s.slug)) {
      console.log(`skip    ${s.slug.padEnd(16)} — eski yozuv ko'chirildi, dublikat yaratilmaydi`);
      continue;
    }
    if (!DRY_RUN) {
      await prisma.serviceType.upsert({
        where: { slug: s.slug },
        create: { slug: s.slug, nameUz: s.nameUz, nameRu: s.nameRu, category: s.category, icon: s.icon, isActive: true },
        update: { nameUz: s.nameUz, nameRu: s.nameRu, category: s.category, icon: s.icon, isActive: true },
      });
    }
    created++;
    console.log(`upsert  ${s.slug.padEnd(16)} ${s.category}`);
  }

  // 3) Qolgan eski yozuvlar (ko'chirilmaganlari) — nofaol.
  //    Ko'chirilgan slug'lar ATAYLAB istisno qilinadi: 1-qadam ularning
  //    kategoriyasini yangilagani uchun odatda bu shartga tushmaydi, lekin
  //    aniq istisno bo'lmasa `--dry-run` (hech narsa yozmaydi) ularni
  //    "nofaol qilinadi" deb noto'g'ri ko'rsatardi.
  //    ⚠️ `RETIRING_CATEGORIES` ichida `body` va `electrics` ham bor — bular
  //    ayni paytda YANGI taksonomiyaning ham kategoriyalari (mazmuni almashdi).
  //    Shuning uchun hozirgina urug'langan slug'lar ham istisno qilinishi SHART,
  //    aks holda 2-qadamda yaratilgan xizmatlar shu yerda o'chib ketadi.
  const keepSlugs = [...MIGRATIONS.map((m) => m.slug), ...SEED.map((s) => s.slug)];
  const staleWhere = {
    category: { in: RETIRING_CATEGORIES },
    isActive: true,
    slug: { notIn: keepSlugs },
  };
  const stale = await prisma.serviceType.findMany({
    where: staleWhere,
    select: { slug: true, category: true },
  });
  if (!DRY_RUN && stale.length) {
    await prisma.serviceType.updateMany({ where: staleWhere, data: { isActive: false } });
  }
  for (const s of stale) console.log(`disable ${s.slug.padEnd(16)} (${s.category})`);

  console.log(
    `\nXULOSA: ${replaced.size} ko'chirildi, ${created} yaratildi/yangilandi, ` +
      `${stale.length} nofaol qilindi.` +
      (DRY_RUN ? '\n(DRY RUN — hech narsa yozilmadi)' : ''),
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
