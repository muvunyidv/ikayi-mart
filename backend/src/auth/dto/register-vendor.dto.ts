import { IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';

export class RegisterVendorDto extends CreateUserDto {
  @ApiProperty({ example: 'Kigali Tech Store' })
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  storeName!: string;
}
