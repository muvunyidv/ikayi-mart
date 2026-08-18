import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PaymentsService } from '../payments.service';
import { JOB_PROCESS_WEBHOOK, QUEUE_PAYMENTS } from '../../common/constants';

@Processor(QUEUE_PAYMENTS)
export class PaymentWebhookProcessor extends WorkerHost {
  private readonly logger = new Logger(PaymentWebhookProcessor.name);

  constructor(private readonly payments: PaymentsService) {
    super();
  }

  async process(job: Job): Promise<void> {
    if (job.name !== JOB_PROCESS_WEBHOOK) return;
    this.logger.log(`Processing payment webhook job ${job.id}`);
    await this.payments.applyWebhookResult(job.data as {
      providerRef: string;
      status: 'SUCCESSFUL' | 'FAILED' | 'PENDING';
    });
  }
}
