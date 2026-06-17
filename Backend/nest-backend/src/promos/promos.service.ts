import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PromosService {
  constructor(private readonly prisma: PrismaService) {}

  async getActive() {
    const now = new Date();
    return this.prisma.promo.findMany({
      where: {
        isActive: true,
        OR: [
          { startDate: null },
          { startDate: { lte: now } },
        ],
        AND: [
          {
            OR: [
              { endDate: null },
              { endDate: { gte: now } },
            ],
          },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findAll() {
    return this.prisma.promo.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async create(data: { badgeUz?: string; badgeRu?: string; titleUz: string; titleRu: string; startDate?: string; endDate?: string }) {
    return this.prisma.promo.create({
      data: {
        badgeUz:   data.badgeUz  || '',
        badgeRu:   data.badgeRu  || '',
        titleUz:   data.titleUz,
        titleRu:   data.titleRu,
        startDate: data.startDate ? new Date(data.startDate) : null,
        endDate:   data.endDate   ? new Date(data.endDate)   : null,
      },
    });
  }

  async update(id: string, data: Partial<{ badgeUz: string; badgeRu: string; titleUz: string; titleRu: string; isActive: boolean; startDate: string; endDate: string }>) {
    const promo = await this.prisma.promo.findUnique({ where: { id } });
    if (!promo) throw new NotFoundException('Promo topilmadi');
    return this.prisma.promo.update({
      where: { id },
      data: {
        ...(data.badgeUz   !== undefined && { badgeUz:   data.badgeUz }),
        ...(data.badgeRu   !== undefined && { badgeRu:   data.badgeRu }),
        ...(data.titleUz   !== undefined && { titleUz:   data.titleUz }),
        ...(data.titleRu   !== undefined && { titleRu:   data.titleRu }),
        ...(data.isActive  !== undefined && { isActive:  data.isActive }),
        ...(data.startDate !== undefined && { startDate: data.startDate ? new Date(data.startDate) : null }),
        ...(data.endDate   !== undefined && { endDate:   data.endDate   ? new Date(data.endDate)   : null }),
      },
    });
  }

  async remove(id: string) {
    const promo = await this.prisma.promo.findUnique({ where: { id } });
    if (!promo) throw new NotFoundException('Promo topilmadi');
    return this.prisma.promo.delete({ where: { id } });
  }
}
