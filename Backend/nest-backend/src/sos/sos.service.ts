import { randomUUID } from 'crypto';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Interval } from '@nestjs/schedule';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { WsHub } from '../ws/ws.hub';

export interface NearbyShop {
  id: string;
  shopName: string;
  distanceMeters: number;
}

interface NearbyShopRow {
  id: string;
  shop_name: string;
  working_hours: string;
  distance_meters: number;
}

export interface NearbyEvacuator {
  id: string;
  distanceMeters: number;
}

interface NearbyEvacuatorRow {
  id: string;
  distance_meters: number;
}

// To'lqinlar: 3km → 7km → 15km, har biriga ~30s (CLAUDE.md, PITGO_PLAN §3.3).
const WAVES = [
  { wave: 1, radiusMeters: 3000, afterSeconds: 0 },
  { wave: 2, radiusMeters: 7000, afterSeconds: 30 },
  { wave: 3, radiusMeters: 15000, afterSeconds: 60 },
] as const;
// Oxirgi to'lqindan keyin yana ~30s kutamiz, so'ng "usta topilmadi".
const NO_MASTER_TIMEOUT_SECONDS = 90;

// Evakuator to'lqinlari (Faza 3.7) — kengroq radius, chunki evakuatorlar
// ustaxonalarga qaraganda kamroq va butun shahar bo'ylab harakatlanadi.
const EVACUATOR_WAVES = [
  { wave: 1, radiusMeters: 5000, afterSeconds: 0 },
  { wave: 2, radiusMeters: 15000, afterSeconds: 30 },
  { wave: 3, radiusMeters: 30000, afterSeconds: 60 },
] as const;
const NO_EVACUATOR_TIMEOUT_SECONDS = 90;

const DISPATCH_TICK_MS = 10_000;

// Qabul qilingandan keyingi hayot davri (Faza 3.5) — faqat shu tartibda,
// bittalab oldinga siljiydi. Usta va evakuator uchun bir xil (kim qabul
// qilgani `acceptedMasterId`/`acceptedEvacuatorId`dan ma'lum).
const PROGRESS_ORDER = ['accepted', 'on_the_way', 'arrived', 'completed'];

const PROGRESS_NOTIFICATIONS: Record<string, { title: string; body: string }> = {
  on_the_way: { title: "Yordam yo'lda", body: "Sizga qarab yo'lga chiqishdi" },
  arrived: { title: 'Yordam yetib keldi', body: 'Manzilingizga yetib kelishdi' },
  completed: { title: 'Xizmat yakunlandi', body: 'SOS chaqiruvi yakunlandi' },
};

@Injectable()
export class SosService {
  private readonly logger = new Logger(SosService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly wsHub: WsHub,
    private readonly notifSvc: NotificationsService,
  ) {}

  // ── Geo-qidiruv (Faza 3.2) ──────────────────────────────────────────────────

  /**
   * Berilgan nuqta atrofida (radiusMeters) `serviceTypeId` xizmatini
   * ko'rsatadigan, kamida bitta faol ustasi bor va hozir ochiq servislarni
   * qaytaradi. ST_DWithin GiST indexdan foydalanadi (CLAUDE.md §8.1).
   * Masofa bo'yicha tartiblash bazada emas — natija radius bilan
   * cheklangani uchun kichik, tartiblash ilova kodida bajariladi.
   */
  async findNearbyShops(
    lat: number,
    lng: number,
    radiusMeters: number,
    serviceTypeId: string,
    excludeShopIds: string[] = [],
  ): Promise<NearbyShop[]> {
    const rows = await this.prisma.$queryRaw<NearbyShopRow[]>`
      SELECT
        sp.id,
        sp.shop_name,
        sp.working_hours,
        ST_Distance(sp.location, ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography) AS distance_meters
      FROM shop_profiles sp
      WHERE sp.verification_status IN ('verified', 'pending')
        AND sp.location IS NOT NULL
        AND ST_DWithin(
          sp.location,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          ${radiusMeters}
        )
        AND NOT (sp.id = ANY (${excludeShopIds}::uuid[]))
        AND EXISTS (
          SELECT 1 FROM masters m
          JOIN master_service_types mst ON mst.master_id = m.id
          WHERE m.shop_id = sp.id
            AND m.is_active = true
            AND mst.service_type_id = ${serviceTypeId}::uuid
        )
      LIMIT 200
    `;

    return rows
      .filter((r) => isShopOpenNow(r.working_hours))
      .map((r) => ({
        id: r.id,
        shopName: r.shop_name,
        distanceMeters: Math.round(Number(r.distance_meters)),
      }))
      .sort((a, b) => a.distanceMeters - b.distanceMeters);
  }

