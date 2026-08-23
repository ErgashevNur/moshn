-- Ish bosqichlari va fotohisobot (mijozga "В работе" ekrani uchun).
-- PackageStage — servis paketda belgilaydi; BookingStage — bron yaratilganda
-- paketdan ko'chiriladi (paket keyin o'zgarsa bron o'z bosqichlarini saqlaydi).
-- Booking.order_no — mijozga ko'rsatiladigan qisqa raqam.
--
-- ⚠️ `migrate diff` yana uchta GiST `DROP INDEX` qo'shgan edi — olib
-- tashlandi (CLAUDE.md §8.1, DEPLOY.md dagi ma'lum tuzoq).

-- AlterTable
ALTER TABLE "bookings" ADD COLUMN     "order_no" SERIAL NOT NULL;

-- CreateTable
CREATE TABLE "package_stages" (
    "id" UUID NOT NULL,
    "package_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "package_stages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "booking_stages" (
    "id" UUID NOT NULL,
    "booking_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "status" VARCHAR(20) NOT NULL DEFAULT 'pending',
    "started_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),

    CONSTRAINT "booking_stages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "booking_photos" (
    "id" UUID NOT NULL,
    "booking_id" UUID NOT NULL,
    "url" TEXT NOT NULL,
    "stage_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_photos_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "package_stages_package_id_idx" ON "package_stages"("package_id");

-- CreateIndex
CREATE INDEX "booking_stages_booking_id_idx" ON "booking_stages"("booking_id");

-- CreateIndex
CREATE INDEX "booking_photos_booking_id_idx" ON "booking_photos"("booking_id");

-- AddForeignKey
ALTER TABLE "package_stages" ADD CONSTRAINT "package_stages_package_id_fkey" FOREIGN KEY ("package_id") REFERENCES "shop_service_packages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_stages" ADD CONSTRAINT "booking_stages_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_photos" ADD CONSTRAINT "booking_photos_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

