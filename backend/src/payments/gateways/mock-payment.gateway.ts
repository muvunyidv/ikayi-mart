import { Injectable } from '@nestjs/common';
import { PaymentMethod } from '@prisma/client';
import { randomUUID } from 'crypto';
import {
  InitiatePaymentInput,
  InitiatePaymentResult,
  PaymentGateway,
  WebhookVerificationResult,
} from './payment-gateway.interface';

@Injectable()
export class MockPaymentGateway implements PaymentGateway {
  readonly method = PaymentMethod.MTN_MOMO;

  async initiate(input: InitiatePaymentInput): Promise<InitiatePaymentResult> {
    return {
      providerRef: `MOCK-${input.method}-${randomUUID()}`,
      ussdPushSent: false,
      message: `Test payment confirmed for ${input.trackingCode}.`,
    };
  }

  async parseWebhook(
    payload: Record<string, unknown>,
    _signature?: string,
  ): Promise<WebhookVerificationResult> {
    const providerRef = String(payload.providerRef ?? payload.externalId ?? '');
    const raw = String(payload.status ?? 'SUCCESSFUL').toUpperCase();
    const status =
      raw === 'FAILED' || raw === 'FAILEDSTATUS' ? 'FAILED' : raw === 'PENDING' ? 'PENDING' : 'SUCCESSFUL';
    return {
      providerRef,
      status,
      amountRwf: typeof payload.amountRwf === 'number' ? payload.amountRwf : undefined,
    };
  }
}