  /**
   * Berilgan nuqta atrofida onlayn (isAvailable) evakuatorlarni qaytaradi
   * (Faza 3.7). Ustaxonalardan farqli — xizmat turi filtri yo'q, ish vaqti
   * yo'q (evakuator o'zi onlayn/oflayn holatini boshqaradi).
   */
  async findNearbyEvacuators(
    lat: number,
    lng: number,
    radiusMeters: number,
    excludeEvacuatorIds: string[] = [],
  ): Promise<NearbyEvacuator[]> {
    const rows = await this.prisma.$queryRaw<NearbyEvacuatorRow[]>`
      SELECT
        e.id,
        ST_Distance(e.location, ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography) AS distance_meters
      FROM evacuators e
      WHERE e.is_active = true
        AND e.is_available = true
        AND e.location IS NOT NULL
        AND ST_DWithin(
          e.location,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          ${radiusMeters}
        )
        AND NOT (e.id = ANY (${excludeEvacuatorIds}::uuid[]))
      LIMIT 200
    `;

    return rows
      .map((r) => ({ id: r.id, distanceMeters: Math.round(Number(r.distance_meters)) }))
      .sort((a, b) => a.distanceMeters - b.distanceMeters);
  }

  // ── SOS so'rovi va tarqatish (Faza 3.3) ─────────────────────────────────────

  async createSosRequest(
    customerId: string,
    data: { vehicleId: string; serviceTypeId: string; lat: number; lng: number },
  ) {
    const vehicle = await this.prisma.vehicle.findFirst({
      where: { id: data.vehicleId, ownerId: customerId },
    });
    if (!vehicle) throw new NotFoundException('Avtomobil topilmadi');

    const serviceType = await this.prisma.serviceType.findUnique({
      where: { id: data.serviceTypeId },
    });
    if (!serviceType) throw new NotFoundException('Xizmat turi topilmadi');

    const id = randomUUID();
    await this.prisma.$executeRaw`
      INSERT INTO sos_requests (id, customer_id, vehicle_id, service_type_id, location, status, created_at, updated_at)
      VALUES (
        ${id}::uuid, ${customerId}::uuid, ${data.vehicleId}::uuid, ${data.serviceTypeId}::uuid,
        ST_SetSRID(ST_MakePoint(${data.lng}, ${data.lat}), 4326)::geography,
        'pending', now(), now()
      )
    `;

    // Birinchi to'lqin darhol yuboriladi — keyingilarini tick tsikli boshqaradi.
    await this.processRequest(id);
    return this.getStatus(id);
  }

  async getStatus(sosRequestId: string) {
    const request = await this.prisma.sosRequest.findUnique({
      where: { id: sosRequestId },
      select: {
        id: true,
        status: true,
        dispatchMode: true,
        serviceTypeId: true,
        acceptedMasterId: true,
        acceptedEvacuatorId: true,
        createdAt: true,
        updatedAt: true,
        serviceType: { select: { nameUz: true, nameRu: true, slug: true, icon: true } },
        // Usta/evakuator kimga ketayotganini ko'rishi uchun (Faza 3.6 — detali).
        customer: { select: { fullName: true, phone: true } },
        vehicle: { select: { plate: true, make: true, model: true } },
        // Qabul qilingandan keyin mijoz kimga ketayotganini ko'rishi uchun
        // (Faza 3.6 — tracking ekrani).
        acceptedMaster: {
          select: {
            id: true,
            fullName: true,
            avatarUrl: true,
            ratingAvg: true,
            shop: { select: { shopName: true, phone: true, address: true } },
          },
        },
        // Faza 3.7 — evakuator qabul qilgan bo'lsa.
        acceptedEvacuator: {
          select: {
            id: true,
            fullName: true,
            phone: true,
            vehiclePlate: true,
            ratingAvg: true,
          },
        },
        // Faza 3.8 — xizmat yakunlangach kiritilgan narx/to'lov holati.
        payment: {
          select: { id: true, amount: true, method: true, status: true, qrCode: true, paidAt: true },
        },
      },
    });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");

    const dispatches = await this.prisma.sosDispatch.findMany({
      where: { sosRequestId },
      orderBy: [{ wave: 'asc' }, { sentAt: 'asc' }],
    });
    return { ...request, dispatches };
  }

  /** Usta ilova ochganda "joriy ish"ini topib olishi uchun (Faza 3.6). */
  async getActiveForMaster(masterUserId: string) {
    const master = await this.prisma.master.findUnique({ where: { userId: masterUserId } });
    if (!master) throw new NotFoundException('Usta profili topilmadi');

    const request = await this.prisma.sosRequest.findFirst({
      where: { acceptedMasterId: master.id, status: { in: ['accepted', 'on_the_way', 'arrived'] } },
      orderBy: { createdAt: 'desc' },
      select: { id: true },
    });
    if (!request) return null;
    return this.getStatus(request.id);
  }

