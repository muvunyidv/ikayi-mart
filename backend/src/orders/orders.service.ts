import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  Prisma,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from '../auth/types/jwt-payload';
import { GuestCheckoutDto } from './dto/guest-checkout.dto';
import { OrdersGateway } from './orders.gateway';
import { generateTrackingCode } from '../common/utils/ids';
import { normalizeRwandaPhone } from '../common/utils/rwanda-phone';
import { isMockPaymentMode } from '../common/utils/payment-mode';
import { randomUUID } from 'crypto';
import {
  DEFAULT_DELIVERY_FEE_RWF,
  JOB_EXPIRE_STOCK_HOLD,
  JOB_NOTIFY_VENDOR,
  QUEUE_NOTIFICATIONS,
  QUEUE_STOCK_HOLDS,
} from '../common/constants';

const ORDER_INCLUDE = {
  items: {
    include: {
      product: { select: { id: true, name: true, imageUrl: true } },
      vendor: { select: { id: true, storeName: true } },
    },
  },
  supportTicket: true,
} satisfies Prisma.CustomerOrderInclude;

type OrderWithItems = Prisma.CustomerOrderGetPayload<{ include: typeof ORDER_INCLUDE }>;

const STATUS_FLOW: Record<OrderStatus, OrderStatus[]> = {
  PENDING: [OrderStatus.PROCESSING, OrderStatus.CANCELLED],
  PROCESSING: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
  SHIPPED: [OrderStatus.DELIVERED],
  DELIVERED: [OrderStatus.ISSUE_REPORTED],
  ISSUE_REPORTED: [OrderStatus.PROCESSING, OrderStatus.DELIVERED],
  CANCELLED: [],
};

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly gateway: OrdersGateway,
    private readonly config: ConfigService,
    @InjectQueue(QUEUE_STOCK_HOLDS) private readonly stockHolds: Queue,
    @InjectQueue(QUEUE_NOTIFICATIONS) private readonly notifications: Queue,
  ) {}

  async guestCheckout(dto: GuestCheckoutDto) {
    if (dto.isGuest === false) {
      throw new UnauthorizedException(
        'Sign in is required when isGuest is false',
      );
    }

    const phone = normalizeRwandaPhone(dto.phone);
    if (!phone) {
      throw new BadRequestException(
        'Enter a valid Rwanda phone number (+250 7XX XXX XXX or 07XX XXX XXX)',
      );
    }

    const deliveryFeeRwf = Number(
      this.config.get('DEFAULT_DELIVERY_FEE_RWF') ?? DEFAULT_DELIVERY_FEE_RWF,
    );
    const paymentMethod = dto.paymentMethod ?? PaymentMethod.MTN_MOMO;

    const merged = this.mergeLineItems(dto.items);
    const productIds = merged.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } },
      include: { vendor: true, variants: true },
    });

    if (products.length !== productIds.length) {
      throw new BadRequestException('One or more products were not found');
    }

    const productMap = new Map(products.map((p) => [p.id, p]));
    for (const item of merged) {
      const product = productMap.get(item.productId)!;
      if (!product.isActive) {
        throw new BadRequestException(`${product.name} is not available`);
      }
      if (product.stock < item.quantity) {
        throw new BadRequestException(
          `Insufficient stock for ${product.name} (available: ${product.stock})`,
        );
      }
      this.assertVariants(product.variants, item.selectedVariants);
    }

    const itemsTotal = merged.reduce((sum, item) => {
      const product = productMap.get(item.productId)!;
      return sum + product.priceRwf * item.quantity;
    }, 0);
    const totalAmountRwf = itemsTotal + deliveryFeeRwf;

    const order = await this.prisma.$transaction(async (tx) => {
      for (const item of merged) {
        const product = productMap.get(item.productId)!;
        const updated = await tx.product.updateMany({
          where: {
            id: product.id,
            stock: { gte: item.quantity },
            isActive: true,
          },
          data: { stock: { decrement: item.quantity } },
        });
        if (updated.count !== 1) {
          throw new BadRequestException(`Insufficient stock for ${product.name}`);
        }
      }

      const trackingCode = await this.allocateTrackingCode(tx);
      return tx.customerOrder.create({
        data: {
          trackingCode,
          guestName: dto.guestName.trim(),
          email: dto.email.toLowerCase().trim(),
          phone,
          district: dto.district.trim(),
          sector: dto.sector.trim(),
          landmark: dto.landmark.trim(),
          deliveryFeeRwf,
          totalAmountRwf,
          status: OrderStatus.PENDING,
          paymentMethod,
          paymentStatus: PaymentStatus.PENDING,
          isGuest: true,
          items: {
            create: merged.map((item) => {
              const product = productMap.get(item.productId)!;
              return {
                productId: product.id,
                vendorId: product.vendorId,
                quantity: item.quantity,
                unitPriceRwf: product.priceRwf,
                selectedVariants: item.selectedVariants ?? Prisma.JsonNull,
              };
            }),
          },
        },
        include: ORDER_INCLUDE,
      });
    });

    const mockPayments = isMockPaymentMode(this.config);
    if (mockPayments) {
      await this.prisma.payment.create({
        data: {
          orderId: order.id,
          method: paymentMethod,
          status: PaymentStatus.SUCCESSFUL,
          amountRwf: order.totalAmountRwf,
          phone,
          providerRef: `MOCK-${paymentMethod}-${randomUUID()}`,
        },
      });
      await this.prisma.customerOrder.update({
        where: { id: order.id },
        data: { paymentStatus: PaymentStatus.SUCCESSFUL },
      });
    } else {
      const ttlSeconds = Number(this.config.get('STOCK_HOLD_TTL_SECONDS') ?? 900);
      try {
        await this.stockHolds.add(
          JOB_EXPIRE_STOCK_HOLD,
          { orderId: order.id },
          { delay: ttlSeconds * 1000, removeOnComplete: true, jobId: `hold-${order.id}` },
        );
      } catch (err) {
        this.logger.warn(`Stock-hold queue unavailable: ${err}`);
      }
    }

    const vendorIds = [...new Set(order.items.map((i) => i.vendorId))];
    for (const vendorId of vendorIds) {
      const payload = {
        orderId: order.id,
        trackingCode: order.trackingCode,
        guestName: order.guestName,
        status: order.status,
        paymentStatus: mockPayments ? PaymentStatus.SUCCESSFUL : order.paymentStatus,
        totalAmountRwf: order.totalAmountRwf,
        createdAt: order.createdAt,
      };
      this.gateway.notifyNewOrder(vendorId, payload);
      try {
        await this.notifications.add(JOB_NOTIFY_VENDOR, { vendorId, ...payload });
      } catch (err) {
        this.logger.warn(`Vendor notify queue unavailable: ${err}`);
      }
    }

    this.logger.log(`Guest order ${order.trackingCode} created`);

    return {
      trackingCode: order.trackingCode,
      orderId: order.id,
      status: order.status,
      paymentStatus: mockPayments ? PaymentStatus.SUCCESSFUL : order.paymentStatus,
      paymentMethod: order.paymentMethod,
      deliveryFeeRwf: order.deliveryFeeRwf,
      itemsTotalRwf: itemsTotal,
      totalAmountRwf: order.totalAmountRwf,
      phone: order.phone,
      email: order.email,
      isGuest: order.isGuest,
      userId: order.userId,
      payment: {
        requiresUssdPush: !mockPayments && paymentMethod !== PaymentMethod.VISA_CARD,
        initiateUrl: '/api/v1/payments/initiate',
        amountRwf: order.totalAmountRwf,
        currency: 'RWF',
        testMode: mockPayments,
      },
    };
  }

  async track(code: string) {
    const trackingCode = code.replace(/^#/, '').toUpperCase();
    const order = await this.prisma.customerOrder.findUnique({
      where: { trackingCode },
      include: ORDER_INCLUDE,
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }
    return this.toPublicOrder(order);
  }

  async listForCustomer(user: JwtPayload) {
    const orders = await this.prisma.customerOrder.findMany({
      where: { userId: user.sub },
      include: ORDER_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });
    return orders.map((order) => this.toPublicOrder(order));
  }

  async claimForUser(user: JwtPayload, orderId: string) {
    const order = await this.prisma.customerOrder.findUnique({
      where: { id: orderId },
      include: ORDER_INCLUDE,
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const orderEmail = (order.email ?? '').toLowerCase().trim();
    if (!orderEmail || orderEmail !== user.email.toLowerCase().trim()) {
      throw new BadRequestException('This order belongs to a different email');
    }

    if (order.userId && order.userId !== user.sub) {
      throw new ForbiddenException('This order is already linked to another account');
    }

    const updated = await this.prisma.customerOrder.update({
      where: { id: orderId },
      data: { userId: user.sub, isGuest: false },
      include: ORDER_INCLUDE,
    });
    return this.toPublicOrder(updated);
  }

  async listForVendor(user: JwtPayload, status?: OrderStatus) {
    const vendorId = this.requireVendorId(user);
    const orders = await this.prisma.customerOrder.findMany({
      where: {
        items: { some: { vendorId } },
        ...(status ? { status } : {}),
      },
      include: ORDER_INCLUDE,
      orderBy: { createdAt: 'desc' },
    });

    return orders.map((order) => this.toVendorOrder(order, vendorId));
  }

  async updateStatus(user: JwtPayload, orderId: string, next: OrderStatus) {
    const vendorId = this.requireVendorId(user);
    const order = await this.prisma.customerOrder.findUnique({
      where: { id: orderId },
      include: { items: true },
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const belongs = order.items.some((i) => i.vendorId === vendorId);
    if (user.role !== UserRole.ADMIN && !belongs) {
      throw new ForbiddenException('You cannot update another vendor’s order');
    }

    const allowed = STATUS_FLOW[order.status];
    if (!allowed.includes(next) && user.role !== UserRole.ADMIN) {
      throw new BadRequestException(
        `Cannot move order from ${order.status} to ${next}`,
      );
    }

    const updated = await this.prisma.customerOrder.update({
      where: { id: orderId },
      data: { status: next },
      include: ORDER_INCLUDE,
    });

    for (const id of [...new Set(updated.items.map((i) => i.vendorId))]) {
      this.gateway.notifyOrderUpdated(id, {
        orderId: updated.id,
        trackingCode: updated.trackingCode,
        status: updated.status,
      });
    }

    return this.toVendorOrder(updated, vendorId);
  }

  async restoreStockIfUnpaid(orderId: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const order = await tx.customerOrder.findUnique({
        where: { id: orderId },
        include: { items: true },
      });
      if (!order) return;
      if (order.paymentStatus !== PaymentStatus.PENDING) return;
      if (order.status === OrderStatus.CANCELLED) return;

      for (const item of order.items) {
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: { increment: item.quantity } },
        });
      }

      await tx.customerOrder.update({
        where: { id: orderId },
        data: {
          status: OrderStatus.CANCELLED,
          paymentStatus: PaymentStatus.FAILED,
        },
      });
    });
  }

  private toPublicOrder(order: OrderWithItems) {
    return {
      id: order.id,
      trackingCode: order.trackingCode,
      guestName: order.guestName,
      email: order.email,
      phone: order.phone,
      district: order.district,
      sector: order.sector,
      landmark: order.landmark,
      locationLabel: `${order.sector}, ${order.district}`,
      deliveryFeeRwf: order.deliveryFeeRwf,
      totalAmountRwf: order.totalAmountRwf,
      status: order.status,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      isGuest: order.isGuest,
      userId: order.userId,
      createdAt: order.createdAt,
      items: order.items.map((i) => ({
        productName: i.product.name,
        quantity: i.quantity,
        unitPriceRwf: i.unitPriceRwf,
        selectedVariants: i.selectedVariants,
        vendorName: i.vendor.storeName,
      })),
      supportTicket: order.supportTicket
        ? {
            id: order.supportTicket.id,
            issue: order.supportTicket.issue,
            resolution: order.supportTicket.resolution,
            isResolved: order.supportTicket.isResolved,
          }
        : null,
    };
  }

  private toVendorOrder(order: OrderWithItems, vendorId: string) {
    const items = order.items.filter(
      (i) => i.vendorId === vendorId || true,
    );
    return {
      ...this.toPublicOrder(order),
      items: items.map((i) => ({
        id: i.id,
        productId: i.productId,
        productName: i.product.name,
        imageUrl: i.product.imageUrl,
        quantity: i.quantity,
        unitPriceRwf: i.unitPriceRwf,
        selectedVariants: i.selectedVariants,
        vendorId: i.vendorId,
        vendorName: i.vendor.storeName,
        mine: i.vendorId === vendorId,
      })),
    };
  }

  private mergeLineItems(items: GuestCheckoutDto['items']) {
    const map = new Map<string, GuestCheckoutDto['items'][number]>();
    for (const item of items) {
      const key = `${item.productId}:${JSON.stringify(item.selectedVariants ?? {})}`;
      const existing = map.get(key);
      if (existing) {
        existing.quantity += item.quantity;
      } else {
        map.set(key, { ...item });
      }
    }
    return [...map.values()];
  }

  private assertVariants(
    variants: Array<{ name: string; options: string[] }>,
    selected?: Record<string, string>,
  ) {
    if (!selected) return;
    for (const [name, option] of Object.entries(selected)) {
      const variant = variants.find((v) => v.name === name);
      if (!variant || !variant.options.includes(option)) {
        throw new BadRequestException(`Invalid variant ${name}=${option}`);
      }
    }
  }

  private async allocateTrackingCode(tx: Prisma.TransactionClient): Promise<string> {
    for (let attempt = 0; attempt < 12; attempt += 1) {
      const code = generateTrackingCode();
      const exists = await tx.customerOrder.findUnique({
        where: { trackingCode: code },
        select: { id: true },
      });
      if (!exists) return code;
    }
    throw new BadRequestException('Could not allocate a tracking code');
  }

  private requireVendorId(user: JwtPayload): string {
    if (user.role === UserRole.ADMIN && user.vendorId) {
      return user.vendorId;
    }
    if (!user.vendorId) {
      throw new ForbiddenException('Vendor profile required');
    }
    return user.vendorId;
  }
}
