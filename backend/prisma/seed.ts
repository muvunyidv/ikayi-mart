import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

/** Matches `AuthService` (`bcrypt.hash(..., 12)`). */
const BCRYPT_ROUNDS = 12;

const TEST_VENDOR_EMAIL = 'vendor@ikayi.app';
const TEST_VENDOR_PASSWORD = 'vendor123456';
const TEST_STORE_NAME = 'IKAYI Test Store';

function slugify(value: string): string {
  const slug = value
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
  return slug.length > 0 ? slug : `store-${Date.now()}`;
}

async function uniqueStoreSlug(storeName: string, excludeUserId?: string) {
  const base = slugify(storeName);
  let slug = base;
  let i = 2;
  while (true) {
    const found = await prisma.vendor.findUnique({ where: { slug } });
    if (!found || found.userId === excludeUserId) return slug;
    slug = `${base}-${i}`;
    i += 1;
  }
}

async function upsertVendorAccount(params: {
  email: string;
  password: string;
  name: string;
  storeName: string;
  isVerified?: boolean;
  description?: string;
  phone?: string;
}) {
  const passwordHash = await bcrypt.hash(params.password, BCRYPT_ROUNDS);

  const user = await prisma.user.upsert({
    where: { email: params.email },
    update: {
      password: passwordHash,
      name: params.name,
      role: UserRole.VENDOR,
      phone: params.phone,
    },
    create: {
      email: params.email,
      password: passwordHash,
      name: params.name,
      role: UserRole.VENDOR,
      phone: params.phone,
    },
  });

  const slug = await uniqueStoreSlug(params.storeName, user.id);

  await prisma.vendor.upsert({
    where: { userId: user.id },
    update: {
      storeName: params.storeName,
      slug,
      description: params.description,
      phone: params.phone,
      contactEmail: params.email,
      isVerified: params.isVerified ?? true,
      isOnline: true,
    },
    create: {
      userId: user.id,
      storeName: params.storeName,
      slug,
      description: params.description,
      phone: params.phone,
      contactEmail: params.email,
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
    description:
      'Official IKAYI marketplace test store — electronics, apparel, and everyday essentials for Kigali shoppers.',
    phone: '+250788000001',
  });

  await upsertVendorAccount({
    email: 'jean.paul@kigalitech.rw',
    password: 'VendorPass123!',
    name: 'Jean Paul K.',
    storeName: 'Kigali Tech Store',
    isVerified: true,
    description:
      'Consumer electronics and accessories from Kigali. Fast 60-minute delivery across Gasabo, Kicukiro & Nyarugenge.',
    phone: '+250788000002',
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