  /** Evakuator ilova ochganda "joriy ish"ini topib olishi uchun (Faza 3.7). */
  async getActiveForEvacuator(evacuatorUserId: string) {
    const evacuator = await this.prisma.evacuator.findUnique({ where: { userId: evacuatorUserId } });
    if (!evacuator) throw new NotFoundException('Evakuator profili topilmadi');

    const request = await this.prisma.sosRequest.findFirst({
      where: { acceptedEvacuatorId: evacuator.id, status: { in: ['accepted', 'on_the_way', 'arrived'] } },
      orderBy: { createdAt: 'desc' },
      select: { id: true },
    });
    if (!request) return null;
    return this.getStatus(request.id);
  }

  /**
   * "Evakuator chaqirish" — faqat oddiy tarqatish hech kimni topa
   * olmagandan keyin (`no_master_found`) ochiladi (CLAUDE.md §5). Xuddi
   * shu SosRequest'ni "evacuator" rejimiga o'tkazadi va to'lqin hisobini
   * `evacuatorRequestedAt`dan qayta boshlaydi.
   */
  async requestEvacuator(customerId: string, sosRequestId: string) {
    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");
    if (request.customerId !== customerId) throw new ForbiddenException("Bu so'rov sizga tegishli emas");
    if (request.status !== 'no_master_found') {
      throw new BadRequestException("Evakuator faqat usta topilmagandan keyin chaqirilishi mumkin");
    }

    await this.prisma.sosRequest.update({
      where: { id: sosRequestId },
      data: { status: 'dispatching', dispatchMode: 'evacuator', evacuatorRequestedAt: new Date() },
    });

    await this.processRequest(sosRequestId);
    return this.getStatus(sosRequestId);
  }

  /**
   * Har ~10s'da barcha faol (pending/dispatching) so'rovlarni qayta ko'rib
   * chiqadi. Holat butunlay bazadan (createdAt + mavjud dispatch yozuvlari)
   * hisoblanadi — server qayta ishga tushsa ham keyingi tsiklda aynan
   * qayerda to'xtaganini xotirasiz tiklaydi (PITGO_PLAN §3.3).
   */
  @Interval(DISPATCH_TICK_MS)
  async tickDispatchLoop() {
    const active = await this.prisma.sosRequest.findMany({
      where: { status: { in: ['pending', 'dispatching'] } },
      select: { id: true },
    });
    for (const r of active) {
      try {
        await this.processRequest(r.id);
      } catch (err: any) {
        this.logger.error(`SOS tick xatosi (${r.id}): ${err?.message}`);
      }
    }
  }

  private async processRequest(sosRequestId: string) {
    const [row] = await this.prisma.$queryRaw<
      {
        id: string;
        status: string;
        dispatch_mode: string;
        service_type_id: string;
        created_at: Date;
        evacuator_requested_at: Date | null;
        lat: number;
        lng: number;
      }[]
    >`
      SELECT id, status, dispatch_mode, service_type_id, created_at, evacuator_requested_at,
             ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng
      FROM sos_requests WHERE id = ${sosRequestId}::uuid
    `;
    if (!row || !['pending', 'dispatching'].includes(row.status)) return;

    if (row.dispatch_mode === 'evacuator') {
      await this.processEvacuatorWave(row);
    } else {
      await this.processShopWave(row);
    }
  }

  private async processShopWave(row: {
    id: string;
    status: string;
    service_type_id: string;
    created_at: Date;
    lat: number;
    lng: number;
  }) {
    const sosRequestId = row.id;
    const elapsedSeconds = (Date.now() - new Date(row.created_at).getTime()) / 1000;

    const existing = await this.prisma.sosDispatch.findMany({
      where: { sosRequestId, shopId: { not: null } },
      select: { shopId: true, wave: true },
    });
    const dispatchedShopIds = existing.map((d) => d.shopId!);
    const maxWaveDispatched = existing.reduce((max, d) => Math.max(max, d.wave), 0);

    const targetWave = [...WAVES].reverse().find((w) => elapsedSeconds >= w.afterSeconds);

    if (targetWave && targetWave.wave > maxWaveDispatched) {
      const nearby = await this.findNearbyShops(
        row.lat,
        row.lng,
        targetWave.radiusMeters,
        row.service_type_id,
        dispatchedShopIds,
      );

      if (nearby.length) {
        await this.prisma.sosDispatch.createMany({
          data: nearby.map((s) => ({
            sosRequestId,
            shopId: s.id,
            wave: targetWave.wave,
            distanceMeters: s.distanceMeters,
          })),
        });
        await this.notifyShops(sosRequestId, nearby, targetWave.wave);
      }

      if (row.status === 'pending') {
        await this.prisma.sosRequest.update({ where: { id: sosRequestId }, data: { status: 'dispatching' } });
      }
    }

    if (elapsedSeconds >= NO_MASTER_TIMEOUT_SECONDS) {
      await this.prisma.$transaction([
        this.prisma.sosRequest.updateMany({
          where: { id: sosRequestId, status: { in: ['pending', 'dispatching'] } },
          data: { status: 'no_master_found' },
        }),
        this.prisma.sosDispatch.updateMany({
          where: { sosRequestId, shopId: { not: null }, status: 'sent' },
          data: { status: 'expired', respondedAt: new Date() },
        }),
      ]);
    }
  }

