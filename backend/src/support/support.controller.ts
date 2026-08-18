import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { SupportService } from './support.service';
import { ReportIssueDto } from './dto/report-issue.dto';
import { ReplyTicketDto } from './dto/reply-ticket.dto';
import { Public } from '../common/decorators/public.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/types/jwt-payload';

@ApiTags('support')
@Controller('support')
export class SupportController {
  constructor(private readonly support: SupportService) {}

  @Public()
  @Post('report-issue')
  @ApiOperation({ summary: 'Guest or admin creates a support ticket for an order' })
  reportIssue(@Body() dto: ReportIssueDto) {
    return this.support.reportIssue(dto);
  }

  @Post('reply')
  @Roles(UserRole.VENDOR, UserRole.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Vendor resolves a support ticket' })
  reply(@CurrentUser() user: JwtPayload, @Body() dto: ReplyTicketDto) {
    return this.support.reply(user, dto);
  }
}
