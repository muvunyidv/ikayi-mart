import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { OrderStatus, PaymentMethod, PaymentStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';
import { MockPaymentGateway } from './gateways/mock-payment.gateway';
import { MtnMomoGateway } from './gateways/mtn-momo.gateway';
import { AirtelMoneyGateway } from './gateways/airtel-money.gateway';
import { PaymentGateway } from './gateways/payment-gateway.interface';
import { OrdersGateway } from '../orders/orders.gateway';
import { normalizeRwandaPhone } from '../common/utils/rwanda-phone';
import { JOB_PROCESS_WEBHOOK, QUEUE_PAYMENTS, QUEUE_STOCK_HOLDS } from '../common/constants';
import { isMockPaymentMode } from '../common/utils/payment-mode';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly mock: MockPaymentGateway,
    private readonly mtn: MtnMomoGateway,
    private readonly airtel: AirtelMoneyGateway,
    private readonly ordersGateway: OrdersGateway,
    @InjectQueue(QUEUE_PAYMENTS) private readonly paymentsQueue: Queue,
    @InjectQueue(QUEUE_STOCK_HOLDS) private readonly stockHolds: Queue,
  ) {}

  async initiate(dto: InitiatePaymentDto) {
    if (!dto.orderId && !dto.trackingCode) {
      throw new BadRequestException('Provide orderId or trackingCode');
    }

    const order = await this.prisma.customerOrder.findFirst({
      where: dto.orderId
        ? { id: dto.orderId }
        : { trackingCode: dto.trackingCode!.replace(/^#/, '').toUpperCase() },
      include: { items: true, payments: { orderBy: { createdAt: 'desc' }, take: 1 } },
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }
    if (order.paymentStatus === PaymentStatus.SUCCESSFUL) {
      const existing = order.payments[0];
      return {
        paymentId: existing?.id ?? null,
        orderId: order.id,
        trackingCode: order.trackingCode,
        amountRwf: order.totalAmountRwf,
        currency: 'RWF',
        method: existing?.method ?? order.paymentMethod,
        providerRef: existing?.providerRef ?? null,
        ussdPushSent: false,
        message: 'Payment already confirmed',
        testMode: isMockPaymentMode(this.config),
      };
    }

    const method = dto.method ?? order.paymentMethod;
    const phoneRaw = dto.phone ?? order.phone;
    const phone = normalizeRwandaPhone(phoneRaw);
    if (!phone) {
      throw new BadRequestException('Enter a valid Rwanda phone number for MoMo / Airtel');
    }

    const mock = isMockPaymentMode(this.config);
    const gateway = this.pickGateway(method);
    const result = await gateway.initiate({
      orderId: order.id,
      trackingCode: order.trackingCode,
      amountRwf: order.totalAmountRwf,
      phone,
      method,
    });

    const payment = await this.prisma.payment.create({
      data: {
        orderId: order.id,
        method,
        status: mock ? PaymentStatus.SUCCESSFUL : PaymentStatus.PENDING,
        amountRwf: order.totalAmountRwf,
        phone,
        providerRef: result.providerRef,
      },
    });

    await this.prisma.customerOrder.update({
      where: { id: order.id },
      data: {
        paymentMethod: method,
        paymentStatus: mock ? PaymentStatus.SUCCESSFUL : PaymentStatus.PENDING,
      },
    });

    if (mock) {
      await this.stockHolds.remove(`hold-${order.id}`).catch(() => undefined);
      for (const vendorId of [...new Set(order.items.map((i) => i.vendorId))]) {
        this.ordersGateway.notifyOrderUpdated(vendorId, {
          orderId: order.id,
          trackingCode: order.trackingCode,
          paymentStatus: PaymentStatus.SUCCESSFUL,
          status: order.status,
        });
      }
    }

    return {
      paymentId: payment.id,
      orderId: order.id,
      trackingCode: order.trackingCode,
      amountRwf: order.totalAmountRwf,
      currency: 'RWF',
      method,
      providerRef: result.providerRef,
      ussdPushSent: mock ? false : result.ussdPushSent,
      message: mock
        ? `Test payment confirmed. Tracking code ${order.trackingCode}.`
        : result.message,
      testMode: mock,
    };
  }

  async enqueueWebhook(payload: Record<string, unknown>, signature?: string) {
    const secret = this.config.get<string>('WEBHOOK_SECRET');
    if (secret && signature && signature !== secret) {
      throw new UnauthorizedException('Invalid webhook signature');
    }

    const method = this.inferMethod(payload);
    const parsed = await this.pickGateway(method).parseWebhook(payload, signature);
    if (!parsed.providerRef) {
      throw new BadRequestException('Webhook missing provider reference');
    }

    await this.paymentsQueue.add(
      JOB_PROCESS_WEBHOOK,
      parsed,
      { removeOnComplete: true, jobId: `wh-${parsed.providerRef}` },
    );

    return { accepted: true };
  }

  async applyWebhookResult(data: {
    providerRef: string;
    status: 'SUCCESSFUL' | 'FAILED' | 'PENDING';
  }): Promise<void> {
    const payment = await this.prisma.payment.findUnique({
      where: { providerRef: data.providerRef },
      include: { order: { include: { items: true } } },
    });
    if (!payment) {
      this.logger.warn(`No payment for providerRef ${data.providerRef}`);
      return;
    }
    if (payment.status === PaymentStatus.SUCCESSFUL) {
      return;
    }

    const nextStatus =
      data.status === 'SUCCESSFUL'
        ? PaymentStatus.SUCCESSFUL
        : data.status === 'FAILED'
          ? PaymentStatus.FAILED
          : PaymentStatus.PENDING;

    await this.prisma.$transaction(async (tx) => {
      await tx.payment.update({
        where: { id: payment.id },
        data: { status: nextStatus },
      });
      await tx.customerOrder.update({
        where: { id: payment.orderId },
        data: {
          paymentStatus: nextStatus,
          status:
            nextStatus === PaymentStatus.FAILED
              ? OrderStatus.CANCELLED
              : payment.order.status,
        },
      });

      if (nextStatus === PaymentStatus.FAILED && payment.order.paymentStatus === PaymentStatus.PENDING) {
        for (const item of payment.order.items) {
          await tx.product.update({
            where: { id: item.productId },
            data: { stock: { increment: item.quantity } },
          });
        }
      }
    });

    if (nextStatus === PaymentStatus.SUCCESSFUL) {
      await this.stockHolds.remove(`hold-${payment.orderId}`).catch(() => undefined);
    }

    for (const vendorId of [...new Set(payment.order.items.map((i) => i.vendorId))]) {
      this.ordersGateway.notifyOrderUpdated(vendorId, {
        orderId: payment.orderId,
        trackingCode: payment.order.trackingCode,
        paymentStatus: nextStatus,
        status: nextStatus === PaymentStatus.FAILED ? OrderStatus.CANCELLED : payment.order.status,
      });
    }
  }

  private pickGateway(method: PaymentMethod): PaymentGateway {
    if (isMockPaymentMode(this.config)) {
      return this.mock;
    }
    if (method === PaymentMethod.AIRTEL_MONEY) {
      return this.airtel;
    }
    return this.mtn;
  }

  private inferMethod(payload: Record<string, unknown>): PaymentMethod {
    const raw = String(payload.method ?? payload.provider ?? '').toUpperCase();
    if (raw.includes('AIRTEL')) return PaymentMethod.AIRTEL_MONEY;
    if (raw.includes('VISA') || raw.includes('CARD')) return PaymentMethod.VISA_CARD;
    return PaymentMethod.MTN_MOMO;
  }
}
