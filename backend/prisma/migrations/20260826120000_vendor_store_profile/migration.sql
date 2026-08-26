-- AlterTable
ALTER TABLE "Vendor" ADD COLUMN "contactEmail" TEXT;
ALTER TABLE "Vendor" ADD COLUMN "description" TEXT;
ALTER TABLE "Vendor" ADD COLUMN "phone" TEXT;
ALTER TABLE "Vendor" ADD COLUMN "slug" TEXT;

-- Backfill unique slugs from store names
UPDATE "Vendor"
SET "slug" = trim(both '-' from lower(regexp_replace("storeName", '[^A-Za-z0-9]+', '-', 'g')));

UPDATE "Vendor"
SET "slug" = 'store-' || substr(replace("id", '-', ''), 1, 8)
WHERE "slug" IS NULL OR "slug" = '';

WITH ranked AS (
  SELECT
    "id",
    "slug",
    ROW_NUMBER() OVER (PARTITION BY "slug" ORDER BY "createdAt", "id") AS rn
  FROM "Vendor"
)
UPDATE "Vendor" AS v
SET "slug" = r."slug" || '-' || r.rn
FROM ranked AS r
WHERE v."id" = r."id" AND r.rn > 1;

ALTER TABLE "Vendor" ALTER COLUMN "slug" SET NOT NULL;

CREATE UNIQUE INDEX "Vendor_slug_key" ON "Vendor"("slug");
