import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { VendorDashboardService } from './vendor-dashboard.service';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload';

@ApiTags('vendor-dashboard')
@ApiBearerAuth()
@Roles(UserRole.VENDOR, UserRole.ADMIN)
@Controller('vendor/dashboard')
export class VendorDashboardController {
  constructor(private readonly dashboard: VendorDashboardService) {}

  @Get('kpis')
  @ApiOperation({ summary: "Today's revenue, pending orders, low stock, completed orders" })
  kpis(@CurrentUser() user: JwtPayload) {
    return this.dashboard.kpis(user);
  }

  @Get('chart')
  @ApiOperation({ summary: '7-day weekly revenue breakdown' })
  chart(@CurrentUser() user: JwtPayload) {
    return this.dashboard.chart(user);
  }
}
