-- Xizmat paketlari: har bir servis o'z "Bazoviy/Standart/Premium" takliflarini
-- belgilaydi (nom, tarkib, muddat, narx). Booking'ga package_id va duration_min.
--
-- ⚠️ `prisma migrate diff` bu migratsiyaga ham uchta `DROP INDEX` qo'shgan edi
-- (shop_profiles/sos_requests/evacuators_location_gist_idx). Ular ATAYLAB olib
-- tashlandi: bu GiST indekslar Unsupported("geography(...)") ustunlar uchun
-- qo'lda yaratilgan, Prisma ularni "ortiqcha" deb hisoblaydi. O'chirilsa SOS
-- geo-qidiruvi to'liq jadval skanerlashga tushadi (CLAUDE.md §8.1).

-- AlterTable
ALTER TABLE "bookings" ADD COLUMN     "duration_min" INTEGER NOT NULL DEFAULT 60,
ADD COLUMN     "package_id" UUID;

-- CreateTable
CREATE TABLE "shop_service_packages" (
    "id" UUID NOT NULL,
    "shop_id" UUID NOT NULL,
    "service_type_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL DEFAULT '',
    "duration_min" INTEGER NOT NULL DEFAULT 60,
    "price" INTEGER NOT NULL DEFAULT 0,
    "currency" VARCHAR(10) NOT NULL DEFAULT 'UZS',
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "shop_service_packages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "shop_service_packages_shop_id_service_type_id_idx" ON "shop_service_packages"("shop_id", "service_type_id");

-- AddForeignKey
ALTER TABLE "shop_service_packages" ADD CONSTRAINT "shop_service_packages_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "shop_profiles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shop_service_packages" ADD CONSTRAINT "shop_service_packages_service_type_id_fkey" FOREIGN KEY ("service_type_id") REFERENCES "service_types"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_package_id_fkey" FOREIGN KEY ("package_id") REFERENCES "shop_service_packages"("id") ON DELETE SET NULL ON UPDATE CASCADE;

