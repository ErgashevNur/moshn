import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { EmailService } from '../email/email.service';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';

const OTP_TTL_MS = 10 * 60 * 1000;
const OTP_COOLDOWN_MS = 60 * 1000;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly emailService: EmailService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.toLowerCase().trim();
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phone: dto.phone }, { email }] },
    });
    if (existing) {
      if (existing.phone === dto.phone) throw new BadRequestException("Bu telefon raqami allaqachon ro'yxatdan o'tgan");
      throw new BadRequestException("Bu email allaqachon ro'yxatdan o'tgan");
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        phone: dto.phone,
        email,
        passwordHash,
        role: dto.role,
        fullName: dto.fullName,
        language: 'uz',
        emailVerified: true,
      },
    });

    if (dto.role === 'service') {
      await this.prisma.shopProfile.create({
        data: {
          userId: user.id,
          shopName: dto.shopName ?? '',
          address: dto.address || "Ko'rsatilmagan",
          latitude: dto.latitude ?? 0,
          longitude: dto.longitude ?? 0,
          workingHours: dto.workingHours ?? '',
          serviceTypes: dto.serviceTypes ?? [],
          verificationStatus: 'pending',
        },
      });
    }

    return this.buildTokenResponse(user);
  }

  async login(identifier: string, password: string) {
    const id = identifier.trim();
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ phone: id }, { email: id.toLowerCase() }] },
    });
    if (!user) throw new UnauthorizedException('Email yoki parol noto\'g\'ri');

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Email yoki parol noto\'g\'ri');

    return this.buildTokenResponse(user);
  }

  async refreshToken(token: string) {
    let payload: any;
    try {
      payload = this.jwtService.verify(token);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
    const user = await this.prisma.user.findUnique({ where: { id: payload.user_id } });
    if (!user) throw new UnauthorizedException('User not found');
    return this.buildTokenResponse(user);
  }

  async sendOtpByPhone(phone: string) {
    phone = phone.trim();
    if (!phone) throw new BadRequestException('Telefon raqamini kiriting');

    let user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phone,
          email: `${phone}@phone.shina24.uz`,
          passwordHash: '',
          fullName: 'Foydalanuvchi',
          role: '',
        },
      });
    }

    if (
      user.emailOtpLastSentAt &&
      Date.now() - user.emailOtpLastSentAt.getTime() < OTP_COOLDOWN_MS
    ) {
      throw new BadRequestException('Iltimos, 60 soniya kuting');
    }

    const code = EmailService.generateOtp();
    const expiresAt = new Date(Date.now() + OTP_TTL_MS);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { emailOtpCode: code, emailOtpExpiresAt: expiresAt, emailOtpLastSentAt: new Date() },
    });

    return code;
  }

  async verifyOtpByPhone(phone: string, code: string) {
    phone = phone.trim();
    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) throw new BadRequestException('Foydalanuvchi topilmadi');

    const isDevBypass = process.env.NODE_ENV !== 'production' && code === '000000';
    if (!isDevBypass) {
      if (!user.emailOtpCode || !user.emailOtpExpiresAt) {
        throw new BadRequestException("Kod topilmadi, qaytadan so'rang");
      }
      if (Date.now() > user.emailOtpExpiresAt.getTime()) {
        throw new BadRequestException("Kodning muddati o'tdi");
      }
      if (user.emailOtpCode !== code) {
        throw new BadRequestException("Kod noto'g'ri");
      }
    }

    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true, emailOtpCode: '', emailOtpExpiresAt: null },
    });

    const tokens = this.buildTokenResponse(updated);
    return { ...tokens, new_user: !updated.role };
  }

  async adminCreateShop(dto: {
    phone: string;
    email: string;
    password: string;
    fullName: string;
    shopName?: string;
    address?: string;
    latitude?: number;
    longitude?: number;
    workingHours?: string;
    serviceTypes?: string[];
  }) {
    const email = dto.email.toLowerCase().trim();
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phone: dto.phone }, { email }] },
    });
    if (existing) {
      if (existing.phone === dto.phone) throw new BadRequestException("Bu telefon raqami allaqachon ro'yxatdan o'tgan");
      throw new BadRequestException("Bu email allaqachon ro'yxatdan o'tgan");
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        phone: dto.phone,
        email,
        passwordHash,
        role: 'service',
        fullName: dto.fullName,
        language: 'uz',
        emailVerified: true,
        isVerified: true,
      },
    });

    const shop = await this.prisma.shopProfile.create({
      data: {
        userId: user.id,
        shopName: dto.shopName ?? '',
        address: dto.address || "Ko'rsatilmagan",
        latitude: dto.latitude ?? 0,
        longitude: dto.longitude ?? 0,
        workingHours: dto.workingHours ?? '',
        serviceTypes: dto.serviceTypes ?? [],
        verificationStatus: 'verified',
      },
      include: { user: true },
    });

    return shop;
  }

  private buildTokenResponse(user: { id: string; role: string; [key: string]: any }) {
    const payload = { user_id: user.id, role: user.role };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '1h' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '30d' });
    const { passwordHash, emailOtpCode, emailOtpExpiresAt, emailOtpLastSentAt, ...safeUser } = user as any;
    return { access_token: accessToken, refresh_token: refreshToken, user: safeUser };
  }
}
