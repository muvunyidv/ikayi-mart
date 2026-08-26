import { Body, Controller, Get, Param, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { StoresService } from './stores.service';
import { UpdateStoreDto } from './dto/update-store.dto';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload';

@ApiTags('stores')
@Controller('stores')
export class StoresController {
  constructor(private readonly stores: StoresService) {}

  @Get('me')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Authenticated vendor store profile and catalog' })
  findMine(@CurrentUser() user: JwtPayload) {
    return this.stores.findMine(user);
  }

  @Patch('me')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update store name, bio, and contact info' })
  updateMine(@CurrentUser() user: JwtPayload, @Body() dto: UpdateStoreDto) {
    return this.stores.updateMine(user, dto);
  }

  @Public()
  @Get(':slug')
  @ApiOperation({
    summary: 'Public store channel: metadata, categories, and active products',
  })
  findBySlug(@Param('slug') slug: string) {
    return this.stores.findPublicBySlug(slug);
  }
}
