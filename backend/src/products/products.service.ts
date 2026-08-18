import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from '../auth/types/jwt-payload';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { QueryProductsDto } from './dto/query-products.dto';
import { productInclude, toProductResponse } from './product.mapper';
import { slugify } from '../common/utils/ids';

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async findPublic(query: QueryProductsDto) {
    const limit = query.limit ?? 20;
    const offset = query.offset ?? 0;
    const where: Prisma.ProductWhereInput = { isActive: true };

    if (query.category && query.category !== 'All') {
      where.category = query.category;
    }

    if (query.search?.trim()) {
      const q = query.search.trim();
      where.OR = [
        { name: { contains: q, mode: 'insensitive' } },
        { category: { contains: q, mode: 'insensitive' } },
        { vendor: { storeName: { contains: q, mode: 'insensitive' } } },
      ];
    }

    const [items, total] = await this.prisma.$transaction([
      this.prisma.product.findMany({
        where,
        include: productInclude,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.product.count({ where }),
    ]);

    return {
      items: items.map(toProductResponse),
      total,
      limit,
      offset,
    };
  }

  async findMine(user: JwtPayload) {
    const vendorId = this.requireVendorId(user);
    const items = await this.prisma.product.findMany({
      where: { vendorId },
      include: productInclude,
      orderBy: { createdAt: 'desc' },
    });
    return {
      items: items.map(toProductResponse),
      total: items.length,
    };
  }

  async findByIdOrSlug(idOrSlug: string) {
    const product = await this.prisma.product.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
        isActive: true,
      },
      include: productInclude,
    });
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    return toProductResponse(product);
  }

  async create(user: JwtPayload, dto: CreateProductDto) {
    const vendorId = this.requireVendorId(user);
    const slug = await this.uniqueSlug(slugify(dto.name));

    const product = await this.prisma.product.create({
      data: {
        vendorId,
        slug,
        name: dto.name.trim(),
        category: dto.category.trim(),
        priceRwf: dto.priceRwf,
        stock: dto.stock,
        imageUrl: dto.imageUrl,
        description: dto.description.trim(),
        badge: dto.badge?.trim(),
        originLabel: dto.originLabel?.trim(),
        gallery: dto.gallery ?? [],
        variants: dto.variants
          ? {
              create: dto.variants.map((v) => ({
                name: v.name.trim(),
                options: v.options.map((o) => o.trim()),
              })),
            }
          : undefined,
      },
      include: productInclude,
    });

    return toProductResponse(product);
  }

  async update(user: JwtPayload, id: string, dto: UpdateProductDto) {
    const existing = await this.requireOwnedProduct(user, id);

    if (dto.priceRwf !== undefined && !Number.isInteger(dto.priceRwf)) {
      throw new BadRequestException('priceRwf must be an integer (RWF)');
    }

    const slug =
      dto.name && dto.name.trim() !== existing.name
        ? await this.uniqueSlug(slugify(dto.name), id)
        : undefined;

    const product = await this.prisma.$transaction(async (tx) => {
      if (dto.variants) {
        await tx.productVariant.deleteMany({ where: { productId: id } });
      }
      return tx.product.update({
        where: { id },
        data: {
          slug,
          name: dto.name?.trim(),
          category: dto.category?.trim(),
          priceRwf: dto.priceRwf,
          stock: dto.stock,
          imageUrl: dto.imageUrl,
          description: dto.description?.trim(),
          badge: dto.badge?.trim(),
          originLabel: dto.originLabel?.trim(),
          gallery: dto.gallery,
          variants: dto.variants
            ? {
                create: dto.variants.map((v) => ({
                  name: v.name.trim(),
                  options: v.options.map((o) => o.trim()),
                })),
              }
            : undefined,
        },
        include: productInclude,
      });
    });

    return toProductResponse(product);
  }

  async toggleStatus(user: JwtPayload, id: string, isActive: boolean) {
    await this.requireOwnedProduct(user, id);
    const product = await this.prisma.product.update({
      where: { id },
      data: { isActive },
      include: productInclude,
    });
    return toProductResponse(product);
  }

  async remove(user: JwtPayload, id: string) {
    await this.requireOwnedProduct(user, id);
    try {
      await this.prisma.product.delete({ where: { id } });
    } catch {
      throw new BadRequestException(
        'Product cannot be deleted because it is referenced by existing orders. Deactivate it instead.',
      );
    }
    return { deleted: true, id };
  }

  private requireVendorId(user: JwtPayload): string {
    if (user.role === UserRole.ADMIN && !user.vendorId) {
      throw new ForbiddenException('Admin accounts without a vendor profile cannot manage products');
    }
    if (!user.vendorId) {
      throw new ForbiddenException('Vendor profile required');
    }
    return user.vendorId;
  }

  private async requireOwnedProduct(user: JwtPayload, id: string) {
    const product = await this.prisma.product.findUnique({ where: { id } });
    if (!product) {
      throw new NotFoundException('Product not found');
    }
    if (user.role !== UserRole.ADMIN && product.vendorId !== user.vendorId) {
      throw new ForbiddenException('You cannot modify another vendor’s product');
    }
    return product;
  }

  private async uniqueSlug(base: string, excludeId?: string): Promise<string> {
    let slug = base;
    let i = 2;
    while (true) {
      const found = await this.prisma.product.findUnique({ where: { slug } });
      if (!found || found.id === excludeId) {
        return slug;
      }
      slug = `${base}-${i}`;
      i += 1;
    }
  }
}
