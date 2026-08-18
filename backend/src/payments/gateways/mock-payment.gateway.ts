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
      ussdPushSent: input.method !== PaymentMethod.VISA_CARD,
      message:
        input.method === PaymentMethod.VISA_CARD
          ? 'Card payment session created (mock). Confirm via webhook.'
          : `USSD push sent to ${input.phone} (mock ${input.method}). Confirm via webhook.`,
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