  /** Faza 3.7 — SosRequest 'evacuator' rejimida bo'lganda to'lqin bosqichi. */
  private async processEvacuatorWave(row: {
    id: string;
    status: string;
    evacuator_requested_at: Date | null;
    lat: number;
    lng: number;
  }) {
    if (!row.evacuator_requested_at) return;
    const sosRequestId = row.id;
    const elapsedSeconds = (Date.now() - new Date(row.evacuator_requested_at).getTime()) / 1000;

    const existing = await this.prisma.sosDispatch.findMany({
      where: { sosRequestId, evacuatorId: { not: null } },
      select: { evacuatorId: true, wave: true },
    });
    const dispatchedEvacuatorIds = existing.map((d) => d.evacuatorId!);
    const maxWaveDispatched = existing.reduce((max, d) => Math.max(max, d.wave), 0);

    const targetWave = [...EVACUATOR_WAVES].reverse().find((w) => elapsedSeconds >= w.afterSeconds);

    if (targetWave && targetWave.wave > maxWaveDispatched) {
      const nearby = await this.findNearbyEvacuators(
        row.lat,
        row.lng,
        targetWave.radiusMeters,
        dispatchedEvacuatorIds,
      );

      if (nearby.length) {
        await this.prisma.sosDispatch.createMany({
          data: nearby.map((e) => ({
            sosRequestId,
            evacuatorId: e.id,
            wave: targetWave.wave,
            distanceMeters: e.distanceMeters,
          })),
        });
        await this.notifyEvacuators(sosRequestId, nearby, targetWave.wave);
      }
    }

    if (elapsedSeconds >= NO_EVACUATOR_TIMEOUT_SECONDS) {
      await this.prisma.$transaction([
        this.prisma.sosRequest.updateMany({
          where: { id: sosRequestId, status: { in: ['pending', 'dispatching'] } },
          data: { status: 'no_evacuator_found' },
        }),
        this.prisma.sosDispatch.updateMany({
          where: { sosRequestId, evacuatorId: { not: null }, status: 'sent' },
          data: { status: 'expired', respondedAt: new Date() },
        }),
      ]);
    }
  }

  // ── Qabul qilish (Faza 3.4) ──────────────────────────────────────────────────

  /**
   * Usta tomonidan qabul qilish. Race condition himoyasi — atomik
   * `UPDATE ... WHERE status IN (...)`: ikki usta bir vaqtda bossa, faqat
   * birinchisi `affected=1` oladi, ikkinchisiga "kech qoldingiz" (CLAUDE.md §8.2).
   */
  async acceptSosRequest(masterUserId: string, sosRequestId: string) {
    const master = await this.prisma.master.findUnique({ where: { userId: masterUserId } });
    if (!master || !master.isActive) throw new NotFoundException('Usta profili topilmadi');

    const dispatch = await this.prisma.sosDispatch.findFirst({
      where: { sosRequestId, shopId: master.shopId },
    });
    if (!dispatch) throw new NotFoundException("Bu SOS so'rovi sizning servisingizga yuborilmagan");

    const affected = await this.prisma.$executeRaw`
      UPDATE sos_requests
         SET status = 'accepted', accepted_master_id = ${master.id}::uuid, updated_at = now()
       WHERE id = ${sosRequestId}::uuid AND status IN ('pending', 'dispatching')
    `;
    if (affected === 0) {
      throw new ConflictException("Kech qoldingiz — bu so'rovni boshqa usta oldi yoki u tugagan");
    }

    await this.prisma.sosDispatch.updateMany({
      where: { sosRequestId, shopId: master.shopId },
      data: { status: 'accepted', respondedAt: new Date() },
    });
    await this.markOthersTaken(sosRequestId, master.shopId);

    return this.getStatus(sosRequestId);
  }

  async listForMaster(masterUserId: string) {
    const master = await this.prisma.master.findUnique({ where: { userId: masterUserId } });
    if (!master) throw new NotFoundException('Usta profili topilmadi');

    const dispatches = await this.prisma.sosDispatch.findMany({
      where: {
        shopId: master.shopId,
        status: 'sent',
        sosRequest: { status: { in: ['pending', 'dispatching'] } },
      },
      include: {
        sosRequest: {
          include: { serviceType: true, vehicle: true, customer: { select: { fullName: true, phone: true } } },
        },
      },
      orderBy: { sentAt: 'desc' },
    });

    return dispatches.map((d) => ({
      dispatchId: d.id,
      sosRequestId: d.sosRequestId,
      wave: d.wave,
      distanceMeters: d.distanceMeters,
      sentAt: d.sentAt,
      serviceType: d.sosRequest.serviceType,
      vehicle: d.sosRequest.vehicle,
      customer: d.sosRequest.customer,
    }));
  }

