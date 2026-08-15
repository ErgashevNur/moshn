import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { existsSync, unlinkSync } from 'fs';
import { join } from 'path';
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
    mileageKm?: number;
    nextServiceKm?: number;
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
        mileageKm: this.normalizeKm(data.mileageKm),
        nextServiceKm: this.normalizeKm(data.nextServiceKm),
      },
    });
  }

  /// Probeg manfiy yoki aql bovar qilmaydigan bo'lmasligi kerak —
  /// forma erkin raqam kiritishga ruxsat beradi.
  private normalizeKm(v?: number): number {
    if (v === undefined || v === null || Number.isNaN(v)) return 0;
    const n = Math.floor(Number(v));
    if (!Number.isFinite(n) || n < 0) return 0;
    return Math.min(n, 10_000_000);
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
    // Probeg maydonlari alohida — tozalanadi (create bilan bir xil qoida).
    for (const key of ['mileageKm', 'nextServiceKm']) {
      if (data[key] !== undefined) update[key] = this.normalizeKm(data[key]);
    }
    return this.prisma.vehicle.update({ where: { id }, data: update });
  }

  /// Rasm yuklangandan keyin chaqiriladi. Egalik shu yerda tekshiriladi —
  /// begona mashinaga rasm biriktirib bo'lmaydi.
  async updatePhoto(id: string, ownerId: string, photoUrl: string) {
    const v = await this.prisma.vehicle.findFirst({ where: { id, ownerId } });
    if (!v) {
      // Fayl allaqachon diskka yozilgan — egasi bo'lmasa uni qoldirmaymiz.
      this.removeUploadedFile(photoUrl);
      throw new NotFoundException('Mashina topilmadi');
    }

    const updated = await this.prisma.vehicle.update({
      where: { id },
      data: { photoUrl },
    });

    // Eski rasm endi kerak emas — diskda to'planib qolmasin.
    if (v.photoUrl && v.photoUrl !== photoUrl) this.removeUploadedFile(v.photoUrl);

    return updated;
  }

  /// `/uploads/...` URL'ini diskdagi yo'lga aylantirib o'chiradi.
  /// Xatolar yutiladi: rasm tozalanmasligi asosiy amalni buzmasligi kerak.
  private removeUploadedFile(url: string) {
    try {
      if (!url.startsWith('/uploads/')) return;
      const abs = join(process.cwd(), url.replace(/^\//, ''));
      if (existsSync(abs)) unlinkSync(abs);
    } catch {
      // e'tiborsiz qoldiriladi
    }
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
