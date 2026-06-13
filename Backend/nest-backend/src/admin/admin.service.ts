import { Injectable, NotFoundException } from '@nestjs/common';
import { AuthService } from '../auth/auth.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifSvc: NotificationsService,
    private readonly authSvc: AuthService,
  ) {}

  async getStats() {
    const [users, vehicles, bookings, shops, activeShops] = await Promise.all([
      this.prisma.user.count({ where: { role: 'owner' } }),
      this.prisma.vehicle.count(),
      this.prisma.booking.count(),
      this.prisma.shopProfile.count(),
      this.prisma.shopProfile.count({ where: { verificationStatus: 'verified' } }),
    ]);
    return { users, vehicles, bookings, shops, active_shops: activeShops };
  }

  async createShop(dto: any) {
    return this.authSvc.adminCreateShop(dto);
  }

  async listShops(status: string, limit: number, skip: number) {
    const where: any = {};
    if (status) where.verificationStatus = status;
    const [shops, total] = await Promise.all([
      this.prisma.shopProfile.findMany({ where, include: { user: true }, orderBy: { createdAt: 'desc' }, take: limit, skip }),
      this.prisma.shopProfile.count({ where }),
    ]);
    return { shops, total };
  }

  async verifyShop(id: string, status: string, notes?: string) {
    await this.prisma.shopProfile.update({
      where: { id },
      data: { verificationStatus: status, verificationNotes: notes ?? '' },
    });
    const shop = await this.prisma.shopProfile.findUnique({ where: { id }, include: { user: true } });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    const msg = status === 'verified' ? 'Profilingiz tasdiqlandi' : 'Profilingiz rad etildi';
    this.notifSvc.sendToUser(shop.userId, 'Verifikatsiya', msg, 'verification', id);
    return shop;
  }

  async listBookings(status: string, limit: number, skip: number) {
    const where: any = {};
    if (status) where.status = status;
    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: { customer: true, shop: { include: { user: true } }, vehicle: true, serviceType: true },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip,
      }),
      this.prisma.booking.count({ where }),
    ]);
    return { bookings, total };
  }

  async listUsers(search: string, role: string, limit: number, skip: number) {
    const where: any = {};
    if (role) where.role = role;
    if (search) {
      where.OR = [
        { fullName: { contains: search, mode: 'insensitive' } },
        { phone: { contains: search, mode: 'insensitive' } },
      ];
    }
    const [users, total] = await Promise.all([
      this.prisma.user.findMany({ where, orderBy: { createdAt: 'desc' }, take: limit, skip }),
      this.prisma.user.count({ where }),
    ]);
    return { users, total };
  }

  async listVehicles(search: string, limit: number, skip: number) {
    const where: any = {};
    if (search) where.plate = { contains: search, mode: 'insensitive' };
    const [vehicles, total] = await Promise.all([
      this.prisma.vehicle.findMany({ where, include: { owner: true }, orderBy: { createdAt: 'desc' }, take: limit, skip }),
      this.prisma.vehicle.count({ where }),
    ]);
    return { vehicles, total };
  }

  async listReviews(type: string, limit: number, skip: number) {
    const where: any = {};
    if (type) where.reviewType = type;
    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({ where, include: { author: true }, orderBy: { createdAt: 'desc' }, take: limit, skip }),
      this.prisma.review.count({ where }),
    ]);
    return { reviews, total };
  }

  async moderateReview(id: string, approve: boolean) {
    if (approve) {
      await this.prisma.review.update({ where: { id }, data: { isModerated: true } });
    } else {
      await this.prisma.review.delete({ where: { id } });
    }
  }

  async listServiceTypes() {
    return this.prisma.serviceType.findMany({ where: { isActive: true }, orderBy: { nameUz: 'asc' } });
  }

  async createServiceType(data: any) {
    return this.prisma.serviceType.create({
      data: {
        slug: data.slug,
        nameUz: data.nameUz ?? data.name_uz,
        nameRu: data.nameRu ?? data.name_ru ?? '',
        icon: data.icon ?? '',
        basePrice: data.basePrice ?? data.base_price ?? 0,
        isActive: data.isActive ?? data.is_active ?? true,
      },
    });
  }

  async updateServiceType(id: string, data: any) {
    return this.prisma.serviceType.update({
      where: { id },
      data: {
        slug: data.slug,
        nameUz: data.nameUz ?? data.name_uz,
        nameRu: data.nameRu ?? data.name_ru,
        icon: data.icon,
        basePrice: data.basePrice ?? data.base_price,
        isActive: data.isActive ?? data.is_active,
      },
    });
  }

  async listSeasonalRules() {
    return this.prisma.seasonalRule.findMany({ orderBy: [{ sendMonth: 'asc' }, { sendDay: 'asc' }] });
  }

  async createSeasonalRule(data: {
    name: string; sendMonth: number; sendDay: number; messageUz: string; messageRu: string;
  }) {
    return this.prisma.seasonalRule.create({
      data: { ...data, isActive: true },
    });
  }

  async updateSeasonalRule(id: string, data: Record<string, any>) {
    await this.prisma.seasonalRule.update({ where: { id }, data });
    return this.prisma.seasonalRule.findUnique({ where: { id } });
  }

  async sendSeasonalNow(id: string) {
    const rule = await this.prisma.seasonalRule.findUnique({ where: { id } });
    if (!rule) throw new NotFoundException('Qoida topilmadi');
    await this.notifSvc.broadcastSeasonal(rule);
    await this.prisma.seasonalRule.update({ where: { id }, data: { lastSentAt: new Date() } });
  }

  async broadcast(title: string, body: string) {
    await this.notifSvc.broadcastToAll(title, body);
  }
}