  /**
   * Evakuator tomonidan qabul qilish (Faza 3.7) — xuddi shu atomik
   * himoya (§8.2), faqat `accepted_evacuator_id` ustunida.
   */
  async acceptAsEvacuator(evacuatorUserId: string, sosRequestId: string) {
    const evacuator = await this.prisma.evacuator.findUnique({ where: { userId: evacuatorUserId } });
    if (!evacuator || !evacuator.isActive) throw new NotFoundException('Evakuator profili topilmadi');

    const dispatch = await this.prisma.sosDispatch.findFirst({
      where: { sosRequestId, evacuatorId: evacuator.id },
    });
    if (!dispatch) throw new NotFoundException("Bu so'rov sizga yuborilmagan");

    const affected = await this.prisma.$executeRaw`
      UPDATE sos_requests
         SET status = 'accepted', accepted_evacuator_id = ${evacuator.id}::uuid, updated_at = now()
       WHERE id = ${sosRequestId}::uuid AND status IN ('pending', 'dispatching')
    `;
    if (affected === 0) {
      throw new ConflictException("Kech qoldingiz — bu so'rovni boshqa evakuator oldi yoki u tugagan");
    }

    await this.prisma.sosDispatch.updateMany({
      where: { sosRequestId, evacuatorId: evacuator.id },
      data: { status: 'accepted', respondedAt: new Date() },
    });
    await this.markOtherEvacuatorsTaken(sosRequestId, evacuator.id);

    return this.getStatus(sosRequestId);
  }

  async listForEvacuator(evacuatorUserId: string) {
    const evacuator = await this.prisma.evacuator.findUnique({ where: { userId: evacuatorUserId } });
    if (!evacuator) throw new NotFoundException('Evakuator profili topilmadi');

    const dispatches = await this.prisma.sosDispatch.findMany({
      where: {
        evacuatorId: evacuator.id,
        status: 'sent',
        sosRequest: { status: { in: ['pending', 'dispatching'] } },
      },
      include: {
        sosRequest: {
          include: { serviceType: true, vehicle: true, customer: { select: { fullName: true, phone: true } } },
        },
      },
      orderBy: { sentAt: 'desc' },
    });

    return dispatches.map((d) => ({
      dispatchId: d.id,
      sosRequestId: d.sosRequestId,
      wave: d.wave,
      distanceMeters: d.distanceMeters,
      sentAt: d.sentAt,
      serviceType: d.sosRequest.serviceType,
      vehicle: d.sosRequest.vehicle,
      customer: d.sosRequest.customer,
    }));
  }

  // ── Kuzatuv va yakun (Faza 3.5) ──────────────────────────────────────────────

  /**
   * Qabul qilgan tomon (usta yoki evakuator) holatni bittalab oldinga
   * suradi: accepted → on_the_way → arrived → completed.
   */
  async updateProgress(actorUserId: string, sosRequestId: string, nextStatus: string) {
    if (!PROGRESS_NOTIFICATIONS[nextStatus]) {
      throw new BadRequestException("Noto'g'ri holat");
    }

    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");

    const acceptedActorUserId = await this.getAcceptedActorUserId(request);
    if (!acceptedActorUserId || acceptedActorUserId !== actorUserId) {
      throw new ForbiddenException("Bu so'rov sizga tegishli emas");
    }

    const currentIdx = PROGRESS_ORDER.indexOf(request.status);
    const nextIdx = PROGRESS_ORDER.indexOf(nextStatus);
    if (currentIdx === -1 || nextIdx !== currentIdx + 1) {
      throw new BadRequestException(`Holatni "${request.status}"dan "${nextStatus}"ga o'tkazib bo'lmaydi`);
    }

    await this.prisma.sosRequest.update({ where: { id: sosRequestId }, data: { status: nextStatus } });

    const notif = PROGRESS_NOTIFICATIONS[nextStatus];
    this.wsHub.broadcastToUser(request.customerId, 'sos_status', { sosRequestId, status: nextStatus });
    this.notifSvc
      .sendToUser(request.customerId, notif.title, notif.body, 'sos_status', sosRequestId)
      .catch((err) => this.logger.error(`SOS status push xatosi: ${err?.message}`));

    return this.getStatus(sosRequestId);
  }

