import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ShopsService {
  constructor(private readonly prisma: PrismaService) {}

  async findMany(filter: {
    serviceType?: string;
    lat?: number;
    lng?: number;
    limit: number;
    skip: number;
  }) {
    const where: any = { verificationStatus: 'verified' };
    if (filter.serviceType) {
      where.serviceTypes = { has: filter.serviceType };
    }

    const [shops, total] = await Promise.all([
      this.prisma.shopProfile.findMany({
        where,
        include: { user: true },
        take: filter.limit,
        skip: filter.skip,
      }),
      this.prisma.shopProfile.count({ where }),
    ]);

    const result = shops.map((s) => ({
      ...s,
      distance_km:
        filter.lat && filter.lng
          ? Math.round(this.haversine(filter.lat, filter.lng, s.latitude, s.longitude) * 10) / 10
          : 0,
    }));

    return { shops: result, total };
  }

  async findById(id: string) {
    const shop = await this.prisma.shopProfile.findUnique({
      where: { id },
      include: { user: true },
    });
    if (!shop) throw new NotFoundException('Servis topilmadi');
    return shop;
  }

  async findByUserId(userId: string) {
    const shop = await this.prisma.shopProfile.findUnique({
      where: { userId },
      include: { user: true },
    });
    if (!shop) throw new NotFoundException('Servis profili topilmadi');
    return shop;
  }

  async updateProfile(userId: string, data: Record<string, any>) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('Servis profili topilmadi');

    const allowed = ['shopName', 'address', 'latitude', 'longitude', 'phone', 'workingHours', 'serviceTypes'];
    const update: Record<string, any> = {};
    for (const key of allowed) {
      if (data[key] !== undefined) update[key] = data[key];
    }

    return this.prisma.shopProfile.update({ where: { id: shop.id }, data: update, include: { user: true } });
  }

  async getCustomers(shopId: string, limit: number, skip: number) {
    const [cards, total] = await Promise.all([
      this.prisma.customerCard.findMany({
        where: { shopId },
        include: { customer: true },
        orderBy: [{ isVip: 'desc' }, { lastVisitAt: 'desc' }],
        take: limit,
        skip,
      }),
      this.prisma.customerCard.count({ where: { shopId } }),
    ]);
    return { customers: cards, total };
  }

  async getCustomerCard(shopId: string, customerId: string) {
    const card = await this.prisma.customerCard.findFirst({
      where: { shopId, customerId },
      include: { customer: true },
    });
    if (!card) throw new NotFoundException('Mijoz kartochkasi topilmadi');
    return card;
  }

  async updateCustomerCard(shopId: string, customerId: string, data: { isVip?: boolean; notes?: string }) {
    const card = await this.prisma.customerCard.findFirst({ where: { shopId, customerId } });
    if (!card) throw new NotFoundException('Mijoz kartochkasi topilmadi');
    return this.prisma.customerCard.update({
      where: { id: card.id },
      data,
      include: { customer: true },
    });
  }

  async upsertCustomerCard(shopId: string, customerId: string) {
    return this.prisma.customerCard.upsert({
      where: { shopId_customerId: { shopId, customerId } },
      update: {},
      create: { shopId, customerId, visitCount: 1 },
    });
  }

  async getServiceTypes() {
    return this.prisma.serviceType.findMany({
      where: { isActive: true },
      orderBy: { nameUz: 'asc' },
    });
  }

  private haversine(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}
