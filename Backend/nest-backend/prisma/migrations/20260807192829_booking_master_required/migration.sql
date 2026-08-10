-- DropForeignKey
ALTER TABLE "bookings" DROP CONSTRAINT "bookings_master_id_fkey";

-- AlterTable
ALTER TABLE "bookings" ALTER COLUMN "master_id" SET NOT NULL;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_master_id_fkey" FOREIGN KEY ("master_id") REFERENCES "masters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