  /** Mijoz so'rovni bekor qiladi — hali qabul qilinmagan yoki qabul qilingan bo'lsa ham. */
  async cancelSosRequest(customerId: string, sosRequestId: string) {
    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");
    if (request.customerId !== customerId) throw new ForbiddenException('Bu so\'rov sizga tegishli emas');
    if (['completed', 'cancelled', 'no_master_found', 'no_evacuator_found'].includes(request.status)) {
      throw new BadRequestException("Bu so'rovni endi bekor qilib bo'lmaydi");
    }

    const wasAccepted = !!(request.acceptedMasterId || request.acceptedEvacuatorId);

    await this.prisma.sosRequest.update({ where: { id: sosRequestId }, data: { status: 'cancelled' } });
    await this.prisma.sosDispatch.updateMany({
      where: { sosRequestId, status: 'sent' },
      data: { status: 'expired', respondedAt: new Date() },
    });

    if (wasAccepted) {
      const actorUserId = await this.getAcceptedActorUserId(request);
      if (actorUserId) this.wsHub.broadcastToUser(actorUserId, 'sos_cancelled', { sosRequestId });
    } else if (request.dispatchMode === 'evacuator') {
      const evacuatorIds = [
        ...new Set(
          (
            await this.prisma.sosDispatch.findMany({
              where: { sosRequestId, evacuatorId: { not: null } },
              select: { evacuatorId: true },
            })
          ).map((d) => d.evacuatorId!),
        ),
      ];
      const recipients = await this.getEvacuatorRecipientUserIds(evacuatorIds);
      for (const userId of recipients) this.wsHub.broadcastToUser(userId, 'sos_cancelled', { sosRequestId });
    } else {
      const shopIds = [
        ...new Set(
          (
            await this.prisma.sosDispatch.findMany({
              where: { sosRequestId, shopId: { not: null } },
              select: { shopId: true },
            })
          ).map((d) => d.shopId!),
        ),
      ];
      const recipients = await this.getShopRecipientUserIds(shopIds);
      for (const userId of recipients) this.wsHub.broadcastToUser(userId, 'sos_cancelled', { sosRequestId });
    }

    return this.getStatus(sosRequestId);
  }

  /**
   * "Men mashinamga nima bo'lganini bilmayman" tugmasi (2026-08-08 jamoa
   * qarori) — ichki texqo'llab-quvvatlashga signal, tashqi raqamga emas.
   */
  async requestUnknownIssueSupport(customerId: string, sosRequestId: string) {
    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");
    if (request.customerId !== customerId) throw new ForbiddenException("Bu so'rov sizga tegishli emas");

    this.wsHub.broadcastToAdmins('sos_support_needed', { sosRequestId, customerId });

    const admins = await this.prisma.user.findMany({ where: { role: 'admin' }, select: { id: true } });
    await Promise.all(
      admins.map((a) =>
        this.notifSvc
          .sendToUser(
            a.id,
            'SOS: mijoz yordam so\'ramoqda',
            'Mijoz "mashinamga nima bo\'lganini bilmayman" tugmasini bosdi',
            'sos_support_needed',
            sosRequestId,
          )
          .catch((err) => this.logger.error(`SOS support push xatosi: ${err?.message}`)),
      ),
    );

    return { message: "Qo'llab-quvvatlashga xabar yuborildi" };
  }

  // ── Chat (Faza 3.5, mavjud WebSocket Gateway ustiga) ────────────────────────

  async sendMessage(senderUserId: string, sosRequestId: string, body: string) {
    const text = (body ?? '').trim();
    if (!text) throw new BadRequestException("Xabar bo'sh bo'lishi mumkin emas");

    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");

    const acceptedActorUserId = await this.getAcceptedActorUserId(request);
    if (!acceptedActorUserId) {
      throw new BadRequestException("Chat faqat so'rov qabul qilingandan keyin ochiladi");
    }

    const isCustomer = request.customerId === senderUserId;
    const isAcceptedActor = acceptedActorUserId === senderUserId;
    if (!isCustomer && !isAcceptedActor) {
      throw new ForbiddenException("Faqat mijoz yoki qabul qilgan tomon yozishi mumkin");
    }

    const message = await this.prisma.sosMessage.create({
      data: { sosRequestId, senderUserId, body: text },
    });

    const recipientUserId = isCustomer ? acceptedActorUserId : request.customerId;
    this.wsHub.broadcastToUser(recipientUserId, 'sos_message', message);
    this.notifSvc
      .sendToUser(recipientUserId, 'Yangi xabar', text.slice(0, 80), 'sos_message', sosRequestId)
      .catch((err) => this.logger.error(`SOS chat push xatosi: ${err?.message}`));

    return message;
  }

  async getMessages(userId: string, sosRequestId: string) {
    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");

    const acceptedActorUserId = await this.getAcceptedActorUserId(request);
    const allowed = request.customerId === userId || acceptedActorUserId === userId;
    if (!allowed) throw new ForbiddenException('Ruxsat yo\'q');

    return this.prisma.sosMessage.findMany({ where: { sosRequestId }, orderBy: { createdAt: 'asc' } });
  }

