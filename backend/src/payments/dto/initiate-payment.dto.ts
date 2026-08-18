import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '@prisma/client';
import { IsRwandaPhone } from '../../common/decorators/is-rwanda-phone.decorator';

export class InitiatePaymentDto {
  @ApiPropertyOptional({ description: 'Order UUID' })
  @IsOptional()
  @IsUUID()
  orderId?: string;

  @ApiPropertyOptional({ example: 'IKY-9842' })
  @IsOptional()
  @IsString()
  trackingCode?: string;

  @ApiPropertyOptional({ enum: PaymentMethod })
  @IsOptional()
  @IsEnum(PaymentMethod)
  method?: PaymentMethod;

  @ApiPropertyOptional({ example: '+250788123456' })
  @IsOptional()
  @IsString()
  @IsRwandaPhone()
  phone?: string;
}
