import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Server, Socket } from 'socket.io';
import { JwtPayload } from '../auth/types/jwt-payload';

@WebSocketGateway({
  cors: { origin: true, credentials: true },
  namespace: '/orders',
})
export class OrdersGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(OrdersGateway.name);

  constructor(private readonly jwt: JwtService) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const token = this.readToken(client);
      if (!token) {
        client.disconnect(true);
        return;
      }
      const payload = await this.jwt.verifyAsync<JwtPayload>(token);
      if (!payload.vendorId) {
        client.disconnect(true);
        return;
      }
      client.data.vendorId = payload.vendorId;
      await client.join(`vendor:${payload.vendorId}`);
      this.logger.log(`Vendor ${payload.vendorId} connected (${client.id})`);
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    this.logger.log(`Client disconnected (${client.id})`);
  }

  @SubscribeMessage('join')
  async onJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { vendorId?: string },
  ) {
    const vendorId = (client.data.vendorId as string | undefined) ?? body?.vendorId;
    if (!vendorId) {
      return { ok: false };
    }
    await client.join(`vendor:${vendorId}`);
    return { ok: true, room: `vendor:${vendorId}` };
  }

  notifyNewOrder(vendorId: string, payload: Record<string, unknown>): void {
    this.server.to(`vendor:${vendorId}`).emit('order:new', payload);
  }

  notifyOrderUpdated(vendorId: string, payload: Record<string, unknown>): void {
    this.server.to(`vendor:${vendorId}`).emit('order:updated', payload);
  }

  private readToken(client: Socket): string | null {
    const auth = client.handshake.auth as { token?: string };
    if (auth?.token) {
      return auth.token.replace(/^Bearer\s+/i, '');
    }
    const header = client.handshake.headers.authorization;
    if (typeof header === 'string') {
      return header.replace(/^Bearer\s+/i, '');
    }
    const query = client.handshake.query.token;
    if (typeof query === 'string') {
      return query;
    }
    return null;
  }
}
