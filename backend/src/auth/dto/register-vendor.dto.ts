import { IsEmail, IsString, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterVendorDto {
  @ApiProperty({ example: 'jean.paul@kigalitech.rw' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'VendorPass123!' })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;

  @ApiProperty({ example: 'Jean Paul K.' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name!: string;

  @ApiProperty({ example: 'Kigali Tech Store' })
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  storeName!: string;
}
