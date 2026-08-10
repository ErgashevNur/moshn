/*
  Warnings:

  - A unique constraint covering the columns `[sos_request_id]` on the table `payments` will be added. If there are existing duplicate values, this will fail.

*/
-- DropForeignKey
ALTER TABLE "payments" DROP CONSTRAINT "payments_booking_id_fkey";

-- DropForeignKey
ALTER TABLE "tips" DROP CONSTRAINT "tips_booking_id_fkey";

-- AlterTable
ALTER TABLE "payments" ADD COLUMN     "sos_request_id" UUID,
ALTER COLUMN "booking_id" DROP NOT NULL;

-- AlterTable
ALTER TABLE "tips" ADD COLUMN     "sos_request_id" UUID,
ALTER COLUMN "booking_id" DROP NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "payments_sos_request_id_key" ON "payments"("sos_request_id");

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_sos_request_id_fkey" FOREIGN KEY ("sos_request_id") REFERENCES "sos_requests"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tips" ADD CONSTRAINT "tips_booking_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tips" ADD CONSTRAINT "tips_sos_request_id_fkey" FOREIGN KEY ("sos_request_id") REFERENCES "sos_requests"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CheckConstraint: bookingId/sosRequestId'dan aynan bittasi to'lgan bo'lishi kerak (CLAUDE.md ruhida DB darajasidagi butunlik).
ALTER TABLE "payments" ADD CONSTRAINT "payment_one_target" CHECK (
  (("booking_id" IS NOT NULL)::int + ("sos_request_id" IS NOT NULL)::int) = 1
);

ALTER TABLE "tips" ADD CONSTRAINT "tip_one_target" CHECK (
  (("booking_id" IS NOT NULL)::int + ("sos_request_id" IS NOT NULL)::int) = 1
);
