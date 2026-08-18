import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Req,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { randomUUID } from 'crypto';
import { Request } from 'express';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { QueryProductsDto } from './dto/query-products.dto';
import { ToggleProductStatusDto } from './dto/toggle-status.dto';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload';
import { ensureUploadDir } from '../common/upload';

const IMAGE_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif']);

@ApiTags('products')
@Controller('products')
export class ProductsController {
  constructor(private readonly products: ProductsService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Public catalog with category, search, and pagination' })
  findAll(@Query() query: QueryProductsDto) {
    return this.products.findPublic(query);
  }

  @Get('mine')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Authenticated vendor catalog, including inactive items' })
  findMine(@CurrentUser() user: JwtPayload) {
    return this.products.findMine(user);
  }

  @Post('upload')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload a product image and return a public URL' })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (_req, _file, cb) => cb(null, ensureUploadDir()),
        filename: (_req, file, cb) => {
          const ext = extname(file.originalname || '').toLowerCase() || '.jpg';
          cb(null, `${randomUUID()}${ext}`);
        },
      }),
      limits: { fileSize: 8 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        const ext = extname(file.originalname || '').toLowerCase();
        const ok =
          IMAGE_EXT.has(ext) ||
          (file.mimetype || '').startsWith('image/');
        if (!ok) {
          cb(new BadRequestException('Only JPG, PNG, WEBP, or GIF images are allowed'), false);
          return;
        }
        cb(null, true);
      },
    }),
  )
  upload(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    if (!file) {
      throw new BadRequestException('Choose an image file to upload');
    }
    const host = req.get('host') ?? 'localhost:3000';
    const protocol = req.protocol ?? 'http';
    return { imageUrl: `${protocol}://${host}/uploads/${file.filename}` };
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get product by ID or slug' })
  findOne(@Param('id') id: string) {
    return this.products.findByIdOrSlug(id);
  }

  @Post()
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a product (vendor)' })
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateProductDto) {
    return this.products.create(user, dto);
  }

  @Put(':id')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a product (own catalog only)' })
  update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
  ) {
    return this.products.update(user, id, dto);
  }

  @Patch(':id/status')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Toggle product active state' })
  toggleStatus(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: ToggleProductStatusDto,
  ) {
    return this.products.toggleStatus(user, id, dto.isActive);
  }

  @Delete(':id')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete a product (own catalog only)' })
  remove(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.products.remove(user, id);
  }
}