  // ── To'lov (Faza 3.8) ────────────────────────────────────────────────────
  // Jamoa qarori (PITGO_PLAN §"HAL QILINGAN SAVOLLAR"): xizmat completed
  // bo'lgach qabul qilgan tomon narxni kiritadi, mijoz shu summani QR/NFC
  // orqali (ilova tashqarisida, to'g'ridan-to'g'ri usta hisobiga) to'laydi.
  // Real to'lov provayderi hali tanlanmagan — MVP: narx + mock QR-satr +
  // mijozning o'zi "to'ladim" deb tasdiqlashi (xuddi mavjud Booking to'lov
  // ekrani — PaymentScreen/PaymentsService — bilan bir xil andoza).

  /** Qabul qilgan tomon (usta/evakuator) yakuniy narxni kiritadi — faqat bir marta, faqat 'completed' holatda. */
  async setPrice(actorUserId: string, sosRequestId: string, amount: number) {
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException("Narx noto'g'ri");
    }

    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");

    const acceptedActorUserId = await this.getAcceptedActorUserId(request);
    if (!acceptedActorUserId || acceptedActorUserId !== actorUserId) {
      throw new ForbiddenException("Bu so'rov sizga tegishli emas");
    }
    if (request.status !== 'completed') {
      throw new BadRequestException("Narx faqat xizmat yakunlangandan keyin kiritiladi");
    }

    const existing = await this.prisma.payment.findUnique({ where: { sosRequestId } });
    if (existing) throw new BadRequestException('Narx allaqachon kiritilgan');

    const roundedAmount = Math.round(amount);
    await this.prisma.payment.create({
      data: {
        sosRequestId,
        amount: roundedAmount,
        method: 'card_qr',
        status: 'pending',
        qrCode: `pitgo://pay/sos/${sosRequestId}/${roundedAmount}`,
      },
    });

    this.wsHub.broadcastToUser(request.customerId, 'sos_payment_ready', { sosRequestId, amount: roundedAmount });
    this.notifSvc
      .sendToUser(
        request.customerId,
        "To'lov kutilmoqda",
        `Xizmat narxi: ${roundedAmount} so'm`,
        'sos_payment_ready',
        sosRequestId,
      )
      .catch((err) => this.logger.error(`SOS to'lov push xatosi: ${err?.message}`));

