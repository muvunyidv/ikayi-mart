import { Type } from 'class-transformer';
import {
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';
import { StoreContactInfoDto } from '../../stores/dto/store-contact-info.dto';

export class RegisterVendorDto extends CreateUserDto {
  @ApiProperty({ example: 'Kigali Tech Store' })
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  storeName!: string;

  @ApiPropertyOptional({
    example: 'Consumer electronics and accessories from Kigali.',
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
}
