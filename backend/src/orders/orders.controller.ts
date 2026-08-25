import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { OrdersService } from './orders.service';
import { GuestCheckoutDto } from './dto/guest-checkout.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { QueryVendorOrdersDto } from './dto/query-vendor-orders.dto';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload';

@ApiTags('orders')
@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Public()
  @Post()
  @ApiOperation({
    summary:
      'Place an order. Unauthenticated when isGuest is true and contact details are provided. Signed-in users are linked and their shipping profile is saved.',
  })
  create(@Body() dto: GuestCheckoutDto, @CurrentUser() user?: JwtPayload) {
    return this.orders.guestCheckout(dto, user);
  }

  @Public()
  @Post('guest-checkout')
  @ApiOperation({ summary: 'Guest checkout alias of POST /orders' })
  guestCheckout(@Body() dto: GuestCheckoutDto, @CurrentUser() user?: JwtPayload) {
    return this.orders.guestCheckout(dto, user);
  }

  @Public()
  @Get('track/:code')
  @ApiOperation({ summary: 'Guest order tracking by IKY-XXXX code' })
  track(@Param('code') code: string) {
    return this.orders.track(code);
  }

  @Get('my-orders')
  @Roles(UserRole.CUSTOMER, UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Orders linked to the signed-in shopper account' })
  listMyOrders(@CurrentUser() user: JwtPayload) {
    return this.orders.listForCustomer(user);
  }

  @Get('mine')
  @Roles(UserRole.CUSTOMER, UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Alias of GET /orders/my-orders' })
  listMine(@CurrentUser() user: JwtPayload) {
    return this.orders.listForCustomer(user);
  }

  @Get('vendor')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Vendor order list, optionally filtered by status' })
  listVendor(@CurrentUser() user: JwtPayload, @Query() query: QueryVendorOrdersDto) {
    return this.orders.listForVendor(user, query.status);
  }

  @Post(':id/claim')
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Attach a guest order to the signed-in account when emails match',
  })
  claim(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.orders.claimForUser(user, id);
  }

  @Patch(':id/status')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Advance order status (PENDING → PROCESSING → SHIPPED → DELIVERED)' })
  updateStatus(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.orders.updateStatus(user, id, dto.status);
  }
}
