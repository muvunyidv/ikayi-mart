import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterVendorDto } from './dto/register-vendor.dto';
import { LoginDto } from './dto/login.dto';
import { JwtPayload } from './types/jwt-payload';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
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
