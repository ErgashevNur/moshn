import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  BusyInterval,
  freeSlotsForDay,
  localDateStr,
  localDayStartUtc,
} from './availability';

@Injectable()
export class ShopsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Bosh ekrandagi qidiruv paneli — ism bo'yicha servis va usta aralash
   * natija qaytaradi (CLAUDE.md §4: "mijoz servisni ham, aniq ustani ham
   * ko'ra oladi").
   */
  async search(query: string) {
    const q = query.trim();
    if (!q) return { shops: [], masters: [] };

    const [shops, masters] = await Promise.all([
      this.prisma.shopProfile.findMany({
        where: {
          verificationStatus: { in: ['verified', 'pending'] },
          shopName: { contains: q, mode: 'insensitive' },
        },
        orderBy: [{ ratingAvg: 'desc' }],
        take: 10,
      }),
      this.prisma.master.findMany({
        where: {
          isActive: true,
          fullName: { contains: q, mode: 'insensitive' },
          shop: { verificationStatus: { in: ['verified', 'pending'] } },
        },
        include: { shop: true },
        orderBy: [{ ratingAvg: 'desc' }],
        take: 10,
      }),
    ]);

    return { shops, masters };
  }

  async findMany(filter: {
    serviceType?: string;
    lat?: number;
    lng?: number;
    limit: number;
    skip: number;
    /// Zapis ekranidagi tablar: 'rating' | 'price' | 'distance'
    sort?: string;
    /// Berilsa, ro'yxatga shu xizmat bo'yicha eng arzon paket narxi va
    /// eng yaqin bo'sh vaqt qo'shiladi (zapis ekrani uchun).
    serviceTypeId?: string;
  }) {
    const where: any = { verificationStatus: { in: ['verified', 'pending'] } };
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

    const withDistance = shops.map((s) => ({
      ...s,
      distance_km:
        filter.lat && filter.lng
          ? Math.round(this.haversine(filter.lat, filter.lng, s.latitude, s.longitude) * 10) / 10
          : 0,
    }));

    const result = filter.serviceTypeId
      ? await this.enrichForBooking(withDistance, filter.serviceTypeId)
      : withDistance.map((s) => ({ ...s, min_price: null, nearest_slot: null }));

    this.sortShops(result, filter.sort);
    return { shops: result, total };
  }

  /// Zapis ekrani uchun qo'shimcha maydonlar: eng arzon paket narxi
  /// ("от 320 000 сум") va eng yaqin bo'sh vaqt.
  private async enrichForBooking(shops: any[], serviceTypeId: string) {
    const ids = shops.map((s) => s.id);
    if (!ids.length) return shops;

    const packages = await this.prisma.shopServicePackage.findMany({
      where: { shopId: { in: ids }, serviceTypeId, isActive: true },
      select: { shopId: true, price: true, durationMin: true },
    });

    const minPrice = new Map<string, number>();
    const minDuration = new Map<string, number>();
    for (const p of packages) {
      if (p.price > 0 && (!minPrice.has(p.shopId) || p.price < minPrice.get(p.shopId)!)) {
        minPrice.set(p.shopId, p.price);
      }
      if (!minDuration.has(p.shopId) || p.durationMin < minDuration.get(p.shopId)!) {
        minDuration.set(p.shopId, p.durationMin);
      }
    }

    // Eng yaqin vaqt eng qisqa paket bo'yicha hisoblanadi — mijoz ko'radigan
    // "eng erta bo'sh vaqt" shu bo'ladi. Paket yo'q bo'lsa 60 daqiqa.
    const nearest = await this.nearestSlots(ids, 60);

    return shops.map((s) => ({
      ...s,
      min_price: minPrice.get(s.id) ?? null,
      nearest_slot: nearest.get(s.id) ?? null,
    }));
  }

  private sortShops(shops: any[], sort?: string) {
    switch (sort) {
      case 'price':
        // Narxi yo'qlar oxirida — bo'sh ma'lumot ro'yxat boshini egallamasin.
        shops.sort((a, b) => (a.min_price ?? Infinity) - (b.min_price ?? Infinity));
        break;
      case 'distance':
        shops.sort((a, b) => (a.distance_km || Infinity) - (b.distance_km || Infinity));
        break;
      case 'rating':
      default:
        shops.sort(
          (a, b) => b.ratingAvg - a.ratingAvg || b.ratingCount - a.ratingCount,
        );
    }
  }

  async findById(id: string) {
    const shop = await this.prisma.shopProfile.findUnique({
      where: { id },
      include: {
        user: true,
        servicePrices: { include: { serviceType: true }, where: { isActive: true } },
      },
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

  async createProfile(userId: string, data: Record<string, any>) {
    const existing = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (existing) {
      return this.updateProfile(userId, data);
    }

    return this.prisma.shopProfile.create({
      data: {
        userId,
        shopName:     data.shopName     ?? data.shop_name     ?? '',
        address:      data.address      ?? '',
        latitude:     Number(data.latitude  ?? 0),
        longitude:    Number(data.longitude ?? 0),
        phone:        data.phone        ?? '',
        workingHours: data.workingHours ?? data.working_hours ?? '09:00-18:00',
        serviceTypes: data.serviceTypes ?? data.service_types ?? [],
        verificationStatus: 'pending',
      },
      include: { user: true },
    });
  }

  async updateProfile(userId: string, data: Record<string, any>) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('Servis profili topilmadi');

    const allowed: Record<string, string> = {
      shopName: 'shopName', shop_name: 'shopName',
      address: 'address',
      latitude: 'latitude', longitude: 'longitude',
      phone: 'phone',
      workingHours: 'workingHours', working_hours: 'workingHours',
      serviceTypes: 'serviceTypes', service_types: 'serviceTypes',
    };
    const update: Record<string, any> = {};
    for (const [key, mapped] of Object.entries(allowed)) {
      if (data[key] !== undefined) update[mapped] = data[key];
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

  async getServicePrices(shopId: string) {
    return this.prisma.shopServicePrice.findMany({
      where: { shopId },
      include: { serviceType: true },
      orderBy: { serviceType: { nameUz: 'asc' } },
    });
  }

  async upsertServicePrices(shopId: string, prices: { serviceTypeId: string; priceMin: number; priceMax: number; currency?: string }[]) {
    const ops = prices.map((p) =>
      this.prisma.shopServicePrice.upsert({
        where: { shopId_serviceTypeId: { shopId, serviceTypeId: p.serviceTypeId } },
        update: { priceMin: p.priceMin, priceMax: p.priceMax, currency: p.currency ?? 'UZS', isActive: true },
        create: { shopId, serviceTypeId: p.serviceTypeId, priceMin: p.priceMin, priceMax: p.priceMax, currency: p.currency ?? 'UZS' },
        include: { serviceType: true },
      }),
    );
    return Promise.all(ops);
  }


  // ── Xizmat paketlari ────────────────────────────────────────────────────────
  // Har bir servis o'z paketlarini belgilaydi (nom, tarkib, muddat, narx).

  /// Mijoz uchun: shu servisning tanlangan xizmat bo'yicha paketlari.
  async getPackages(shopId: string, serviceTypeId?: string) {
    return this.prisma.shopServicePackage.findMany({
      where: {
        shopId,
        isActive: true,
        ...(serviceTypeId ? { serviceTypeId } : {}),
      },
      include: { serviceType: true },
      orderBy: [{ sortOrder: 'asc' }, { price: 'asc' }],
    });
  }

  /// Servis egasi uchun — nofaollari ham ko'rinadi.
  async listMyPackages(userId: string, serviceTypeId?: string) {
    const shop = await this.findByUserId(userId);
    return this.prisma.shopServicePackage.findMany({
      where: { shopId: shop.id, ...(serviceTypeId ? { serviceTypeId } : {}) },
      include: { serviceType: true },
      orderBy: [{ serviceTypeId: 'asc' }, { sortOrder: 'asc' }, { price: 'asc' }],
    });
  }

  async createPackage(userId: string, data: {
    serviceTypeId: string;
    name: string;
    description?: string;
    durationMin?: number;
    price?: number;
    currency?: string;
    sortOrder?: number;
  }) {
    const shop = await this.findByUserId(userId);
    if (!data.serviceTypeId || !data.name?.trim()) {
      throw new BadRequestException('Xizmat turi va paket nomi majburiy');
    }
    return this.prisma.shopServicePackage.create({
      data: {
        shopId: shop.id,
        serviceTypeId: data.serviceTypeId,
        name: data.name.trim(),
        description: data.description ?? '',
        durationMin: this.normalizeDuration(data.durationMin),
        price: Math.max(0, Math.floor(Number(data.price ?? 0)) || 0),
        currency: data.currency ?? 'UZS',
        sortOrder: Math.floor(Number(data.sortOrder ?? 0)) || 0,
      },
      include: { serviceType: true },
    });
  }

  async updatePackage(userId: string, id: string, data: Record<string, any>) {
    const shop = await this.findByUserId(userId);
    const pkg = await this.prisma.shopServicePackage.findFirst({
      where: { id, shopId: shop.id },
    });
    if (!pkg) throw new NotFoundException('Paket topilmadi');

    const update: Record<string, any> = {};
    if (data.name !== undefined) update.name = String(data.name).trim();
    if (data.description !== undefined) update.description = data.description;
    if (data.durationMin !== undefined) update.durationMin = this.normalizeDuration(data.durationMin);
    if (data.price !== undefined) update.price = Math.max(0, Math.floor(Number(data.price)) || 0);
    if (data.currency !== undefined) update.currency = data.currency;
    if (data.sortOrder !== undefined) update.sortOrder = Math.floor(Number(data.sortOrder)) || 0;
    if (data.isActive !== undefined) update.isActive = !!data.isActive;

    return this.prisma.shopServicePackage.update({
      where: { id },
      data: update,
      include: { serviceType: true },
    });
  }

  async deletePackage(userId: string, id: string) {
    const shop = await this.findByUserId(userId);
    const pkg = await this.prisma.shopServicePackage.findFirst({
      where: { id, shopId: shop.id },
    });
    if (!pkg) throw new NotFoundException('Paket topilmadi');
    // Bronlar bu paketga bog'langan bo'lishi mumkin — o'chirmaymiz, nofaol qilamiz.
    await this.prisma.shopServicePackage.update({
      where: { id },
      data: { isActive: false },
    });
    return { message: "Paket o'chirildi" };
  }

  private normalizeDuration(v?: number): number {
    const n = Math.floor(Number(v ?? 60));
    if (!Number.isFinite(n) || n <= 0) return 60;
    // 15 daqiqadan 8 soatgacha — bundan tashqarisi xato kiritish.
    return Math.min(Math.max(n, 15), 8 * 60);
  }


  // ── Bo'sh vaqtlar ───────────────────────────────────────────────────────────

  /// Bitta kun uchun bo'sh vaqtlar (zapis ekranidagi "ВРЕМЯ" bo'limi).
  async getAvailability(shopId: string, dateStr: string, durationMin: number) {
    const shop = await this.prisma.shopProfile.findUnique({
      where: { id: shopId },
      select: { workingHours: true },
    });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    const masters = await this.prisma.master.count({
      where: { shopId, isActive: true },
    });
    const busy = await this.busyIntervals([shopId], dateStr, 1);

    return freeSlotsForDay({
      dateStr,
      workingHours: shop.workingHours,
      durationMin,
      busy: busy.get(shopId) ?? [],
      masters,
    }).map((d) => d.toISOString());
  }

  /// Ro'yxat uchun: har bir servisning eng yaqin bo'sh vaqti
  /// ("Ближайшая запись: сегодня 11:30"). Bir nechta servis bo'yicha
  /// bitta so'rovda hisoblanadi — har biriga alohida so'rov yubormaslik uchun.
  async nearestSlots(
    shopIds: string[],
    durationMin: number,
    daysAhead = 14,
  ): Promise<Map<string, string | null>> {
    const result = new Map<string, string | null>();
    if (!shopIds.length) return result;

    const [shops, masterRows] = await Promise.all([
      this.prisma.shopProfile.findMany({
        where: { id: { in: shopIds } },
        select: { id: true, workingHours: true },
      }),
      this.prisma.master.groupBy({
        by: ['shopId'],
        where: { shopId: { in: shopIds }, isActive: true },
        _count: { _all: true },
      }),
    ]);

    const hoursById = new Map(shops.map((s) => [s.id, s.workingHours]));
    const mastersById = new Map(masterRows.map((r) => [r.shopId, r._count._all]));

    const today = localDateStr(new Date());
    const busyByShop = await this.busyIntervals(shopIds, today, daysAhead);

    for (const id of shopIds) {
      const masters = mastersById.get(id) ?? 0;
      const busy = busyByShop.get(id) ?? [];
      let found: string | null = null;

      for (let i = 0; i < daysAhead && !found; i++) {
        const d = new Date(localDayStartUtc(today).getTime() + i * 86_400_000);
        const slots = freeSlotsForDay({
          dateStr: localDateStr(d),
          workingHours: hoursById.get(id),
          durationMin,
          busy,
          masters,
        });
        if (slots.length) found = slots[0].toISOString();
      }
      result.set(id, found);
    }
    return result;
  }

  /// Berilgan kundan boshlab `days` kun ichidagi faol bronlarni servis
  /// bo'yicha guruhlab qaytaradi.
  private async busyIntervals(
    shopIds: string[],
    fromDateStr: string,
    days: number,
  ): Promise<Map<string, BusyInterval[]>> {
    const from = localDayStartUtc(fromDateStr);
    const to = new Date(from.getTime() + days * 86_400_000);

    const bookings = await this.prisma.booking.findMany({
      where: {
        shopId: { in: shopIds },
        status: { in: ['pending', 'confirmed', 'in_progress'] },
        scheduledAt: { gte: from, lt: to },
      },
      select: { shopId: true, scheduledAt: true, durationMin: true },
    });

    const map = new Map<string, BusyInterval[]>();
    for (const b of bookings) {
      const startMs = b.scheduledAt.getTime();
      const list = map.get(b.shopId) ?? [];
      list.push({ startMs, endMs: startMs + (b.durationMin || 60) * 60_000 });
      map.set(b.shopId, list);
    }
    return map;
  }

  async getBookedSlots(shopId: string, dateFrom: string, dateTo: string) {
    const bookings = await this.prisma.booking.findMany({
      where: {
        shopId,
        status: { in: ['pending', 'confirmed', 'in_progress'] },
        scheduledAt: { gte: new Date(dateFrom), lt: new Date(dateTo) },
      },
      select: { scheduledAt: true },
    });
    return bookings.map((b) => b.scheduledAt.toISOString());
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
