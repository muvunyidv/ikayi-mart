import { IsEmail, IsString, IsUUID, Matches, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import {
  STRONG_PASSWORD_MESSAGE,
  STRONG_PASSWORD_REGEX,
} from '../../common/constants/validation';

export class ConvertGuestDto {
  @ApiProperty({ example: '7c9e6679-7425-40de-944b-e07fc1f90ae7' })
  @IsUUID()
  orderId!: string;

  @ApiProperty({ example: 'aline.uwase@gmail.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'GuestPass123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  @Matches(STRONG_PASSWORD_REGEX, { message: STRONG_PASSWORD_MESSAGE })
  password!: string;
}
