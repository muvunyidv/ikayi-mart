import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { OrdersService } from '../orders/orders.service';
import { JOB_EXPIRE_STOCK_HOLD, QUEUE_STOCK_HOLDS } from '../common/constants';

@Processor(QUEUE_STOCK_HOLDS)
export class StockHoldProcessor extends WorkerHost {
  private readonly logger = new Logger(StockHoldProcessor.name);

  constructor(private readonly orders: OrdersService) {
    super();
  }

  async process(job: Job<{ orderId: string }>): Promise<void> {
    if (job.name !== JOB_EXPIRE_STOCK_HOLD) return;
    this.logger.log(`Expiring unpaid stock hold for order ${job.data.orderId}`);
    await this.orders.restoreStockIfUnpaid(job.data.orderId);
  }
}
