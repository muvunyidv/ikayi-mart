import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { OrderStatus, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from '../auth/types/jwt-payload';
import { ReportIssueDto } from './dto/report-issue.dto';
import { ReplyTicketDto } from './dto/reply-ticket.dto';
import { OrdersGateway } from '../orders/orders.gateway';

@Injectable()
export class SupportService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly gateway: OrdersGateway,
  ) {}

  async reportIssue(dto: ReportIssueDto) {
    if (!dto.orderId && !dto.trackingCode) {
      throw new BadRequestException('Provide orderId or trackingCode');
    }

    const order = await this.prisma.customerOrder.findFirst({
      where: dto.orderId
        ? { id: dto.orderId }
        : { trackingCode: dto.trackingCode!.replace(/^#/, '').toUpperCase() },
      include: { supportTicket: true, items: true },
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }
    if (order.supportTicket) {
      throw new ConflictException('A support ticket already exists for this order');
    }

    const ticket = await this.prisma.supportTicket.create({
      data: { orderId: order.id, issue: dto.issue.trim() },
    });

    await this.prisma.customerOrder.update({
      where: { id: order.id },
      data: { status: OrderStatus.ISSUE_REPORTED },
    });

    for (const vendorId of [...new Set(order.items.map((i) => i.vendorId))]) {
      this.gateway.notifyOrderUpdated(vendorId, {
        orderId: order.id,
        trackingCode: order.trackingCode,
        status: OrderStatus.ISSUE_REPORTED,
        ticketId: ticket.id,
      });
    }

    return {
      ticketId: ticket.id,
      orderId: order.id,
      trackingCode: order.trackingCode,
      issue: ticket.issue,
      isResolved: ticket.isResolved,
      status: OrderStatus.ISSUE_REPORTED,
    };
  }

  async reply(user: JwtPayload, dto: ReplyTicketDto) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: dto.ticketId },
      include: { order: { include: { items: true } } },
    });
    if (!ticket) {
      throw new NotFoundException('Ticket not found');
    }

    if (user.role !== UserRole.ADMIN) {
      const owns = ticket.order.items.some((i) => i.vendorId === user.vendorId);
      if (!owns) {
        throw new ForbiddenException('You cannot reply to another vendor’s ticket');
      }
    }

    const updated = await this.prisma.supportTicket.update({
      where: { id: ticket.id },
      data: {
        resolution: dto.resolution.trim(),
        isResolved: true,
      },
    });

    return {
      ticketId: updated.id,
      orderId: updated.orderId,
      issue: updated.issue,
      resolution: updated.resolution,
      isResolved: updated.isResolved,
    };
  }
}
