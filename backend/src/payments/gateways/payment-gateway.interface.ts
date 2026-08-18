import { PaymentMethod } from '@prisma/client';

export interface InitiatePaymentInput {
  orderId: string;
  trackingCode: string;
  amountRwf: number;
  phone: string;
  method: PaymentMethod;
}

export interface InitiatePaymentResult {
  providerRef: string;
  ussdPushSent: boolean;
  message: string;
}

export interface WebhookVerificationResult {
  providerRef: string;
  status: 'SUCCESSFUL' | 'FAILED' | 'PENDING';
  amountRwf?: number;
}

export interface PaymentGateway {
  readonly method: PaymentMethod;
  initiate(input: InitiatePaymentInput): Promise<InitiatePaymentResult>;
  parseWebhook(payload: Record<string, unknown>, signature?: string): Promise<WebhookVerificationResult>;
}
