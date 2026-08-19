-- Qo'shimcha ish (usta taklif qiladi, mijoz tasdiqlaydi).
--
-- ⚠️ DIQQAT: `prisma migrate diff` bu faylga uchta `DROP INDEX` qo'shgan edi
-- (`shop_profiles/sos_requests/evacuators_location_gist_idx`). Ular QO'LDA
-- OLIB TASHLANDI. Sabab: PostGIS GiST indekslari Prisma sxemasida
-- ko'rinmaydi (`Unsupported` maydon), shuning uchun diff ularni "ortiqcha"
-- deb hisoblaydi. Qo'llansa SOS geo-qidiruvi indekssiz qolardi
-- (CLAUDE.md §8.1). Xuddi shu tuzoq 20260813061507_vehicle_mileage da ham
-- bo'lgan.

-- CreateTable
CREATE TABLE "booking_extras" (
    "id" UUID NOT NULL,
    "booking_id" UUID NOT NULL,
    "stage_id" UUID,
    "name" TEXT NOT NULL,
    "price" INTEGER NOT NULL DEFAULT 0,
    "status" VARCHAR(20) NOT NULL DEFAULT 'proposed',
    "responded_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_extras_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "booking_extras_booking_id_idx" ON "booking_extras"("booking_id");

-- CreateIndex
CREATE INDEX "booking_extras_stage_id_idx" ON "booking_extras"("stage_id");

-- AddForeignKey
ALTER TABLE "booking_extras" ADD CONSTRAINT "booking_extras_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "booking_extras" ADD CONSTRAINT "booking_extras_stage_id_fkey" FOREIGN KEY ("stage_id") REFERENCES "booking_stages"("id") ON DELETE SET NULL ON UPDATE CASCADE;
