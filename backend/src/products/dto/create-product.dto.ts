import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ProductVariantDto {
  @ApiProperty({ example: 'Color' })
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  name!: string;

  @ApiProperty({ example: ['Black', 'White', 'Navy'] })
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(30)
  options!: string[];
}

export class CreateProductDto {
  @ApiProperty({ example: 'Pro Sound Wireless Headphones' })
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  name!: string;

  @ApiProperty({ example: 'Electronics' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  category!: string;

  @ApiProperty({ example: 45000, description: 'Integer RWF only' })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  priceRwf!: number;

  @ApiProperty({ example: 24 })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  stock!: number;

  @ApiProperty({ example: 'https://res.cloudinary.com/demo/image/upload/v1/ikayi-mart/products/headphones.jpg' })
  @IsString()
  @MinLength(4)
  @MaxLength(500)
  imageUrl!: string;

  @ApiProperty({ example: 'Over-ear wireless headphones with 40mm drivers.' })
  @IsString()
  @MinLength(8)
  @MaxLength(4000)
  description!: string;

  @ApiPropertyOptional({ example: 'HOT SELLER' })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  badge?: string;

  @ApiPropertyOptional({ example: 'KIVU REGION' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  originLabel?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(12)
  gallery?: string[];

  @ApiPropertyOptional({ type: [ProductVariantDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ProductVariantDto)
  variants?: ProductVariantDto[];
}
