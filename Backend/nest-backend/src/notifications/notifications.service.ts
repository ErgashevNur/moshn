import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging, MulticastMessage } from 'firebase-admin/messaging';
import { PrismaService } from '../prisma/prisma.service';

const FCM_CHUNK = 500; // FCM multicast limit

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private fcmReady = false;

  constructor(private readonly prisma: PrismaService) {}

  onModuleInit() {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!raw) {
      this.logger.warn('FIREBASE_SERVICE_ACCOUNT not set — FCM push o\'chirilgan');
      return;
    }
    try {
      if (getApps().length === 0) {
        const serviceAccount = JSON.parse(raw);
        initializeApp({ credential: cert(serviceAccount) });
      }
      this.fcmReady = true;
      this.logger.log('Firebase Admin initialized ✓');
    } catch (err: any) {
      this.logger.error('Firebase init xatosi: ' + err?.message);
    }
  }

  // ─── Asosiy: bitta foydalanuvchiga yuborish ─────────────────────────────────

  async sendToUser(userId: string, title: string, body: string, type: string, referenceId: string) {
    await this.prisma.notification.create({ data: { userId, title, body, type, referenceId } });
    if (!this.fcmReady) return;

    const rows = await this.prisma.fCMToken.findMany({ where: { userId } });
    if (!rows.length) return;

    await this.pushMulticast(rows.map((r) => r.token), title, body, { type, referenceId });
  }

  async sendToShop(shopId: string, title: string, body: string, type: string, referenceId: string) {
    const shop = await this.prisma.shopProfile.findUnique({ where: { id: shopId } });
    if (!shop) return;
    await this.sendToUser(shop.userId, title, body, type, referenceId);
  }

  // ─── Barcha foydalanuvchilarga broadcast ─────────────────────────────────────

  async broadcastToAll(title: string, body: string) {
    const users = await this.prisma.user.findMany({ select: { id: true } });
    // Notification yozuvlari
    await this.prisma.notification.createMany({
      data: users.map((u) => ({ userId: u.id, title, body, type: 'broadcast', referenceId: '' })),
      skipDuplicates: true,
    });
    await this.broadcastFcmToAll(title, body);
  }

  // ─── Segment bo'yicha broadcast (marketing push) ────────────────────────────

  async broadcastToSegment(segment: string, title: string, body: string) {
    if (!segment || segment === 'all') {
      return this.broadcastToAll(title, body);
    }

    const userIds = await this.resolveSegmentUserIds(segment);
    if (!userIds.length) return;

    await this.prisma.notification.createMany({
      data: userIds.map((id) => ({ userId: id, title, body, type: 'broadcast', referenceId: '' })),
      skipDuplicates: true,
    });
    await this.pushToUserIds(userIds, title, body, { type: 'broadcast', referenceId: '' });
  }

  private async resolveSegmentUserIds(segment: string): Promise<string[]> {
    const THIRTY_DAYS_AGO = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    if (segment === 'vip') {
      const cards = await this.prisma.customerCard.findMany({
        where: { isVip: true },
        select: { customerId: true },
        distinct: ['customerId'],
      });
      return cards.map((c) => c.customerId);
    }

    if (segment === 'recent') {
      const bookings = await this.prisma.booking.findMany({
        where: { createdAt: { gte: THIRTY_DAYS_AGO } },
        select: { customerId: true },
        distinct: ['customerId'],
      });
      return bookings.map((b) => b.customerId);
    }

    if (segment === 'inactive') {
      const [owners, recentBookings] = await Promise.all([
        this.prisma.user.findMany({ where: { role: 'owner' }, select: { id: true } }),
        this.prisma.booking.findMany({
          where: { createdAt: { gte: THIRTY_DAYS_AGO } },
          select: { customerId: true },
          distinct: ['customerId'],
        }),
      ]);
      const recentIds = new Set(recentBookings.map((b) => b.customerId));
      return owners.map((o) => o.id).filter((id) => !recentIds.has(id));
    }

    return [];
  }

  // ─── Mavsum bildirshnomasi ───────────────────────────────────────────────────

  async broadcastSeasonal(rule: { id: string; name: string; messageUz: string; messageRu: string }) {
    const users = await this.prisma.user.findMany({
      where: { role: 'owner' },
      select: { id: true, language: true },
    });

    await this.prisma.notification.createMany({
      data: users.map((u) => ({
        userId: u.id,
        title: rule.name,
        body: u.language === 'ru' ? rule.messageRu : rule.messageUz,
        type: 'seasonal',
        referenceId: rule.id,
      })),
      skipDuplicates: true,
    });

    // FCM — til bo'yicha guruhlab yuborish
    const uzIds = users.filter((u) => u.language !== 'ru').map((u) => u.id);
    const ruIds = users.filter((u) => u.language === 'ru').map((u) => u.id);

    await Promise.all([
      this.pushToUserIds(uzIds, rule.name, rule.messageUz, { type: 'seasonal', referenceId: rule.id }),
      this.pushToUserIds(ruIds, rule.name, rule.messageRu, { type: 'seasonal', referenceId: rule.id }),
    ]);
  }

  // ─── O'qish ──────────────────────────────────────────────────────────────────

  async getNotifications(userId: string, limit: number, skip: number) {
    const [items, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip,
      }),
      this.prisma.notification.count({ where: { userId } }),
      this.prisma.notification.count({ where: { userId, isRead: false } }),
    ]);
    return { items, total, unreadCount };
  }

  async markAsRead(id: string, userId: string) {
    await this.prisma.notification.updateMany({ where: { id, userId }, data: { isRead: true } });
  }

  async markAllAsRead(userId: string) {
    await this.prisma.notification.updateMany({ where: { userId, isRead: false }, data: { isRead: true } });
  }

  // ─── FCM token ───────────────────────────────────────────────────────────────

  async saveFcmToken(userId: string, token: string, platform: string) {
    const existing = await this.prisma.fCMToken.findFirst({ where: { token } });
    if (existing) {
      await this.prisma.fCMToken.update({ where: { id: existing.id }, data: { userId, platform } });
    } else {
      await this.prisma.fCMToken.create({ data: { userId, token, platform } });
    }
  }

  // ─── FCM yordamchi metodlar ───────────────────────────────────────────────────

  private async broadcastFcmToAll(title: string, body: string) {
    if (!this.fcmReady) return;
    const rows = await this.prisma.fCMToken.findMany({ select: { token: true } });
    await this.pushMulticast(rows.map((r) => r.token), title, body, { type: 'broadcast', referenceId: '' });
  }

  private async pushToUserIds(userIds: string[], title: string, body: string, data: Record<string, string>) {
    if (!this.fcmReady || !userIds.length) return;
    const rows = await this.prisma.fCMToken.findMany({
      where: { userId: { in: userIds } },
      select: { token: true },
    });
    await this.pushMulticast(rows.map((r) => r.token), title, body, data);
  }

  private async pushMulticast(tokens: string[], title: string, body: string, data: Record<string, string>) {
    if (!this.fcmReady || !tokens.length) return;

    const stringData: Record<string, string> = {};
    for (const [k, v] of Object.entries(data)) stringData[k] = String(v ?? '');

    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
      const chunk = tokens.slice(i, i + FCM_CHUNK);
      try {
        const message: MulticastMessage = {
          tokens: chunk,
          notification: { title, body },
          data: stringData,
          android: { priority: 'high', notification: { sound: 'default', channelId: 'shina24_default' } },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        };
        const res = await getMessaging().sendEachForMulticast(message);

        const invalid: string[] = [];
        res.responses.forEach((r, idx) => {
          if (!r.success) {
            const code = r.error?.code ?? '';
            if (
              code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered' ||
              code === 'messaging/invalid-argument'
            ) {
              invalid.push(chunk[idx]);
            } else {
              this.logger.warn(`FCM error [${code}]: ${r.error?.message}`);
            }
          }
        });

        if (invalid.length) {
          await this.prisma.fCMToken.deleteMany({ where: { token: { in: invalid } } });
          this.logger.log(`${invalid.length} ta eskirgan FCM token o'chirildi`);
        }

        const success = res.successCount;
        if (success > 0) this.logger.debug(`FCM: ${success}/${chunk.length} yuborildi`);
      } catch (err: any) {
        this.logger.error('FCM multicast xatosi: ' + err?.message);
      }
    }
  }
}
