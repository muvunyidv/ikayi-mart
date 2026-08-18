import { Body, Controller, Headers, Post, Req } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { PaymentsService } from './payments.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Public()
  @Post('initiate')
  @ApiOperation({ summary: 'Trigger USSD push (MTN MoMo / Airtel) for a guest order' })
  initiate(@Body() dto: InitiatePaymentDto) {
    return this.payments.initiate(dto);
  }

  @Public()
  @Post('webhook')
  @ApiOperation({ summary: 'Payment gateway callback — acknowledged immediately, processed async' })
  webhook(
    @Req() req: Request,
    @Headers('x-webhook-secret') signature?: string,
  ) {
    const payload = (req.body ?? {}) as Record<string, unknown>;
    return this.payments.enqueueWebhook(payload, signature);
  }
}
