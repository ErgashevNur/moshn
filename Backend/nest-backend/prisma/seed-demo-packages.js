// Zapis ekrani uchun namuna ma'lumot: har servisga paketlar, narx diapazoni
// va (yo'q bo'lsa) standart usta.
//
// Nima uchun kerak: ekran tayyor, lekin prod bazasida bironta ham paket,
// narx yoki (ko'p servisda) faol usta yo'q edi — shuning uchun oqim bo'sh
// ko'rinardi. Servis egalari keyinchalik bularni o'z ilovasidan tahrirlaydi.
//
// Qayta ishga tushirish xavfsiz: mavjud paket/narx qayta yaratilmaydi.
//
//   node prisma/seed-demo-packages.js --dry-run   → faqat ko'rsatadi
//   node prisma/seed-demo-packages.js             → yozadi

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const DRY_RUN = process.argv.includes('--dry-run');
/// Ilgari o'zbekcha matn bilan yaratilgan namuna paketlarni ruscha
/// variantiga yangilaydi. Faqat AYNAN eski namuna nomlariga tegadi —
/// servis egasi o'zi yozgan paketlar o'zgarmaydi.
const UPDATE_TEXTS = process.argv.includes('--update-texts');
const LEGACY_NAMES = ['Bazoviy', 'Standart', 'Premium'];

// Kategoriya bo'yicha bazaviy narx (so'm) va davomiylik (daqiqa).
// Uch pog'ona: [Bazoviy, Standart, Premium].
const TIERS = {
  oil: {
    prices: [320_000, 480_000, 890_000],
    durations: [40, 60, 90],
    desc: [
      'Mannol 5W-40, масляный фильтр',
      'Shell Helix 5W-40, фильтр, проверка 12 узлов',
      'Motul 5W-40, 4 фильтра, полная диагностика',
    ],
  },
  tires: {
    prices: [80_000, 150_000, 260_000],
    durations: [30, 45, 75],
    desc: [
      'Балансировка, 4 колеса',
      'Замена + балансировка, вентиль',
      'Замена, балансировка, ремонт, хранение',
    ],
  },
  service: {
    prices: [200_000, 420_000, 850_000],
    durations: [45, 90, 150],
    desc: [
      'Диагностика и регулировка',
      'Средний ремонт, запчасти отдельно',
      'Полный ремонт с гарантией',
    ],
  },
  body: {
    prices: [450_000, 1_200_000, 2_400_000],
    durations: [60, 180, 300],
    desc: [
      'Один элемент, мелкие работы',
      'Покраска и рихтовка, 2 элемента',
      'Полные кузовные работы, гарантия качества',
    ],
  },
  electrics: {
    prices: [150_000, 320_000, 640_000],
    durations: [30, 60, 120],
    desc: [
      'Компьютерная диагностика',
      'Поиск и устранение неисправности',
      'Вся электрика, установка оборудования',
    ],
  },
};

const TIER_NAMES = ['Базовый', 'Стандарт', 'Премиум'];

/// Servislar orasida narx bir xil bo'lmasin — "Arzon" saralashi ma'noli
/// bo'lishi uchun har servisga barqaror (id'ga bog'liq) koeffitsient.
function shopFactor(shopId) {
  let h = 0;
  for (const ch of shopId) h = (h * 31 + ch.charCodeAt(0)) % 1000;
  return 0.85 + (h % 31) / 100; // 0.85 – 1.15
}

const round5k = (n) => Math.round(n / 5000) * 5000;

