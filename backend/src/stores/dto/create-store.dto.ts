import { Transform, Type } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { StoreContactInfoDto } from './store-contact-info.dto';
import { normalizeRwandaPhone } from '../../common/utils/rwanda-phone';
import { IsRwandaPhone } from '../../common/decorators/is-rwanda-phone.decorator';

export class CreateStoreDto {
  @ApiProperty({ example: 'Titan Builders' })
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  storeName!: string;

  @ApiPropertyOptional({
    example: 'Kigali trusted hardware and building-materials store.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(4000)
  description?: string;

  @ApiPropertyOptional({ type: StoreContactInfoDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => StoreContactInfoDto)
  contactInfo?: StoreContactInfoDto;

  @ApiPropertyOptional({ example: '+250788123456' })
  @IsOptional()
  @Transform(({ value }) =>
    typeof value === 'string' ? normalizeRwandaPhone(value) ?? value.trim() : value,
  )
  @IsString()
  @IsRwandaPhone()
  phone?: string;

  @ApiPropertyOptional({ example: 'hello@titanbuilders.rw' })
  @IsOptional()
  @IsEmail()
  @MaxLength(120)
  contactEmail?: string;
}
