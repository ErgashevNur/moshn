-- shop_profiles_location_gist_idx va sos_requests_location_gist_idx
-- QO'LDA yaratilgan (Unsupported("geography") maydoni Prisma diff-motoriga
-- ko'rinmaydi, shuning uchun avtomatik generatsiya ularni "ortiqcha" deb
-- DROP qilishni taklif qiladi — buni ATAYLAB olib tashladik, indekslar
-- qoladi, CLAUDE.md §8.1).

-- CreateTable
CREATE TABLE "sos_messages" (
    "id" UUID NOT NULL,
    "sos_request_id" UUID NOT NULL,
    "sender_user_id" UUID NOT NULL,
    "body" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sos_messages_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "sos_messages_sos_request_id_idx" ON "sos_messages"("sos_request_id");

-- AddForeignKey
ALTER TABLE "sos_messages" ADD CONSTRAINT "sos_messages_sos_request_id_fkey" FOREIGN KEY ("sos_request_id") REFERENCES "sos_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_messages" ADD CONSTRAINT "sos_messages_sender_user_id_fkey" FOREIGN KEY ("sender_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
