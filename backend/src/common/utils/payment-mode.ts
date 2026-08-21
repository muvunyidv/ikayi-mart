import { ConfigService } from '@nestjs/config';

/** Mock mode auto-confirms pay so the shopper flow can be tested without MoMo/Airtel. */
export function isMockPaymentMode(config: ConfigService): boolean {
  const mode = (config.get<string>('PAYMENT_MODE') ?? 'mock').toLowerCase();
  return mode !== 'production';
}
