import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { OAuth2Client, TokenPayload } from 'google-auth-library';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterVendorDto } from './dto/register-vendor.dto';
import { LoginDto } from './dto/login.dto';
import { ConvertGuestDto } from './dto/convert-guest.dto';
import { JwtPayload } from './types/jwt-payload';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async registerVendor(dto: RegisterVendorDto) {
    const email = dto.email.toLowerCase().trim();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException('Email is already registered');
    }

    const password = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        email,
        password,
        name: dto.name.trim(),
        role: UserRole.VENDOR,
        vendor: {
          create: {
            storeName: dto.storeName.trim(),
            isVerified: false,
            isOnline: true,
          },
        },
      },
      include: { vendor: true },
    });

    return this.issueAuthResponse(user.id, user.email, user.role, user.vendor!.id, {
      name: user.name,
      storeName: user.vendor!.storeName,
      isVerified: user.vendor!.isVerified,
      isOnline: user.vendor!.isOnline,
    });
  }

  async login(dto: LoginDto) {
    const email = dto.email.toLowerCase().trim();
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { vendor: true },
    });
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (!user.password) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const ok = await bcrypt.compare(dto.password, user.password);
    if (!ok) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.issueAuthResponse(user.id, user.email, user.role, user.vendor?.id ?? null, {
      name: user.name,
      storeName: user.vendor?.storeName ?? null,
      isVerified: user.vendor?.isVerified ?? null,
      isOnline: user.vendor?.isOnline ?? null,
    });
  }

  async loginWithGoogle(idToken: string, orderId?: string) {
    const audience =
      this.config.get<string>('googleClientId') ||
      this.config.get<string>('GOOGLE_CLIENT_ID');
    if (!audience) {
      throw new InternalServerErrorException(
        'GOOGLE_CLIENT_ID is not configured',
      );
    }

    const client = new OAuth2Client(audience);
    let payload: TokenPayload | undefined;
    try {
      const ticket = await client.verifyIdToken({
        idToken,
        audience,
      });
      payload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException('Invalid or expired Google token');
    }

    if (!payload?.email || payload.email_verified === false) {
      throw new UnauthorizedException('Invalid or expired Google token');
    }

    const email = payload.email.toLowerCase().trim();
    const name = (payload.name?.trim() || email.split('@')[0]).trim();

    let user = await this.prisma.user.findUnique({
      where: { email },
      include: { vendor: true },
    });
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          email,
          name,
          password: null,
          role: UserRole.CUSTOMER,
        },
        include: { vendor: true },
      });
    }

    if (orderId) {
      await this.linkGuestOrder(user.id, email, orderId);
    }

    return this.issueAuthResponse(
      user.id,
      user.email,
      user.role,
      user.vendor?.id ?? null,
      {
        name: user.name,
        storeName: user.vendor?.storeName ?? null,
        isVerified: user.vendor?.isVerified ?? null,
        isOnline: user.vendor?.isOnline ?? null,
      },
    );
  }

  async convertGuest(dto: ConvertGuestDto) {
    const email = dto.email.toLowerCase().trim();
    const order = await this.prisma.customerOrder.findUnique({
      where: { id: dto.orderId },
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const orderEmail = (order.email ?? '').toLowerCase().trim();
    if (!orderEmail || orderEmail !== email) {
      throw new BadRequestException('Email does not match this order');
    }

    if (order.userId) {
      const linked = await this.prisma.user.findUnique({
        where: { id: order.userId },
        include: { vendor: true },
      });
      if (!linked || linked.email !== email) {
        throw new ConflictException('This order is already linked to an account');
      }
      if (!linked.password) {
        throw new UnauthorizedException('Sign in with Google for this account');
      }
      const ok = await bcrypt.compare(dto.password, linked.password);
      if (!ok) {
        throw new UnauthorizedException('Invalid credentials');
      }
      return this.issueAuthResponse(
        linked.id,
        linked.email,
        linked.role,
        linked.vendor?.id ?? null,
        {
          name: linked.name,
          storeName: linked.vendor?.storeName ?? null,
          isVerified: linked.vendor?.isVerified ?? null,
          isOnline: linked.vendor?.isOnline ?? null,
        },
      );
    }

    let user = await this.prisma.user.findUnique({
      where: { email },
      include: { vendor: true },
    });

    if (user) {
      if (!user.password) {
        const password = await bcrypt.hash(dto.password, 12);
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: {
            password,
            phone: user.phone ?? order.phone,
            district: user.district ?? order.district,
            sector: user.sector ?? order.sector,
            landmark: user.landmark ?? order.landmark,
          },
          include: { vendor: true },
        });
      } else {
        const ok = await bcrypt.compare(dto.password, user.password);
        if (!ok) {
          throw new UnauthorizedException('Invalid credentials');
        }
      }
    } else {
      user = await this.prisma.user.create({
        data: {
          email,
          password: await bcrypt.hash(dto.password, 12),
          name: order.guestName.trim(),
          role: UserRole.CUSTOMER,
          phone: order.phone,
          district: order.district,
          sector: order.sector,
          landmark: order.landmark,
        },
        include: { vendor: true },
      });
    }

    await this.linkGuestOrder(user.id, email, order.id);

    return this.issueAuthResponse(
      user.id,
      user.email,
      user.role,
      user.vendor?.id ?? null,
      {
        name: user.name,
        storeName: user.vendor?.storeName ?? null,
        isVerified: user.vendor?.isVerified ?? null,
        isOnline: user.vendor?.isOnline ?? null,
      },
    );
  }

  private async linkGuestOrder(userId: string, email: string, orderId: string) {
    const order = await this.prisma.customerOrder.findUnique({
      where: { id: orderId },
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const orderEmail = (order.email ?? '').toLowerCase().trim();
    if (!orderEmail || orderEmail !== email.toLowerCase().trim()) {
      throw new BadRequestException(
        'This Google account does not match the email used at checkout',
      );
    }

    if (order.userId && order.userId !== userId) {
      throw new ConflictException('This order is already linked to an account');
    }

    await this.prisma.customerOrder.update({
      where: { id: orderId },
      data: {
        userId,
        isGuest: false,
        email: email.toLowerCase().trim(),
      },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        phone: order.phone,
        district: order.district,
        sector: order.sector,
        landmark: order.landmark,
      },
    });
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { vendor: true },
    });
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      vendor: user.vendor
        ? {
            id: user.vendor.id,
            storeName: user.vendor.storeName,
            isVerified: user.vendor.isVerified,
            isOnline: user.vendor.isOnline,
          }
        : null,
      createdAt: user.createdAt,
    };
  }

  private async issueAuthResponse(
    userId: string,
    email: string,
    role: UserRole,
    vendorId: string | null,
    profile: {
      name: string;
      storeName: string | null;
      isVerified: boolean | null;
      isOnline: boolean | null;
    },
  ) {
    const payload: JwtPayload = { sub: userId, email, role, vendorId };
    const accessToken = await this.jwt.signAsync(payload);
    return {
      accessToken,
      tokenType: 'Bearer',
      user: {
        id: userId,
        email,
        name: profile.name,
        role,
        vendorId,
        storeName: profile.storeName,
        isVerified: profile.isVerified,
        isOnline: profile.isOnline,
      },
    };
  }
}
