import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class VehiclesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(ownerId: string, data: {
    plate: string;
    make?: string;
    model?: string;
    year?: number;
    color?: string;
    photoUrl?: string;
  }) {
    const count = await this.prisma.vehicle.count({ where: { ownerId } });
    if (count >= 5) throw new BadRequestException("Maksimal 5 ta mashina ro'yxatga olish mumkin");

    return this.prisma.vehicle.create({
      data: {
        plate: data.plate,
        ownerId,
        make: data.make ?? '',
        model: data.model ?? '',
        year: data.year ?? 0,
        color: data.color ?? '',
        photoUrl: data.photoUrl ?? '',
      },
    });
  }

  async findAll(ownerId: string) {
    return this.prisma.vehicle.findMany({ where: { ownerId } });
  }

  async findOne(id: string, ownerId: string) {
    const v = await this.prisma.vehicle.findFirst({ where: { id, ownerId } });
    if (!v) throw new NotFoundException('Mashina topilmadi');
    return v;
  }

  async update(id: string, ownerId: string, data: Record<string, any>) {
    const v = await this.prisma.vehicle.findFirst({ where: { id, ownerId } });
    if (!v) throw new NotFoundException('Mashina topilmadi');
    const allowed = ['plate', 'make', 'model', 'year', 'color', 'photoUrl'];
    const update: Record<string, any> = {};
    for (const key of allowed) {
      if (data[key] !== undefined) update[key] = data[key];
    }
    return this.prisma.vehicle.update({ where: { id }, data: update });
  }

  async remove(id: string, ownerId: string) {
    const v = await this.prisma.vehicle.findFirst({ where: { id, ownerId } });
    if (!v) throw new NotFoundException('Mashina topilmadi');
    await this.prisma.vehicle.delete({ where: { id } });
  }

  async lookupByPlate(plate: string) {
    const v = await this.prisma.vehicle.findUnique({
      where: { plate },
      include: { owner: true },
    });
    if (!v) throw new NotFoundException('Bu plaka bilan mashina topilmadi');
    return v;
  }
}
