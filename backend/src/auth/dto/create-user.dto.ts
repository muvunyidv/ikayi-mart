import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsPhoneNumber,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { normalizeRwandaPhone } from '../../common/utils/rwanda-phone';
import {
  RWANDA_PHONE_MESSAGE,
  RWANDA_PHONE_REGEX,
  STRONG_PASSWORD_MESSAGE,
  STRONG_PASSWORD_REGEX,
} from '../../common/constants/validation';

export class CreateUserDto {
  @ApiProperty({ example: 'Aline Uwase' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name!: string;

  @ApiProperty({ example: 'aline.uwase@gmail.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: '+250788123456' })
  @Transform(({ value }) =>
    typeof value === 'string' ? normalizeRwandaPhone(value) ?? value.trim() : value,
  )
  @IsString()
  @IsPhoneNumber('RW')
  @Matches(RWANDA_PHONE_REGEX, { message: RWANDA_PHONE_MESSAGE })
  phone!: string;

  @ApiProperty({ example: 'ShopperPass123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  @Matches(STRONG_PASSWORD_REGEX, { message: STRONG_PASSWORD_MESSAGE })
  password!: string;
}
