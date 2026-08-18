import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { MockPaymentGateway } from './gateways/mock-payment.gateway';
import { MtnMomoGateway } from './gateways/mtn-momo.gateway';
import { AirtelMoneyGateway } from './gateways/airtel-money.gateway';
import { PaymentWebhookProcessor } from './processors/payment-webhook.processor';
import { QUEUE_PAYMENTS, QUEUE_STOCK_HOLDS } from '../common/constants';
import { OrdersModule } from '../orders/orders.module';

@Module({
  imports: [
    OrdersModule,
    BullModule.registerQueue({ name: QUEUE_PAYMENTS }, { name: QUEUE_STOCK_HOLDS }),
  ],
  controllers: [PaymentsController],
  providers: [
    PaymentsService,
    MockPaymentGateway,
    MtnMomoGateway,
    AirtelMoneyGateway,
    PaymentWebhookProcessor,
  ],
})
export class PaymentsModule {}