async function main() {
  if (DRY_RUN) console.log('*** DRY RUN — bazaga hech narsa yozilmaydi ***\n');

  if (UPDATE_TEXTS) {
    await updateLegacyTexts();
    return;
  }

  const shops = await prisma.shopProfile.findMany({
    where: { verificationStatus: { in: ['verified', 'pending'] } },
    select: {
      id: true, userId: true, shopName: true, serviceTypes: true,
      masters: { where: { isActive: true }, select: { id: true } },
      user: { select: { fullName: true, avatarUrl: true } },
    },
  });

  const types = await prisma.serviceType.findMany({
    where: { isActive: true },
    select: { id: true, slug: true, category: true, nameRu: true },
  });
  const bySlug = new Map(types.map((t) => [t.slug, t]));

  let createdMasters = 0, createdPackages = 0, createdPrices = 0, skipped = 0;

  for (const shop of shops) {
    const label = (shop.shopName || shop.id.slice(0, 8)).padEnd(16).slice(0, 16);

    // 1) Ustasiz servisda bron yaratib bo'lmaydi — standart usta
    //    (egasining o'zi, Faza 2.2 backfill bilan bir xil mantiq).
    if (shop.masters.length === 0) {
      console.log(`${label} usta yo'q → standart usta yaratiladi`);
      if (!DRY_RUN) {
        await prisma.master.create({
          data: {
            shopId: shop.id,
            userId: shop.userId,
            fullName: shop.user?.fullName?.trim() || shop.shopName || 'Usta',
            avatarUrl: shop.user?.avatarUrl || '',
            isActive: true,
          },
        });
      }
      createdMasters++;
    }

    // 2) Servis ko'rsatadigan har bir xizmat uchun paketlar
    for (const slug of shop.serviceTypes || []) {
      const st = bySlug.get(slug);
      if (!st) continue;

      const tier = TIERS[st.category] || TIERS.service;
      const f = shopFactor(shop.id);

      const existing = await prisma.shopServicePackage.count({
        where: { shopId: shop.id, serviceTypeId: st.id },
      });
      if (existing > 0) {
        skipped++;
        continue;
      }

      const prices = tier.prices.map((p) => round5k(p * f));

      for (let i = 0; i < TIER_NAMES.length; i++) {
        if (!DRY_RUN) {
          await prisma.shopServicePackage.create({
            data: {
              shopId: shop.id,
              serviceTypeId: st.id,
              name: TIER_NAMES[i],
              description: tier.desc[i],
              durationMin: tier.durations[i],
              price: prices[i],
              sortOrder: i,
            },
          });
        }
        createdPackages++;
      }
      console.log(`${label} ${slug.padEnd(16)} ${prices.join(' / ')}`);

      // 3) Katalogdagi narx diapazoni ham to'lsin
      const hasPrice = await prisma.shopServicePrice.findUnique({
        where: { shopId_serviceTypeId: { shopId: shop.id, serviceTypeId: st.id } },
      });
      if (!hasPrice) {
        if (!DRY_RUN) {
          await prisma.shopServicePrice.create({
            data: {
              shopId: shop.id,
              serviceTypeId: st.id,
              priceMin: prices[0],
              priceMax: prices[prices.length - 1],
            },
          });
        }
        createdPrices++;
      }
    }
  }

  console.log(
    `\nXULOSA: ${createdMasters} usta, ${createdPackages} paket, ` +
      `${createdPrices} narx yozuvi yaratildi; ${skipped} xizmat o'tkazib yuborildi (paketi bor).` +
      (DRY_RUN ? '\n(DRY RUN — hech narsa yozilmadi)' : ''),
  );
}

/// Eski namuna paketlarining nomi va tavsifini yangilaydi (narx tegilmaydi).
async function updateLegacyTexts() {
  const legacy = await prisma.shopServicePackage.findMany({
    where: { name: { in: LEGACY_NAMES } },
    include: { serviceType: { select: { category: true } } },
  });
  console.log(`eski namuna paketlari: ${legacy.length}`);

  let n = 0;
  for (const p of legacy) {
    const i = LEGACY_NAMES.indexOf(p.name);
    const tier = TIERS[p.serviceType.category] || TIERS.service;
    const name = TIER_NAMES[i];
    const description = tier.desc[i];
    if (p.name === name && p.description === description) continue;

    if (!DRY_RUN) {
      await prisma.shopServicePackage.update({
        where: { id: p.id },
        data: { name, description },
      });
    }
    n++;
  }
  console.log(
    `XULOSA: ${n} paket matni yangilandi.` +
      (DRY_RUN ? '\n(DRY RUN — hech narsa yozilmadi)' : ''),
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
