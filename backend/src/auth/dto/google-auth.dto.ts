import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GoogleAuthDto {
  @ApiProperty({
    description: 'Google Sign-In ID token from the Flutter client',
    example: 'eyJhbGciOiJSUzI1NiIsImtpZCI6...',
  })
  @IsString()
  @IsNotEmpty()
  idToken!: string;

  @ApiPropertyOptional({
    description: 'Guest order to attach after Google sign-in',
  })
  @IsOptional()
  @IsUUID()
  orderId?: string;
}
