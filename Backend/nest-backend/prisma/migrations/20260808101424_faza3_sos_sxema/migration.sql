-- PostGIS (Faza 3, CLAUDE.md §8.1). "moshn" prod user superuser bo'lmasligi
-- mumkin — agar shu buyruq huquq xatosi bersa, uni migratsiyadan chiqarib,
-- DEPLOY.md'da yozilganidek superuser bilan qo'lda bir marta bajaring.
CREATE EXTENSION IF NOT EXISTS postgis;

-- AlterTable
ALTER TABLE "shop_profiles" ADD COLUMN     "location" geography(Point, 4326);

-- Mavjud servislarning lat/lng'sini geography ustuniga backfill qilamiz.
UPDATE "shop_profiles"
   SET "location" = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
 WHERE (latitude != 0 OR longitude != 0);

-- GiST index — ST_DWithin radius-qidiruvi shusiz to'liq jadval skanerlaydi
-- (CLAUDE.md §8.1).
CREATE INDEX "shop_profiles_location_gist_idx" ON "shop_profiles" USING GIST ("location");

-- CreateTable
CREATE TABLE "sos_requests" (
    "id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "vehicle_id" UUID NOT NULL,
    "service_type_id" UUID NOT NULL,
    "location" geography(Point, 4326) NOT NULL,
    "status" VARCHAR(20) NOT NULL DEFAULT 'pending',
    "accepted_master_id" UUID,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sos_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sos_dispatches" (
    "id" UUID NOT NULL,
    "sos_request_id" UUID NOT NULL,
    "shop_id" UUID NOT NULL,
    "wave" INTEGER NOT NULL,
    "distance_meters" INTEGER NOT NULL DEFAULT 0,
    "status" VARCHAR(20) NOT NULL DEFAULT 'sent',
    "sent_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "responded_at" TIMESTAMP(3),

    CONSTRAINT "sos_dispatches_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "sos_requests_location_gist_idx" ON "sos_requests" USING GIST ("location");

-- CreateIndex
CREATE INDEX "sos_requests_status_idx" ON "sos_requests"("status");

-- CreateIndex
CREATE INDEX "sos_requests_customer_id_idx" ON "sos_requests"("customer_id");

-- CreateIndex
CREATE INDEX "sos_dispatches_sos_request_id_idx" ON "sos_dispatches"("sos_request_id");

-- CreateIndex
CREATE INDEX "sos_dispatches_shop_id_status_idx" ON "sos_dispatches"("shop_id", "status");

-- AddForeignKey
ALTER TABLE "sos_requests" ADD CONSTRAINT "sos_requests_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_requests" ADD CONSTRAINT "sos_requests_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_requests" ADD CONSTRAINT "sos_requests_service_type_id_fkey" FOREIGN KEY ("service_type_id") REFERENCES "service_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_requests" ADD CONSTRAINT "sos_requests_accepted_master_id_fkey" FOREIGN KEY ("accepted_master_id") REFERENCES "masters"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_dispatches" ADD CONSTRAINT "sos_dispatches_sos_request_id_fkey" FOREIGN KEY ("sos_request_id") REFERENCES "sos_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_dispatches" ADD CONSTRAINT "sos_dispatches_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "shop_profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
