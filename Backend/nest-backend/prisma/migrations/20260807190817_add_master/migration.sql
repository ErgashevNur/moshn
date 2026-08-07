-- AlterTable
ALTER TABLE "bookings" ADD COLUMN     "master_id" UUID;

-- CreateTable
CREATE TABLE "masters" (
    "id" UUID NOT NULL,
    "shop_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "full_name" TEXT NOT NULL,
    "position" TEXT NOT NULL DEFAULT '',
    "avatar_url" TEXT NOT NULL DEFAULT '',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "rating_avg" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "rating_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "masters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "master_service_types" (
    "master_id" UUID NOT NULL,
    "service_type_id" UUID NOT NULL,

    CONSTRAINT "master_service_types_pkey" PRIMARY KEY ("master_id","service_type_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "masters_user_id_key" ON "masters"("user_id");

-- CreateIndex
CREATE INDEX "masters_shop_id_idx" ON "masters"("shop_id");

-- CreateIndex
CREATE INDEX "master_service_types_service_type_id_idx" ON "master_service_types"("service_type_id");

-- CreateIndex
CREATE INDEX "bookings_master_id_idx" ON "bookings"("master_id");

-- AddForeignKey
ALTER TABLE "masters" ADD CONSTRAINT "masters_shop_id_fkey" FOREIGN KEY ("shop_id") REFERENCES "shop_profiles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "masters" ADD CONSTRAINT "masters_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "master_service_types" ADD CONSTRAINT "master_service_types_master_id_fkey" FOREIGN KEY ("master_id") REFERENCES "masters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "master_service_types" ADD CONSTRAINT "master_service_types_service_type_id_fkey" FOREIGN KEY ("service_type_id") REFERENCES "service_types"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_master_id_fkey" FOREIGN KEY ("master_id") REFERENCES "masters"("id") ON DELETE SET NULL ON UPDATE CASCADE;

