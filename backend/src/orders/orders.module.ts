import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrdersGateway } from './orders.gateway';
import { QUEUE_NOTIFICATIONS, QUEUE_STOCK_HOLDS } from '../common/constants';
import { AuthModule } from '../auth/auth.module';
import { StockHoldProcessor } from '../queues/stock-hold.processor';
import { NotificationProcessor } from '../queues/notification.processor';

@Module({
  imports: [
    AuthModule,
    BullModule.registerQueue(
      { name: QUEUE_STOCK_HOLDS },
      { name: QUEUE_NOTIFICATIONS },
    ),
  ],
  controllers: [OrdersController],
  providers: [OrdersService, OrdersGateway, StockHoldProcessor, NotificationProcessor],
  exports: [OrdersService, OrdersGateway],
})
export class OrdersModule {}
