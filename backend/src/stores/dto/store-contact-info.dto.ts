import { Transform } from 'class-transformer';
import { IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { normalizeRwandaPhone } from '../../common/utils/rwanda-phone';
import { IsRwandaPhone } from '../../common/decorators/is-rwanda-phone.decorator';

export class StoreContactInfoDto {
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
  email?: string;
}
