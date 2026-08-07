import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AppConfigService } from '../app-config/app-config.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { ShopsService } from '../shops/shops.service';
import { WsHub } from '../ws/ws.hub';

const BOOKING_INCLUDE = {
  customer: true,
  shop: { include: { user: true } },
  master: true,
  vehicle: true,
  serviceType: true,
} as const;

@Injectable()
export class BookingsService {
  private readonly logger = new Logger(BookingsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifSvc: NotificationsService,
    private readonly wsHub: WsHub,
    private readonly shopSvc: ShopsService,
    private readonly configSvc: AppConfigService,
  ) {}

  async create(customerId: string, data: {
    shopId: string;
    masterId: string;
    vehicleId: string;
    serviceTypeId: string;
    scheduledAt: string;
    notes?: string;
    totalPrice?: number;
  }) {
    const vehicle = await this.prisma.vehicle.findFirst({
      where: { id: data.vehicleId, ownerId: customerId },
    });
    if (!vehicle) throw new NotFoundException('Mashina topilmadi');

    const shop = await this.prisma.shopProfile.findFirst({
      where: { id: data.shopId },
    });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    // Mijoz aniq ustaga yoziladi — usta shu servisga tegishli va faol bo'lishi shart
    if (!data.masterId) throw new BadRequestException('Usta tanlanmagan');
    const master = await this.prisma.master.findFirst({
      where: { id: data.masterId, shopId: data.shopId, isActive: true },
    });
    if (!master) throw new BadRequestException('Usta topilmadi yoki bu servisga tegishli emas');

    const booking = await this.prisma.booking.create({
      data: {
        customerId,
        shopId: data.shopId,
        masterId: data.masterId,
        vehicleId: data.vehicleId,
        serviceTypeId: data.serviceTypeId,
        scheduledAt: new Date(data.scheduledAt),
        notes: data.notes ?? '',
        totalPrice: data.totalPrice ?? 0,
        status: 'pending',
      },
      include: BOOKING_INCLUDE,
    });

    this.wsHub.broadcastToUser(shop.userId, 'new_booking', booking);
    this.notifSvc.sendToUser(shop.userId, 'Yangi bron!', 'Yangi mijoz bron qildi', 'new_booking', booking.id);
    // Usta alohida login bo'lsa, unga ham xabar (yakka usta = egasi bo'lsa takrorlamaymiz)
    if (master.userId !== shop.userId) {
      this.wsHub.broadcastToUser(master.userId, 'new_booking', booking);
      this.notifSvc.sendToUser(master.userId, 'Yangi bron!', 'Sizga yangi mijoz yozildi', 'new_booking', booking.id);
    }
    this.shopSvc.upsertCustomerCard(data.shopId, customerId).catch(() => null);

    return booking;
  }

