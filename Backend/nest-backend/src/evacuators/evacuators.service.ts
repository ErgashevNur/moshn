import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class EvacuatorsService {
  constructor(private readonly prisma: PrismaService) {}

  async createProfile(userId: string, data: { fullName: string; phone?: string; vehiclePlate?: string }) {
    const existing = await this.prisma.evacuator.findUnique({ where: { userId } });
    if (existing) throw new BadRequestException('Evakuator profili allaqachon mavjud');

    const fullName = (data.fullName ?? '').trim();
    if (!fullName) throw new BadRequestException("Ism kiritilishi shart");

    return this.prisma.evacuator.create({
      data: {
        userId,
        fullName,
        phone: (data.phone ?? '').trim(),
        vehiclePlate: (data.vehiclePlate ?? '').trim().toUpperCase(),
      },
    });
  }

  async getOwnProfile(userId: string) {
    const evacuator = await this.prisma.evacuator.findUnique({ where: { userId } });
    if (!evacuator) throw new NotFoundException('Evakuator profili topilmadi');
    return evacuator;
  }

  /** Mobil evakuator joylashuvi — ilova ochilganda/onlayn bo'lganda yangilanadi. */
  async updateLocation(userId: string, lat: number, lng: number) {
    const evacuator = await this.requireOwn(userId);
    await this.prisma.$executeRaw`
      UPDATE evacuators
         SET location = ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography, updated_at = now()
       WHERE id = ${evacuator.id}::uuid
    `;
    return { message: 'Joylashuv yangilandi' };
  }

  async setAvailability(userId: string, isAvailable: boolean) {
    const evacuator = await this.requireOwn(userId);
    return this.prisma.evacuator.update({
      where: { id: evacuator.id },
      data: { isAvailable },
    });
  }

  private async requireOwn(userId: string) {
    const evacuator = await this.prisma.evacuator.findUnique({ where: { userId } });
    if (!evacuator) throw new NotFoundException('Evakuator profili topilmadi');
    return evacuator;
  }
}
