-- AlterTable
ALTER TABLE "User" ADD COLUMN "phone" TEXT;
ALTER TABLE "User" ADD COLUMN "district" TEXT;
ALTER TABLE "User" ADD COLUMN "sector" TEXT;
ALTER TABLE "User" ADD COLUMN "landmark" TEXT;

-- AlterTable
ALTER TABLE "CustomerOrder" ADD COLUMN "email" TEXT;
ALTER TABLE "CustomerOrder" ADD COLUMN "isGuest" BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE "CustomerOrder" ADD COLUMN "userId" TEXT;

-- CreateIndex
CREATE INDEX "CustomerOrder_email_idx" ON "CustomerOrder"("email");
CREATE INDEX "CustomerOrder_userId_idx" ON "CustomerOrder"("userId");

-- AddForeignKey
ALTER TABLE "CustomerOrder" ADD CONSTRAINT "CustomerOrder_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
