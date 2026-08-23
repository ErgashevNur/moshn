import { BadRequestException, ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AppConfigService } from '../app-config/app-config.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { ShopsService } from '../shops/shops.service';
import { WsHub } from '../ws/ws.hub';

const BOOKING_INCLUDE = {
  customer: true,
  package: true,
  stages: { orderBy: { sortOrder: 'asc' } },
  extras: { orderBy: { createdAt: 'asc' } },
  photos: { orderBy: { createdAt: 'asc' } },
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
    masterId?: string;
    vehicleId: string;
    serviceTypeId: string;
    packageId?: string;
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

    // Mijoz aniq ustaga yoziladi. Zapis ekranida usta tanlash yo'q
    // (maket bo'yicha) — u holda serverning o'zi shu vaqtda BO'SH ustani
    // tanlaydi. Ilova tomonida "birinchi usta"ni tanlash noto'g'ri bo'lardi:
    // u band bo'lsa ikkita bron ustma-ust tushardi.
    const master = data.masterId
      ? await this.prisma.master.findFirst({
          where: { id: data.masterId, shopId: data.shopId, isActive: true },
        })
      : await this.pickFreeMaster(data.shopId, new Date(data.scheduledAt), data.packageId);
    if (!master) {
      throw new BadRequestException(
        data.masterId
          ? 'Usta topilmadi yoki bu servisga tegishli emas'
          : "Bu vaqtda bo'sh usta yo'q",
      );
    }

    // Paket tanlangan bo'lsa — narx va davomiylik SERVERDA undan olinadi,
    // mijoz yuborgan narxga ishonilmaydi. Davomiylik bronga ko'chiriladi:
    // keyin paket o'zgarsa ham bu bron o'z vaqtini saqlaydi.
    let packageId: string | null = null;
    let durationMin = 60;
    let totalPrice = data.totalPrice ?? 0;
    // Bosqichlar paketdan bronga KO'CHIRILADI — paket keyin o'zgarsa ham
    // bu bron o'z bosqichlarini saqlaydi.
    let stageNames: string[] = [];

    if (data.packageId) {
      const pkg = await this.prisma.shopServicePackage.findFirst({
        where: {
          id: data.packageId,
          shopId: data.shopId,
          serviceTypeId: data.serviceTypeId,
          isActive: true,
        },
      });
      if (!pkg) {
        throw new BadRequestException('Paket topilmadi yoki bu xizmatga tegishli emas');
      }
      packageId = pkg.id;
      durationMin = pkg.durationMin;
      totalPrice = pkg.price;
      stageNames = (
        await this.prisma.packageStage.findMany({
          where: { packageId: pkg.id },
          orderBy: { sortOrder: 'asc' },
          select: { name: true },
        })
      ).map((x) => x.name);
    }

    const booking = await this.prisma.booking.create({
      data: {
        customerId,
        shopId: data.shopId,
        masterId: master.id,
        vehicleId: data.vehicleId,
        serviceTypeId: data.serviceTypeId,
        packageId,
        durationMin,
        scheduledAt: new Date(data.scheduledAt),
        notes: data.notes ?? '',
        totalPrice,
        status: 'pending',
        stages: {
          create: stageNames.map((name, i) => ({ name, sortOrder: i })),
        },
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

  /// Berilgan vaqtda ishi bo'lmagan faol ustani qaytaradi (yo'q bo'lsa null).
  private async pickFreeMaster(shopId: string, startAt: Date, packageId?: string) {
    let durationMin = 60;
    if (packageId) {
      const pkg = await this.prisma.shopServicePackage.findUnique({
        where: { id: packageId },
        select: { durationMin: true },
      });
      if (pkg) durationMin = pkg.durationMin;
    }
    const endAt = new Date(startAt.getTime() + durationMin * 60_000);

    const masters = await this.prisma.master.findMany({
      where: { shopId, isActive: true },
      select: { id: true },
      orderBy: { createdAt: 'asc' },
    });
    if (!masters.length) return null;

    // Shu oraliqqa tegib turgan bronlar (kesishish tekshiruvi bron
    // davomiyligini hisobga oladi).
    const overlapping = await this.prisma.booking.findMany({
      where: {
        shopId,
        status: { in: ['pending', 'confirmed', 'in_progress'] },
        scheduledAt: { lt: endAt, gte: new Date(startAt.getTime() - 8 * 60 * 60_000) },
      },
      select: { masterId: true, scheduledAt: true, durationMin: true },
    });
    const busy = new Set(
      overlapping
        .filter((b) => {
          const bEnd = b.scheduledAt.getTime() + (b.durationMin || 60) * 60_000;
          return b.scheduledAt.getTime() < endAt.getTime() && startAt.getTime() < bEnd;
        })
        .map((b) => b.masterId),
    );

    const free = masters.find((m) => !busy.has(m.id));
    return free ? this.prisma.master.findUnique({ where: { id: free.id } }) : null;
  }

  // ── Ish bosqichlari va fotohisobot ──────────────────────────────────────────

  /// Bronni faqat shu servis egasi yoki tayinlangan usta boshqara oladi.
  private async requireBookingActor(bookingId: string, userId: string) {
    const b = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { shop: { select: { userId: true } }, master: { select: { userId: true } } },
    });
    if (!b) throw new NotFoundException('Bron topilmadi');
    const allowed = b.shop.userId === userId || b.master?.userId === userId;
    if (!allowed) throw new ForbiddenException('Bu bron sizga tegishli emas');
    return b;
  }

  /// Bosqich holatini o'zgartiradi va mijozga xabar beradi.
  /// `in_progress` qo'yilganda oldingi bosqich avtomatik yakunlanadi —
  /// usta har birini alohida yopib o'tirmasin.
  async setStageStatus(
    bookingId: string,
    stageId: string,
    userId: string,
    status: string,
  ) {
    if (!['pending', 'in_progress', 'done'].includes(status)) {
      throw new BadRequestException("Noto'g'ri holat");
    }
    const booking = await this.requireBookingActor(bookingId, userId);

    const stage = await this.prisma.bookingStage.findFirst({
      where: { id: stageId, bookingId },
    });
    if (!stage) throw new NotFoundException('Bosqich topilmadi');
    // Kelishuv bosqichini usta yopa olmaydi — u faqat mijoz javob berganda
    // yopiladi (`respondToExtra`). Aks holda tasdiqlanmagan qo'shimcha ish
    // "osilib" qolardi va hisob-kitob noto'g'ri chiqardi.
    if (stage.status === 'awaiting_customer') {
      throw new BadRequestException('Mijozning javobi kutilmoqda');
    }

    const now = new Date();
    await this.prisma.$transaction(async (tx) => {
      if (status === 'in_progress') {
        await tx.bookingStage.updateMany({
          where: {
            bookingId,
            sortOrder: { lt: stage.sortOrder },
            // `awaiting_customer` ham chetlab o'tilmasin — mijoz javob
            // bermaguncha u ochiq turishi kerak.
            status: { notIn: ['done', 'awaiting_customer'] },
          },
          data: { status: 'done', completedAt: now },
        });
      }
      await tx.bookingStage.update({
        where: { id: stageId },
        data: {
          status,
          startedAt: status === 'in_progress' ? (stage.startedAt ?? now) : stage.startedAt,
          completedAt: status === 'done' ? now : null,
        },
      });
    });

    const updated = await this.getById(bookingId);
    this.wsHub.broadcastToUser(booking.customerId, 'booking_stage', updated);
    this.notifSvc.sendToUser(
      booking.customerId,
      'Ish holati yangilandi',
      `${stage.name}: ${status === 'done' ? 'bajarildi' : 'boshlandi'}`,
      'booking_stage',
      bookingId,
    );
    return updated;
  }

  /// Fotohisobotga rasm qo'shadi (usta yoki servis egasi).
  async addPhoto(bookingId: string, userId: string, url: string, stageId?: string) {
    const booking = await this.requireBookingActor(bookingId, userId);
    await this.prisma.bookingPhoto.create({
      data: { bookingId, url, stageId: stageId || null },
    });

    const updated = await this.getById(bookingId);
    this.wsHub.broadcastToUser(booking.customerId, 'booking_photo', updated);
    this.notifSvc.sendToUser(
      booking.customerId,
      'Fotohisobot',
      'Usta yangi rasm qo\'shdi',
      'booking_photo',
      bookingId,
    );
    return updated;
  }

  // ─── Qo'shimcha ish: usta taklif qiladi, mijoz tasdiqlaydi ─────────────────
  //
  // Mijoz ko'rmagan ish hisobga tushmasin — shuning uchun narx faqat
  // TASDIQLANGANDAN keyin `totalPrice` ga qo'shiladi.

  /// Kelishuv bosqichining nomi. Paketdan kelmaydi — taklif paytida
  /// bosqichlar ro'yxatiga qo'yiladi (maketdagi "Согласование доп. работ").
  private static readonly APPROVAL_STAGE = 'Согласование доп. работ';

  /// Usta ish davomida qo'shimcha ish taklif qiladi.
  async proposeExtra(bookingId: string, userId: string, name: string, price: number) {
    const clean = (name ?? '').trim();
    if (!clean) throw new BadRequestException('Ish nomi kiritilmadi');
    if (!Number.isFinite(price) || price <= 0) {
      throw new BadRequestException("Narx noto'g'ri");
    }

    const booking = await this.requireBookingActor(bookingId, userId);
    if (['completed', 'cancelled'].includes(booking.status)) {
      throw new BadRequestException("Tugagan bronga qo'shimcha ish qo'shib bo'lmaydi");
    }

    const now = new Date();
    await this.prisma.$transaction(async (tx) => {
      const stages = await tx.bookingStage.findMany({
        where: { bookingId },
        orderBy: { sortOrder: 'asc' },
      });

      // Javob kutayotgan kelishuv bosqichi bo'lsa — yangisini qo'shmaymiz,
      // taklif o'shanga ilinadi (ikkita taklif = ikkita bosqich bo'lmasin).
      let stage = stages.find((s) => s.status === 'awaiting_customer') ?? null;

      if (!stage) {
        // Maketdagi tartib: kelishuv tugagan ishlardan keyin, hozir
        // bajarilayotgan ishdan OLDIN turadi.
        const active = stages.find((s) => s.status === 'in_progress');
        const at = active ? active.sortOrder : stages.length;
        await tx.bookingStage.updateMany({
          where: { bookingId, sortOrder: { gte: at } },
          data: { sortOrder: { increment: 1 } },
        });
        stage = await tx.bookingStage.create({
          data: {
            bookingId,
            name: BookingsService.APPROVAL_STAGE,
            sortOrder: at,
            status: 'awaiting_customer',
            startedAt: now,
          },
        });
      }

      await tx.bookingExtra.create({
        data: { bookingId, stageId: stage.id, name: clean, price: Math.round(price) },
      });
    });

    const updated = await this.getById(bookingId);
    this.wsHub.broadcastToUser(booking.customerId, 'booking_extra', updated);
    this.notifSvc.sendToUser(
      booking.customerId,
      'Qo\'shimcha ish taklifi',
      `${clean} — ${Math.round(price).toLocaleString('ru-RU')} so'm. Roziligingiz kutilmoqda`,
      'booking_extra',
      bookingId,
    );
    return updated;
  }

  /// Mijoz taklifga javob beradi. `approve = true` bo'lsa narx hisobga
  /// qo'shiladi.
  async respondToExtra(bookingId: string, extraId: string, customerId: string, approve: boolean) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, customerId },
      include: { shop: { select: { userId: true } }, master: { select: { userId: true } } },
    });
    if (!booking) throw new NotFoundException('Bron topilmadi');

    const extra = await this.prisma.bookingExtra.findFirst({
      where: { id: extraId, bookingId },
    });
    if (!extra) throw new NotFoundException("Qo'shimcha ish topilmadi");
    if (extra.status !== 'proposed') {
      throw new BadRequestException('Bu taklifga allaqachon javob berilgan');
    }

    const now = new Date();
    await this.prisma.$transaction(async (tx) => {
      await tx.bookingExtra.update({
        where: { id: extraId },
        data: { status: approve ? 'approved' : 'rejected', respondedAt: now },
      });

      if (approve) {
        await tx.booking.update({
          where: { id: bookingId },
          data: { totalPrice: { increment: extra.price } },
        });
      }

      // Shu bosqichdagi barcha takliflarga javob berilgan bo'lsa —
      // kelishuv tugadi.
      if (extra.stageId) {
        const stillOpen = await tx.bookingExtra.count({
          where: { stageId: extra.stageId, status: 'proposed' },
        });
        if (stillOpen === 0) {
          await tx.bookingStage.update({
            where: { id: extra.stageId },
            data: { status: 'done', completedAt: now },
          });
        }
      }
    });

    const updated = await this.getById(bookingId);
    const title = approve ? 'Mijoz rozi bo\'ldi' : 'Mijoz rad etdi';
    for (const uid of new Set([booking.shop.userId, booking.master?.userId].filter(Boolean) as string[])) {
      this.wsHub.broadcastToUser(uid, 'booking_extra', updated);
      this.notifSvc.sendToUser(uid, title, extra.name, 'booking_extra', bookingId);
    }
    return updated;
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
