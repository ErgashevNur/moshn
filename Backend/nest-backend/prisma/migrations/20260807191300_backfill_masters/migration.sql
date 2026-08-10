-- Faza 2.2: mavjud servislar uchun standart usta (data migration)
-- Prinsip (CLAUDE.md §3): "yakka usta ham servis" — mavjud servis egasining o'zi
-- shu servisning standart ustasi bo'ladi. Yangi login yaratilmaydi.
-- Toza (bo'sh) bazada bu migratsiya hech narsa qilmaydi — xavfsiz.

-- 1) Har bir shop_profile uchun bitta Master.
--    Master.user_id = servis egasining useri (ShopProfile.user_id unique).
--    Ism: egasining full_name'i, bo'sh bo'lsa shop_name.
INSERT INTO "masters" (
  "id", "shop_id", "user_id", "full_name", "position",
  "avatar_url", "is_active", "rating_avg", "rating_count",
  "created_at", "updated_at"
)
SELECT
  gen_random_uuid(),
  sp."id",
  sp."user_id",
  COALESCE(NULLIF(u."full_name", ''), NULLIF(sp."shop_name", ''), 'Usta'),
  '',
  COALESCE(u."avatar_url", ''),
  true,
  0,
  0,
  now(),
  now()
FROM "shop_profiles" sp
JOIN "users" u ON u."id" = sp."user_id"
WHERE NOT EXISTS (
  SELECT 1 FROM "masters" m WHERE m."user_id" = sp."user_id"
);

-- 2) Mavjud bookinglarni shu servisning standart ustasiga bog'lash.
--    Backfill'dan keyin har bir shopda aynan bitta usta bor.
UPDATE "bookings" b
SET "master_id" = m."id"
FROM "masters" m
WHERE m."shop_id" = b."shop_id"
  AND b."master_id" IS NULL;

-- 3) Standart ustaga servisning xizmatlarini biriktirish.
--    Manba: shop_service_prices (haqiqiy service_type_id lar).
--    SOS tarqatishida "qaysi usta bu xizmatni bajaradi" filtri uchun.
INSERT INTO "master_service_types" ("master_id", "service_type_id")
SELECT DISTINCT m."id", ssp."service_type_id"
FROM "masters" m
JOIN "shop_service_prices" ssp ON ssp."shop_id" = m."shop_id"
ON CONFLICT DO NOTHING;
