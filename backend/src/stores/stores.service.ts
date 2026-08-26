import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { UserRole, Vendor } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from '../auth/types/jwt-payload';
import { productInclude, toProductResponse } from '../products/product.mapper';
import { uniqueSlug } from '../common/utils/ids';
import { CreateStoreDto } from './dto/create-store.dto';
import { UpdateStoreDto } from './dto/update-store.dto';

@Injectable()
export class StoresService {
  constructor(private readonly prisma: PrismaService) {}

  async allocateSlug(storeName: string, excludeId?: string): Promise<string> {
    return uniqueSlug(storeName, async (slug) => {
      const found = await this.prisma.vendor.findUnique({ where: { slug } });
      return Boolean(found && found.id !== excludeId);
    });
  }

  resolveContact(
    dto: Pick<CreateStoreDto, 'description' | 'contactInfo' | 'phone' | 'contactEmail'>,
    fallbacks?: { phone?: string | null; email?: string | null },
  ) {
    const phone =
      dto.contactInfo?.phone?.trim() ||
      dto.phone?.trim() ||
      fallbacks?.phone ||
      null;
    const contactEmail =
      dto.contactInfo?.email?.trim().toLowerCase() ||
      dto.contactEmail?.trim().toLowerCase() ||
      fallbacks?.email ||
      null;
    const description = dto.description?.trim() || null;
    return { phone, contactEmail, description };
  }

  async findPublicBySlug(slug: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { slug },
      include: {
        user: { select: { email: true, phone: true } },
        products: {
          where: { isActive: true },
          include: productInclude,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!vendor) {
      throw new NotFoundException('Store not found');
    }
    return this.toPublicStore(vendor);
  }

  async findMine(user: JwtPayload) {
    const vendorId = this.requireVendorId(user);
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        user: { select: { email: true, phone: true } },
        products: {
          where: { isActive: true },
          include: productInclude,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
    if (!vendor) {
      throw new NotFoundException('Store not found');
    }
    return this.toPublicStore(vendor);
  }

  async updateMine(user: JwtPayload, dto: UpdateStoreDto) {
    const vendorId = this.requireVendorId(user);
    const existing = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: { user: { select: { email: true, phone: true } } },
    });
    if (!existing) {
      throw new NotFoundException('Store not found');
    }

    const storeName = dto.storeName?.trim() || existing.storeName;
    const slug =
      dto.storeName && dto.storeName.trim() !== existing.storeName
        ? await this.allocateSlug(storeName, existing.id)
        : existing.slug;
    const contact = this.resolveContact(dto, {
      phone: existing.phone ?? existing.user.phone,
      email: existing.contactEmail ?? existing.user.email,
    });

    const vendor = await this.prisma.vendor.update({
      where: { id: vendorId },
      data: {
        storeName,
        slug,
        description:
          dto.description !== undefined ? contact.description : existing.description,
        phone: dto.contactInfo?.phone !== undefined || dto.phone !== undefined
          ? contact.phone
          : existing.phone,
        contactEmail:
          dto.contactInfo?.email !== undefined || dto.contactEmail !== undefined
            ? contact.contactEmail
            : existing.contactEmail,
      },
      include: {
        user: { select: { email: true, phone: true } },
        products: {
          where: { isActive: true },
          include: productInclude,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    return this.toPublicStore(vendor);
  }

  private toPublicStore(
    vendor: Vendor & {
      user: { email: string; phone: string | null };
      products: Parameters<typeof toProductResponse>[0][];
    },
  ) {
    const products = vendor.products.map(toProductResponse);
    const categories = [
      ...new Set(products.map((p) => p.category).filter((c) => c.length > 0)),
    ].sort((a, b) => a.localeCompare(b));

    return {
      id: vendor.id,
      storeName: vendor.storeName,
      slug: vendor.slug,
      description: vendor.description,
      phone: vendor.phone ?? vendor.user.phone,
      contactEmail: vendor.contactEmail ?? vendor.user.email,
      isVerified: vendor.isVerified,
      isOnline: vendor.isOnline,
      categories,
      products,
      productCount: products.length,
    };
  }

  private requireVendorId(user: JwtPayload): string {
    if (user.role === UserRole.ADMIN && !user.vendorId) {
      throw new ForbiddenException(
        'Admin accounts without a vendor profile cannot manage a store',
      );
    }
    if (!user.vendorId) {
      throw new ForbiddenException('Vendor profile required');
    }
    return user.vendorId;
  }
}
