import { IsEmail, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

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
  password!: string;
}