    return this.getStatus(sosRequestId);
  }

  /** Mijoz to'lovni tasdiqlaydi (real gateway hali yo'q — MVP qo'lda tasdiqlash). */
  async confirmPayment(customerId: string, sosRequestId: string, method: string) {
    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");
    if (request.customerId !== customerId) throw new ForbiddenException("Bu so'rov sizga tegishli emas");

    const payment = await this.prisma.payment.findUnique({ where: { sosRequestId } });
    if (!payment) throw new NotFoundException("To'lov hali kiritilmagan");

    if (payment.status !== 'paid') {
      await this.prisma.payment.update({
        where: { id: payment.id },
        data: { status: 'paid', paidAt: new Date(), method: method || payment.method },
      });

      const acceptedActorUserId = await this.getAcceptedActorUserId(request);
      if (acceptedActorUserId) {
        this.wsHub.broadcastToUser(acceptedActorUserId, 'sos_payment_paid', { sosRequestId });
        this.notifSvc
          .sendToUser(acceptedActorUserId, "To'lov qabul qilindi", `${payment.amount} so'm to'landi`, 'sos_payment_paid', sosRequestId)
          .catch((err) => this.logger.error(`SOS to'lov push xatosi: ${err?.message}`));
      }
    }

    return this.getStatus(sosRequestId);
  }

  /** Mijoz qabul qilgan tomonga chayevoy qoldiradi. */
  async addTip(customerId: string, sosRequestId: string, amount: number) {
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException("Chayevoy miqdori noto'g'ri");
    }
    const request = await this.prisma.sosRequest.findUnique({ where: { id: sosRequestId } });
    if (!request) throw new NotFoundException("SOS so'rovi topilmadi");
    if (request.customerId !== customerId) throw new ForbiddenException("Bu so'rov sizga tegishli emas");

    return this.prisma.tip.create({ data: { sosRequestId, amount: Math.round(amount) } });
  }

  /** Qabul qilgan tomonning (usta yoki evakuator) userId'sini topadi. */
  private async getAcceptedActorUserId(request: {
    acceptedMasterId: string | null;
    acceptedEvacuatorId: string | null;
  }): Promise<string | null> {
    if (request.acceptedMasterId) {
      const master = await this.prisma.master.findUnique({
        where: { id: request.acceptedMasterId },
        select: { userId: true },
      });
      return master?.userId ?? null;
    }
    if (request.acceptedEvacuatorId) {
      const evacuator = await this.prisma.evacuator.findUnique({
        where: { id: request.acceptedEvacuatorId },
        select: { userId: true },
      });
      return evacuator?.userId ?? null;
    }
    return null;
  }

  // ── WebSocket/push bildirishnomalari ────────────────────────────────────────

  private async notifyShops(sosRequestId: string, shops: NearbyShop[], wave: number) {
    const recipients = await this.getShopRecipientUserIds(shops.map((s) => s.id));
    for (const userId of recipients) {
      this.wsHub.broadcastToUser(userId, 'sos_dispatch', { sosRequestId, wave });
      this.notifSvc
        .sendToUser(userId, 'SOS chaqiruv!', 'Yaqin atrofda mijozga yordam kerak', 'sos_dispatch', sosRequestId)
        .catch((err) => this.logger.error(`SOS push xatosi (${userId}): ${err?.message}`));
    }
  }

  /** Qabul qilinganidan keyin qolgan servislarga "olib bo'lindi" signali (§3.5 bilan bog'liq). */
  private async markOthersTaken(sosRequestId: string, acceptedShopId: string) {
    const others = await this.prisma.sosDispatch.findMany({
      where: { sosRequestId, shopId: { not: acceptedShopId }, status: 'sent' },
      select: { shopId: true },
      distinct: ['shopId'],
    });
    if (!others.length) return;

    await this.prisma.sosDispatch.updateMany({
      where: { sosRequestId, shopId: { not: acceptedShopId }, status: 'sent' },
      data: { status: 'taken', respondedAt: new Date() },
    });

    const recipients = await this.getShopRecipientUserIds(others.map((o) => o.shopId));
    for (const userId of recipients) {
      this.wsHub.broadcastToUser(userId, 'sos_taken', { sosRequestId });
    }
  }

  private async getShopRecipientUserIds(shopIds: string[]): Promise<string[]> {
    const shopRows = await this.prisma.shopProfile.findMany({
      where: { id: { in: shopIds } },
      select: { userId: true, masters: { where: { isActive: true }, select: { userId: true } } },
    });
    const ids = new Set<string>();
    for (const shop of shopRows) {
      ids.add(shop.userId);
      for (const m of shop.masters) ids.add(m.userId);
    }
    return [...ids];
  }

  private async notifyEvacuators(sosRequestId: string, evacuators: NearbyEvacuator[], wave: number) {
    const recipients = await this.getEvacuatorRecipientUserIds(evacuators.map((e) => e.id));
    for (const userId of recipients) {
      this.wsHub.broadcastToUser(userId, 'sos_dispatch', { sosRequestId, wave, evacuator: true });
      this.notifSvc
        .sendToUser(userId, 'Evakuator chaqiruvi!', 'Yaqin atrofda mijozga yordam kerak', 'sos_dispatch', sosRequestId)
        .catch((err) => this.logger.error(`Evakuator push xatosi (${userId}): ${err?.message}`));
    }
  }

  /** Qabul qilinganidan keyin qolgan evakuatorlarga "olib bo'lindi" signali. */
  private async markOtherEvacuatorsTaken(sosRequestId: string, acceptedEvacuatorId: string) {
    const others = await this.prisma.sosDispatch.findMany({
      where: { sosRequestId, evacuatorId: { not: acceptedEvacuatorId }, status: 'sent' },
      select: { evacuatorId: true },
      distinct: ['evacuatorId'],
    });
    if (!others.length) return;

    await this.prisma.sosDispatch.updateMany({
      where: { sosRequestId, evacuatorId: { not: acceptedEvacuatorId }, status: 'sent' },
      data: { status: 'taken', respondedAt: new Date() },
    });

    const recipients = await this.getEvacuatorRecipientUserIds(
      others.map((o) => o.evacuatorId).filter((id): id is string => !!id),
    );
    for (const userId of recipients) {
      this.wsHub.broadcastToUser(userId, 'sos_taken', { sosRequestId });
    }
  }

  private async getEvacuatorRecipientUserIds(evacuatorIds: string[]): Promise<string[]> {
    const rows = await this.prisma.evacuator.findMany({
      where: { id: { in: evacuatorIds } },
      select: { userId: true },
    });
    return [...new Set(rows.map((r) => r.userId))];
  }
}

/**
 * `working_hours` — erkin matn ("09:00-18:00"), boshqa infra yo'q.
 * Format tanilmasa "ochiq" deb hisoblaymiz (yashirib qo'ymaslik uchun) —
 * noto'g'ri ma'lumot servisni SOS dispatchidan chetlab o'tmasin.
 */
export function isShopOpenNow(workingHours: string): boolean {
  const match = /^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$/.exec((workingHours ?? '').trim());
  if (!match) return true;

  const [, openH, openM, closeH, closeM] = match;
  const openMinutes = Number(openH) * 60 + Number(openM);
  const closeMinutes = Number(closeH) * 60 + Number(closeM);
  if (openMinutes === closeMinutes) return true;

  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Tashkent',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(new Date());
  const nowMinutes =
    Number(parts.find((p) => p.type === 'hour')?.value) * 60 +
    Number(parts.find((p) => p.type === 'minute')?.value);

  if (openMinutes < closeMinutes) {
    return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
  }
  // Kechqurundan ertalabgacha davom etadigan ish vaqti (masalan 20:00-02:00).
  return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
}
