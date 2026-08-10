-- ServiceType: basePrice (bitta raqam) o'rniga priceMin/priceMax (diapazon).
-- Mavjud qiymatlar yo'qotilmasin deb price_min=price_max=eski base_price
-- qilib backfill qilinadi (admin keyin haqiqiy diapazonni tahrirlaydi).

ALTER TABLE "service_types" ADD COLUMN "price_min" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "service_types" ADD COLUMN "price_max" INTEGER NOT NULL DEFAULT 0;

UPDATE "service_types" SET "price_min" = "base_price", "price_max" = "base_price" WHERE "base_price" > 0;

ALTER TABLE "service_types" DROP COLUMN "base_price";