  async getCustomerBookings(customerId: string, status: string, limit: number, skip: number) {
    const where: any = { customerId };
    if (status) where.status = status;

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: { shop: { include: { user: true } }, vehicle: true, serviceType: true },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip,
      }),
      this.prisma.booking.count({ where }),
    ]);
    return { bookings: items, total };
  }

  async getShopBookings(userId: string, status: string, limit: number, skip: number) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    const where: any = { shopId: shop.id };
    if (status) where.status = status;

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: { customer: true, vehicle: true, serviceType: true },
        orderBy: { scheduledAt: 'asc' },
        take: limit,
        skip,
      }),
      this.prisma.booking.count({ where }),
    ]);
    return { bookings: items, total };
  }

  async getMasterBookings(masterUserId: string, status: string, limit: number, skip: number) {
    const master = await this.prisma.master.findUnique({ where: { userId: masterUserId } });
    if (!master) throw new NotFoundException('Usta profili topilmadi');

    const where: any = { masterId: master.id };
    if (status) where.status = status;

    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: { customer: true, vehicle: true, serviceType: true },
        orderBy: { scheduledAt: 'asc' },
        take: limit,
        skip,
      }),
      this.prisma.booking.count({ where }),
    ]);
    return { bookings: items, total };
  }

  async getById(id: string) {
    const b = await this.prisma.booking.findUnique({ where: { id }, include: BOOKING_INCLUDE });
    if (!b) throw new NotFoundException('Bron topilmadi');
    return b;
  }

  async cancelByCustomer(bookingId: string, customerId: string, reason?: string) {
    const b = await this.prisma.booking.findFirst({
      where: { id: bookingId, customerId, status: { in: ['pending', 'confirmed'] } },
    });
    if (!b) throw new BadRequestException("Bron topilmadi yoki bekor qilib bo'lmaydi");
    await this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'cancelled', cancelReason: reason ?? '' },
    });
  }

  async confirmByShop(bookingId: string, userId: string) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    const b = await this.prisma.booking.findFirst({
      where: { id: bookingId, shopId: shop.id, status: 'pending' },
    });
    if (!b) throw new NotFoundException('Bron topilmadi');

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'confirmed' },
      include: BOOKING_INCLUDE,
    });
    this.notifSvc.sendToUser(b.customerId, 'Bron tasdiqlandi', 'Servis broningizni tasdiqladi', 'booking_confirmed', b.id);
    return updated;
  }

  async startByShop(bookingId: string, userId: string) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    const b = await this.prisma.booking.findFirst({
      where: { id: bookingId, shopId: shop.id, status: 'confirmed' },
    });
    if (!b) throw new NotFoundException('Bron topilmadi');

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'in_progress' },
      include: BOOKING_INCLUDE,
    });
    this.notifSvc.sendToUser(b.customerId, 'Xizmat boshlandi', "Mashinangizga xizmat ko'rsatilmoqda", 'booking_started', b.id);
    return updated;
  }

  async completeByShop(bookingId: string, userId: string) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    const b = await this.prisma.booking.findFirst({
      where: { id: bookingId, shopId: shop.id, status: 'in_progress' },
    });
    if (!b) throw new NotFoundException('Bron topilmadi');

    const now = new Date();
    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'completed', completedAt: now },
      include: BOOKING_INCLUDE,
    });

    await this.prisma.shopProfile.update({
      where: { id: shop.id },
      data: { totalBookings: { increment: 1 } },
    });

    const card = await this.prisma.customerCard.findFirst({ where: { shopId: shop.id, customerId: b.customerId } });
    if (card) {
      const updatedCard = await this.prisma.customerCard.update({
        where: { id: card.id },
        data: { visitCount: { increment: 1 }, lastVisitAt: now },
      });

      // Admin "VIP chegarasi" sozlamasiga yetganda — avtomatik VIP belgilanadi
      if (!updatedCard.isVip) {
        const vipMin = await this.configSvc.getNumber('vip_min', 5);
        if (updatedCard.visitCount >= vipMin) {
          await this.prisma.customerCard.update({ where: { id: card.id }, data: { isVip: true } });
        }
      }
    }

    this.notifSvc.sendToUser(
      b.customerId,
      'Xizmat tugadi',
      "Mashinangizga xizmat ko'rsatildi. Baholang!",
      'booking_completed',
      b.id,
    );
    return updated;
  }

  async cancelByShop(bookingId: string, userId: string, reason?: string) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { userId } });
    if (!shop) throw new NotFoundException('Servis topilmadi');

    const b = await this.prisma.booking.findFirst({
      where: { id: bookingId, shopId: shop.id, status: { in: ['pending', 'confirmed'] } },
    });
    if (!b) throw new BadRequestException("Bron topilmadi");

    await this.prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'cancelled', cancelReason: reason ?? '' },
    });
    this.notifSvc.sendToUser(b.customerId, 'Bron bekor qilindi', 'Servis broningizni bekor qildi', 'booking_cancelled', b.id);
  }

  // ─── Sharh so'rash: xizmat tugaganidan 2 soat o'tgach mijozga eslatma ────────

  @Cron(CronExpression.EVERY_10_MINUTES)
  async sendReviewReminders() {
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);

    const candidates = await this.prisma.booking.findMany({
      where: {
        status: 'completed',
        completedAt: { lte: twoHoursAgo },
        reviewReminderSentAt: null,
      },
      include: { shop: true },
      take: 200,
    });

    for (const b of candidates) {
      try {
        const existingReview = await this.prisma.review.findFirst({
          where: { bookingId: b.id, reviewType: 'owner_to_shop' },
        });

        if (!existingReview) {
          this.notifSvc.sendToUser(
            b.customerId,
            'Xizmatni baholang',
            `${b.shop.shopName || 'Shinomontaj'} — xizmat sifatini baholab, fikringizni qoldiring`,
            'review_reminder',
            b.id,
          );
        }

        await this.prisma.booking.update({
          where: { id: b.id },
          data: { reviewReminderSentAt: new Date() },
        });
      } catch (err: any) {
        this.logger.error(`Review reminder xatosi (booking ${b.id}): ${err?.message}`);
      }
    }
  }
}
