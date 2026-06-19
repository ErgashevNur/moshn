import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

// Admin Marketing > Настройки sahifasidagi standart qiymatlar.
export const APP_CONFIG_DEFAULTS: Record<string, string> = {
  slot_hold: '5 минут',
  pay_later: '14 дней',
  installment: '3–6 месяцев',
  vip_min: '5 визитов',
};

@Injectable()
export class AppConfigService {
  constructor(private readonly prisma: PrismaService) {}

  async getAll(): Promise<Record<string, string>> {
    const rows = await this.prisma.appConfig.findMany();
    const map: Record<string, string> = { ...APP_CONFIG_DEFAULTS };
    for (const r of rows) map[r.key] = r.value;
    return map;
  }

  async get(key: string): Promise<string> {
    const row = await this.prisma.appConfig.findUnique({ where: { key } });
    return row?.value ?? APP_CONFIG_DEFAULTS[key] ?? '';
  }

  async set(key: string, value: string) {
    return this.prisma.appConfig.upsert({
      where: { key },
      update: { value },
      create: { key, value },
    });
  }

  // Erkin matnli qiymatdan birinchi butun sonni ajratib oladi: "5 визитов" -> 5
  async getNumber(key: string, fallback: number): Promise<number> {
    const raw = await this.get(key);
    const match = raw.match(/\d+/);
    return match ? parseInt(match[0], 10) : fallback;
  }
}
