import { Injectable, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async getProfile(userId: string, role: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Foydalanuvchi topilmadi');

    const { passwordHash, emailOtpCode, emailOtpExpiresAt, emailOtpLastSentAt, ...safeUser } = user as any;

    const result: any = { user: safeUser };
    if (role === 'service') {
      const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
      if (shop) result.shop = shop;
    }
    return result;
  }

  async updateProfile(userId: string, fullName: string) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { fullName },
    });
    const { passwordHash, emailOtpCode, emailOtpExpiresAt, emailOtpLastSentAt, ...safeUser } = user as any;
    return safeUser;
  }

  async setRole(userId: string, role: string, fullName?: string) {
    const data: any = { role };
    if (fullName) data.fullName = fullName;
    const user = await this.prisma.user.update({ where: { id: userId }, data });
    const { passwordHash, emailOtpCode, emailOtpExpiresAt, emailOtpLastSentAt, ...safeUser } = user as any;

    // Role o'zgargani uchun yangi tokenlar chiqarish
    const payload = { user_id: user.id, role: user.role };
    const accessToken = this.jwt.sign(payload, { expiresIn: '1h' });
    const refreshToken = this.jwt.sign(payload, { expiresIn: '30d' });

    return { user: safeUser, access_token: accessToken, refresh_token: refreshToken };
  }

  async updateLanguage(userId: string, language: string) {
    await this.prisma.user.update({ where: { id: userId }, data: { language } });
  }

  async updateAvatar(userId: string, avatarUrl: string) {
    await this.prisma.user.update({ where: { id: userId }, data: { avatarUrl } });
  }
}
