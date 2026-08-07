import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';

const MASTER_INCLUDE = {
  serviceTypes: { include: { serviceType: true } },
} as const;

@Injectable()
export class MastersService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Servis egasi tomonidan boshqaruv ───────────────────────────────────────

  async listByOwner(ownerUserId: string) {
    const shop = await this.requireOwnerShop(ownerUserId);
    const masters = await this.prisma.master.findMany({
      where: { shopId: shop.id },
      include: MASTER_INCLUDE,
      orderBy: [{ isActive: 'desc' }, { createdAt: 'asc' }],
    });
    return { masters };
  }

  async createMaster(ownerUserId: string, data: {
    phone: string;
    email: string;
    password: string;
    fullName: string;
    position?: string;
    avatarUrl?: string;
    serviceTypeIds?: string[];
  }) {
    const shop = await this.requireOwnerShop(ownerUserId);

    const phone = (data.phone ?? '').trim();
    const email = (data.email ?? '').toLowerCase().trim();
    if (!phone || !email || !data.password || !data.fullName) {
      throw new BadRequestException('Telefon, email, parol va ism majburiy');
    }

    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phone }, { email }] },
    });
    if (existing) {
      if (existing.phone === phone) throw new BadRequestException("Bu telefon raqami allaqachon ro'yxatdan o'tgan");
      throw new BadRequestException("Bu email allaqachon ro'yxatdan o'tgan");
    }

    const passwordHash = await bcrypt.hash(data.password, 12);
    const serviceTypeIds = data.serviceTypeIds ?? [];

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          phone,
          email,
          passwordHash,
          role: 'master',
          fullName: data.fullName,
          language: 'uz',
          emailVerified: true,
        },
      });

      const master = await tx.master.create({
        data: {
          shopId: shop.id,
          userId: user.id,
          fullName: data.fullName,
          position: data.position ?? '',
          avatarUrl: data.avatarUrl ?? '',
        },
      });

      if (serviceTypeIds.length) {
        await tx.masterServiceType.createMany({
          data: serviceTypeIds.map((serviceTypeId) => ({ masterId: master.id, serviceTypeId })),
          skipDuplicates: true,
        });
      }

      return tx.master.findUnique({ where: { id: master.id }, include: MASTER_INCLUDE });
    });
  }

  async updateMaster(ownerUserId: string, masterId: string, data: {
    fullName?: string;
    position?: string;
    avatarUrl?: string;
    isActive?: boolean;
    serviceTypeIds?: string[];
  }) {
    const master = await this.requireOwnedMaster(ownerUserId, masterId);

    const update: Record<string, any> = {};
    if (data.fullName !== undefined) update.fullName = data.fullName;
    if (data.position !== undefined) update.position = data.position;
    if (data.avatarUrl !== undefined) update.avatarUrl = data.avatarUrl;
    if (data.isActive !== undefined) update.isActive = data.isActive;

    return this.prisma.$transaction(async (tx) => {
      if (Object.keys(update).length) {
        await tx.master.update({ where: { id: master.id }, data: update });
      }
      if (data.serviceTypeIds) {
        await tx.masterServiceType.deleteMany({ where: { masterId: master.id } });
        if (data.serviceTypeIds.length) {
          await tx.masterServiceType.createMany({
            data: data.serviceTypeIds.map((serviceTypeId) => ({ masterId: master.id, serviceTypeId })),
            skipDuplicates: true,
          });
        }
      }
      return tx.master.findUnique({ where: { id: master.id }, include: MASTER_INCLUDE });
    });
  }

  async deactivateMaster(ownerUserId: string, masterId: string) {
    const master = await this.requireOwnedMaster(ownerUserId, masterId);
    await this.prisma.master.update({ where: { id: master.id }, data: { isActive: false } });
    return { message: "Usta o'chirildi (nofaol qilindi)" };
  }

  // ── Usta o'z kabineti ──────────────────────────────────────────────────────

  async getOwnProfile(masterUserId: string) {
    const master = await this.prisma.master.findUnique({
      where: { userId: masterUserId },
      include: { ...MASTER_INCLUDE, shop: true },
    });
    if (!master) throw new NotFoundException('Usta profili topilmadi');
    return master;
  }

  // ── Ommaviy (mijoz uchun) ──────────────────────────────────────────────────

  async listPublicByShop(shopId: string) {
    const masters = await this.prisma.master.findMany({
      where: { shopId, isActive: true },
      include: MASTER_INCLUDE,
      orderBy: [{ ratingAvg: 'desc' }, { createdAt: 'asc' }],
    });
    return { masters };
  }

  async getMasterCard(masterId: string) {
    const master = await this.prisma.master.findUnique({
      where: { id: masterId },
      include: { ...MASTER_INCLUDE, shop: { include: { user: true } } },
    });
    if (!master) throw new NotFoundException('Usta topilmadi');
    return master;
  }

  async getBookedSlots(masterId: string, dateFrom: string, dateTo: string) {
    const bookings = await this.prisma.booking.findMany({
      where: {
        masterId,
        status: { in: ['pending', 'confirmed', 'in_progress'] },
        scheduledAt: { gte: new Date(dateFrom), lt: new Date(dateTo) },
      },
      select: { scheduledAt: true },
    });
    return bookings.map((b) => b.scheduledAt.toISOString());
  }

  // ── Yordamchilar ───────────────────────────────────────────────────────────

  private async requireOwnerShop(ownerUserId: string) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId: ownerUserId } });
    if (!shop) throw new NotFoundException('Servis profili topilmadi');
    return shop;
  }

  private async requireOwnedMaster(ownerUserId: string, masterId: string) {
    const shop = await this.requireOwnerShop(ownerUserId);
    const master = await this.prisma.master.findFirst({ where: { id: masterId, shopId: shop.id } });
    if (!master) throw new NotFoundException('Usta topilmadi');
    return master;
  }
}
