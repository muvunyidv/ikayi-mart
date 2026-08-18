import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { JOB_NOTIFY_VENDOR, QUEUE_NOTIFICATIONS } from '../common/constants';

@Processor(QUEUE_NOTIFICATIONS)
export class NotificationProcessor extends WorkerHost {
  private readonly logger = new Logger(NotificationProcessor.name);

  async process(job: Job): Promise<void> {
    if (job.name !== JOB_NOTIFY_VENDOR) return;
    this.logger.log(
      `Notify vendor ${job.data.vendorId} of order ${job.data.trackingCode}`,
    );
  }
}
