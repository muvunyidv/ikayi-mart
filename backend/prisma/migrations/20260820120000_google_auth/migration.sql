-- AlterEnum
ALTER TYPE "UserRole" ADD VALUE 'CUSTOMER';

-- AlterTable
ALTER TABLE "User" ALTER COLUMN "password" DROP NOT NULL;
