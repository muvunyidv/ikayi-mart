import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  await prisma.payment.deleteMany();
  await prisma.supportTicket.deleteMany();
  await prisma.orderLineItem.deleteMany();
  await prisma.customerOrder.deleteMany();
  await prisma.productVariant.deleteMany();
  await prisma.product.deleteMany();
  await prisma.vendor.deleteMany();
  await prisma.user.deleteMany();

  const password = await bcrypt.hash('VendorPass123!', 12);
  const adminPassword = await bcrypt.hash('AdminPass123!', 12);

  await prisma.user.create({
    data: {
      email: 'admin@ikayi.rw',
      password: adminPassword,
      name: 'IKAYI Admin',
      role: UserRole.ADMIN,
    },
  });

  await prisma.user.create({
    data: {
      email: 'jean.paul@kigalitech.rw',
      password,
      name: 'Jean Paul K.',
      role: UserRole.VENDOR,
      vendor: {
        create: {
          storeName: 'Kigali Tech Store',
          isVerified: true,
          isOnline: true,
        },
      },
    },
  });

  console.log('Seeded empty IKAYI MART database (accounts only).');
  console.log('Vendor login: jean.paul@kigalitech.rw / VendorPass123!');
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
