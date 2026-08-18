import { IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ReportIssueDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  orderId?: string;

  @ApiPropertyOptional({ example: 'IKY-9805' })
  @IsOptional()
  @IsString()
  trackingCode?: string;

  @ApiProperty({ example: 'Guest reports missing charger cable in case bundle.' })
  @IsString()
  @MinLength(8)
  @MaxLength(2000)
  issue!: string;
}
