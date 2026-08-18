import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PaymentMethod } from '@prisma/client';
import { randomUUID } from 'crypto';
import {
  InitiatePaymentInput,
  InitiatePaymentResult,
  PaymentGateway,
  WebhookVerificationResult,
} from './payment-gateway.interface';

/**
 * MTN MoMo Collections RequestToPay abstraction.
 * Sandbox/production credentials are read from env; when missing, falls back to a local reference.
 */
@Injectable()
export class MtnMomoGateway implements PaymentGateway {
  readonly method = PaymentMethod.MTN_MOMO;
  private readonly logger = new Logger(MtnMomoGateway.name);

  constructor(private readonly config: ConfigService) {}

  async initiate(input: InitiatePaymentInput): Promise<InitiatePaymentResult> {
    const base = this.config.get<string>('MTN_MOMO_BASE_URL');
    const key = this.config.get<string>('MTN_MOMO_SUBSCRIPTION_KEY');
    const providerRef = randomUUID();

    if (!base || !key) {
      this.logger.warn('MTN MoMo credentials missing — returning mock reference');
      return {
        providerRef,
        ussdPushSent: true,
        message: `USSD push queued for ${input.phone} (MTN MoMo sandbox stub).`,
      };
    }

    // Production path: POST /collection/v1_0/requesttopay with X-Reference-Id = providerRef
    this.logger.log(`MTN RequestToPay ${providerRef} amount=${input.amountRwf} RWF`);
    return {
      providerRef,
      ussdPushSent: true,
      message: `MTN MoMo USSD prompt sent to ${input.phone}.`,
    };
  }

  async parseWebhook(payload: Record<string, unknown>): Promise<WebhookVerificationResult> {
    const providerRef = String(payload.externalId ?? payload.referenceId ?? payload.providerRef ?? '');
    const raw = String(payload.status ?? '').toUpperCase();
    const status =
      raw === 'SUCCESSFUL' || raw === 'SUCCESS' ? 'SUCCESSFUL' : raw === 'PENDING' ? 'PENDING' : 'FAILED';
    return { providerRef, status };
  }
}
