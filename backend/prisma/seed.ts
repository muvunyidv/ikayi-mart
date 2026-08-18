import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

/** Matches `AuthService` (`bcrypt.hash(..., 12)`). */
const BCRYPT_ROUNDS = 12;

const TEST_VENDOR_EMAIL = 'vendor@ikayi.app';
const TEST_VENDOR_PASSWORD = 'vendor123456';
const TEST_STORE_NAME = 'IKAYI Test Store';

async function upsertVendorAccount(params: {
  email: string;
  password: string;
  name: string;
  storeName: string;
  isVerified?: boolean;
}) {
  const passwordHash = await bcrypt.hash(params.password, BCRYPT_ROUNDS);

  const user = await prisma.user.upsert({
    where: { email: params.email },
    update: {
      password: passwordHash,
      name: params.name,
      role: UserRole.VENDOR,
    },
    create: {
      email: params.email,
      password: passwordHash,
      name: params.name,
      role: UserRole.VENDOR,
    },
  });

  await prisma.vendor.upsert({
    where: { userId: user.id },
    update: {
      storeName: params.storeName,
      isVerified: params.isVerified ?? true,
      isOnline: true,
    },
    create: {
      userId: user.id,
      storeName: params.storeName,
      isVerified: params.isVerified ?? true,
      isOnline: true,
    },
  });

  return user;
}

async function upsertAdminAccount() {
  const passwordHash = await bcrypt.hash('AdminPass123!', BCRYPT_ROUNDS);

  await prisma.user.upsert({
    where: { email: 'admin@ikayi.rw' },
    update: {
      password: passwordHash,
      name: 'IKAYI Admin',
      role: UserRole.ADMIN,
    },
    create: {
      email: 'admin@ikayi.rw',
      password: passwordHash,
      name: 'IKAYI Admin',
      role: UserRole.ADMIN,
    },
  });
}

async function main() {
  await upsertAdminAccount();

  await upsertVendorAccount({
    email: TEST_VENDOR_EMAIL,
    password: TEST_VENDOR_PASSWORD,
    name: 'IKAYI Test Vendor',
    storeName: TEST_STORE_NAME,
    isVerified: true,
  });

  await upsertVendorAccount({
    email: 'jean.paul@kigalitech.rw',
    password: 'VendorPass123!',
    name: 'Jean Paul K.',
    storeName: 'Kigali Tech Store',
    isVerified: true,
  });

  console.log('Seed complete (idempotent upserts, no data wiped).');
  console.log(`Vendor login: ${TEST_VENDOR_EMAIL} / ${TEST_VENDOR_PASSWORD}`);
  console.log('Admin login:  admin@ikayi.rw / AdminPass123!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
