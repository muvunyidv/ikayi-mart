import { Prisma, Product, ProductVariant, Vendor } from '@prisma/client';
import {
  LOW_STOCK_THRESHOLD,
  PRODUCT_DELIVERY_NOTE,
  PRODUCT_WARRANTY_NOTE,
} from '../common/constants';

type ProductWithRelations = Product & {
  vendor: Pick<Vendor, 'id' | 'storeName' | 'slug'>;
  variants: ProductVariant[];
};

export function toProductResponse(product: ProductWithRelations) {
  return {
    id: product.id,
    slug: product.slug,
    name: product.name,
    category: product.category,
    priceRwf: product.priceRwf,
    stock: product.stock,
    imageUrl: product.imageUrl,
    vendorId: product.vendor.id,
    vendorName: product.vendor.storeName,
    vendorSlug: product.vendor.slug,
    description: product.description,
    badge: product.badge,
    originLabel: product.originLabel,
    gallery: product.gallery,
    isActive: product.isActive,
    isLowStock: product.stock > 0 && product.stock <= LOW_STOCK_THRESHOLD,
    inStock: product.stock > 0,
    variants: product.variants.map((v) => ({
      id: v.id,
      name: v.name,
      options: v.options,
    })),
    deliveryNote: PRODUCT_DELIVERY_NOTE,
    warrantyNote: PRODUCT_WARRANTY_NOTE,
    createdAt: product.createdAt,
    updatedAt: product.updatedAt,
  };
}

export const productInclude = {
  vendor: { select: { id: true, storeName: true, slug: true } },
  variants: true,
} satisfies Prisma.ProductInclude;
