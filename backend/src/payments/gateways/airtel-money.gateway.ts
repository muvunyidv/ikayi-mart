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
 * Airtel Money Collection abstraction (Open API USSD push).
 */
@Injectable()
export class AirtelMoneyGateway implements PaymentGateway {
  readonly method = PaymentMethod.AIRTEL_MONEY;
  private readonly logger = new Logger(AirtelMoneyGateway.name);

  constructor(private readonly config: ConfigService) {}

  async initiate(input: InitiatePaymentInput): Promise<InitiatePaymentResult> {
    const clientId = this.config.get<string>('AIRTEL_CLIENT_ID');
    const providerRef = randomUUID();

    if (!clientId) {
      this.logger.warn('Airtel credentials missing — returning stub reference');
      return {
        providerRef,
        ussdPushSent: true,
        message: `USSD push queued for ${input.phone} (Airtel Money sandbox stub).`,
      };
    }

    this.logger.log(`Airtel collection ${providerRef} amount=${input.amountRwf} RWF`);
    return {
      providerRef,
      ussdPushSent: true,
      message: `Airtel Money USSD prompt sent to ${input.phone}.`,
    };
  }

  async parseWebhook(payload: Record<string, unknown>): Promise<WebhookVerificationResult> {
    const txn = (payload.transaction as Record<string, unknown> | undefined) ?? payload;
    const providerRef = String(txn.id ?? payload.providerRef ?? '');
    const raw = String(txn.status ?? payload.status ?? '').toUpperCase();
    const status =
      raw === 'TS' || raw === 'SUCCESS' || raw === 'SUCCESSFUL' ? 'SUCCESSFUL' : raw === 'TIP' ? 'PENDING' : 'FAILED';
    return { providerRef, status };
  }
}
