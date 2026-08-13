-- Vehicle: probeg va keyingi TO (bosh ekrandagi mashina kartasi uchun).
--
-- ⚠️ `prisma migrate diff` bu migratsiyaga uchta `DROP INDEX` ham qo'shgan edi
-- (`shop_profiles_location_gist_idx`, `sos_requests_location_gist_idx`,
-- `evacuators_location_gist_idx`). Ular ATAYLAB olib tashlandi: bu GiST
-- indekslar `Unsupported("geography(...)")` ustunlar uchun migratsiyada qo'lda
-- yaratilgan va Prisma ularni "ortiqcha" deb hisoblaydi. O'chirilsa SOS
-- geo-qidiruvi index o'rniga to'liq jadval skanerlashga tushadi (CLAUDE.md §8.1).
-- Xuddi shu tuzoq DEPLOY.md va PITGO_PLAN.md §3.8 da ham qayd etilgan.

ALTER TABLE "vehicles"
  ADD COLUMN "mileage_km"      INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "next_service_km" INTEGER NOT NULL DEFAULT 0;
