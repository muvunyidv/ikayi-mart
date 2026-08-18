import { ForbiddenException, Injectable } from '@nestjs/common';
import { OrderStatus, PaymentStatus, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from '../auth/types/jwt-payload';
import { LOW_STOCK_THRESHOLD } from '../common/constants';

const WEEKDAY = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as const;

@Injectable()
export class VendorDashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async kpis(user: JwtPayload) {
    const vendorId = this.requireVendorId(user);
    const startOfToday = this.startOfDay(new Date());
    const startOfWeek = this.startOfDay(this.daysAgo(6));

    const [pendingOrders, lowStock, completedWeek] = await Promise.all([
      this.prisma.customerOrder.count({
        where: {
          status: OrderStatus.PENDING,
          items: { some: { vendorId } },
        },
      }),
      this.prisma.product.count({
        where: {
          vendorId,
          isActive: true,
          stock: { gt: 0, lte: LOW_STOCK_THRESHOLD },
        },
      }),
      this.prisma.customerOrder.count({
        where: {
          status: OrderStatus.DELIVERED,
          createdAt: { gte: startOfWeek },
          items: { some: { vendorId } },
        },
      }),
    ]);

    const todayLines = await this.prisma.orderLineItem.findMany({
      where: {
        vendorId,
        order: {
          paymentStatus: PaymentStatus.SUCCESSFUL,
          createdAt: { gte: startOfToday },
          status: { not: OrderStatus.CANCELLED },
        },
      },
      select: { quantity: true, unitPriceRwf: true },
    });
    const todayRevenueRwf = todayLines.reduce(
      (sum, i) => sum + i.quantity * i.unitPriceRwf,
      0,
    );

    return {
      todayRevenueRwf,
      pendingOrders,
      lowStockItems: lowStock,
      completedOrders: completedWeek,
      currency: 'RWF',
    };
  }

  async chart(user: JwtPayload) {
    const vendorId = this.requireVendorId(user);
    const days = Array.from({ length: 7 }, (_, i) => this.startOfDay(this.daysAgo(6 - i)));
    const rangeStart = days[0];

    const lines = await this.prisma.orderLineItem.findMany({
      where: {
        vendorId,
        order: {
          paymentStatus: PaymentStatus.SUCCESSFUL,
          createdAt: { gte: rangeStart },
          status: { not: OrderStatus.CANCELLED },
        },
      },
      select: {
        quantity: true,
        unitPriceRwf: true,
        order: { select: { createdAt: true } },
      },
    });

    const buckets = days.map((d) => ({
      date: d.toISOString().slice(0, 10),
      label: WEEKDAY[d.getDay()],
      revenueRwf: 0,
    }));

    for (const line of lines) {
      const key = this.startOfDay(line.order.createdAt).toISOString().slice(0, 10);
      const bucket = buckets.find((b) => b.date === key);
      if (bucket) {
        bucket.revenueRwf += line.quantity * line.unitPriceRwf;
      }
    }

    return {
      series: buckets,
      values: buckets.map((b) => b.revenueRwf),
      labels: buckets.map((b) => b.label),
      currency: 'RWF',
    };
  }

  private requireVendorId(user: JwtPayload): string {
    if (!user.vendorId) {
      throw new ForbiddenException('Vendor profile required');
    }
    if (user.role !== UserRole.VENDOR && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Insufficient role');
    }
    return user.vendorId;
  }

  private startOfDay(date: Date): Date {
    const d = new Date(date);
    d.setHours(0, 0, 0, 0);
    return d;
  }

  private daysAgo(n: number): Date {
    const d = new Date();
    d.setDate(d.getDate() - n);
    return d;
  }
}
