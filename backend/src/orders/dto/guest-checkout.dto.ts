import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '@prisma/client';
import { IsRwandaPhone } from '../../common/decorators/is-rwanda-phone.decorator';

export class CheckoutLineItemDto {
  @ApiProperty()
  @IsUUID()
  productId!: string;

  @ApiProperty({ example: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(99)
  quantity!: number;

  @ApiPropertyOptional({ example: { Color: 'Black' } })
  @IsOptional()
  @IsObject()
  selectedVariants?: Record<string, string>;
}

export class GuestCheckoutDto {
  @ApiProperty({ example: 'Aline Uwase' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  guestName!: string;

  @ApiProperty({ example: '+250 788 123 456' })
  @IsString()
  @IsRwandaPhone()
  phone!: string;

  @ApiProperty({ example: 'Gasabo' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  district!: string;

  @ApiProperty({ example: 'Remera' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  sector!: string;

  @ApiProperty({ example: 'Near MTN Centre, Chez Lando road' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  landmark!: string;

  @ApiPropertyOptional({ enum: PaymentMethod, default: PaymentMethod.MTN_MOMO })
  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;

  @ApiProperty({ type: [CheckoutLineItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CheckoutLineItemDto)
  items!: CheckoutLineItemDto[];
}
