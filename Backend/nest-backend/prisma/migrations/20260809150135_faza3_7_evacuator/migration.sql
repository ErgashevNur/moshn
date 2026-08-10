-- shop_profiles_location_gist_idx va sos_requests_location_gist_idx uchun
-- DROP INDEX'lar ATAYLAB olib tashlandi — qo'lda yaratilgan indekslar,
-- Prisma diff-motoriga ko'rinmaydi (DEPLOY.md'dagi ogohlantirishga qarang).

-- DropForeignKey
ALTER TABLE "sos_dispatches" DROP CONSTRAINT "sos_dispatches_shop_id_fkey";

-- AlterTable
ALTER TABLE "sos_dispatches" ADD COLUMN     "evacuator_id" UUID,
ALTER COLUMN "shop_id" DROP NOT NULL;

-- AlterTable
ALTER TABLE "sos_requests" ADD COLUMN     "accepted_evacuator_id" UUID,
ADD COLUMN     "dispatch_mode" VARCHAR(20) NOT NULL DEFAULT 'shop',
ADD COLUMN     "evacuator_requested_at" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "evacuators" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "full_name" TEXT NOT NULL,
    "phone" TEXT NOT NULL DEFAULT '',
    "vehicle_plate" TEXT NOT NULL DEFAULT '',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "location" geography(Point, 4326),
    "rating_avg" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "rating_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "evacuators_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "evacuators_user_id_key" ON "evacuators"("user_id");

-- CreateIndex
CREATE INDEX "sos_dispatches_evacuator_id_status_idx" ON "sos_dispatches"("evacuator_id", "status");

-- GiST index — evakuator geo-qidiruvi ST_DWithin uchun (CLAUDE.md §8.1).
CREATE INDEX "evacuators_location_gist_idx" ON "evacuators" USING GIST ("location");

-- AddForeignKey
ALTER TABLE "sos_requests" ADD CONSTRAINT "sos_requests_accepted_evacuator_id_fkey" FOREIGN KEY ("accepted_evacuator_id") REFERENCES "evacuators"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_dispatches" ADD CONSTRAINT "sos_dispatches_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "shop_profiles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_dispatches" ADD CONSTRAINT "sos_dispatches_evacuator_id_fkey" FOREIGN KEY ("evacuator_id") REFERENCES "evacuators"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evacuators" ADD CONSTRAINT "evacuators_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
