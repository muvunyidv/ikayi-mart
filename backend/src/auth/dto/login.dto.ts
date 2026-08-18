import { IsEmail, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'jean.paul@kigalitech.rw' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'VendorPass123!' })
  @IsString()
  @MinLength(8)
  password!: string;
}
