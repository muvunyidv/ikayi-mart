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
import { User, UserRole, Vendor } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { OAuth2Client, TokenPayload } from 'google-auth-library';
import { PrismaService } from '../prisma/prisma.service';
import { StoresService } from '../stores/stores.service';
import { RegisterVendorDto } from './dto/register-vendor.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { ConvertGuestDto } from './dto/convert-guest.dto';
import { JwtPayload } from './types/jwt-payload';
import { normalizeRwandaPhone } from '../common/utils/rwanda-phone';

type AuthUser = User & { vendor: Vendor | null };

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly stores: StoresService,
  ) {}

  async registerCustomer(dto: CreateUserDto) {
    const email = dto.email.toLowerCase().trim();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException('Email is already registered');
    }

    const phone = this.requireRwandaPhone(dto.phone);
    const password = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        email,
        password,
        name: dto.name.trim(),
        role: UserRole.CUSTOMER,
        phone,
      },
      include: { vendor: true },
    });

    return this.issueAuthResponse(user);
  }

  async registerVendor(dto: RegisterVendorDto) {
    const email = dto.email.toLowerCase().trim();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException('Email is already registered');
    }

    const phone = this.requireRwandaPhone(dto.phone);
    const password = await bcrypt.hash(dto.password, 12);
    const storeName = dto.storeName.trim();
    const slug = await this.stores.allocateSlug(storeName);
    const contact = this.stores.resolveContact(dto, {
      phone,
      email,
    });
    const user = await this.prisma.user.create({
      data: {
        email,
        password,
        name: dto.name.trim(),
        role: UserRole.VENDOR,
        phone,
        vendor: {
          create: {
            storeName,
            slug,
            description: contact.description,
            phone: contact.phone,
            contactEmail: contact.contactEmail,
            isVerified: false,
            isOnline: true,
          },
        },
      },
      include: { vendor: true },
    });

    return this.issueAuthResponse(user);
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

    return this.issueAuthResponse(user);
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
      const refreshed = await this.prisma.user.findUnique({
        where: { id: user.id },
        include: { vendor: true },
      });
      if (refreshed) user = refreshed;
    }

    return this.issueAuthResponse(user);
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
      return this.issueAuthResponse(linked);
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

    return this.issueAuthResponse(user);
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

    return this.toPublicProfile(user);
  }

  private requireRwandaPhone(input: string): string {
    const phone = normalizeRwandaPhone(input);
    if (!phone) {
      throw new BadRequestException(
        'Enter a valid Rwandan phone number (+250 7XX XXX XXX or 07XX XXX XXX)',
      );
    }
    return phone;
  }

  private toPublicProfile(user: AuthUser) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      phone: user.phone,
      district: user.district,
      sector: user.sector,
      landmark: user.landmark,
      vendorId: user.vendor?.id ?? null,
      storeName: user.vendor?.storeName ?? null,
      storeSlug: user.vendor?.slug ?? null,
      storeDescription: user.vendor?.description ?? null,
      storePhone: user.vendor?.phone ?? null,
      storeContactEmail: user.vendor?.contactEmail ?? null,
      isVerified: user.vendor?.isVerified ?? null,
      isOnline: user.vendor?.isOnline ?? null,
      vendor: user.vendor
        ? {
            id: user.vendor.id,
            storeName: user.vendor.storeName,
            slug: user.vendor.slug,
            description: user.vendor.description,
            phone: user.vendor.phone,
            contactEmail: user.vendor.contactEmail,
            isVerified: user.vendor.isVerified,
            isOnline: user.vendor.isOnline,
          }
        : null,
      createdAt: user.createdAt,
    };
  }

  private async issueAuthResponse(user: AuthUser) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      vendorId: user.vendor?.id ?? null,
    };
    const accessToken = await this.jwt.signAsync(payload);
    return {
      accessToken,
      tokenType: 'Bearer',
      user: this.toPublicProfile(user),
    };
  }
}
