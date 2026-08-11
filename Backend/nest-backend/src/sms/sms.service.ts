import { Injectable, Logger } from '@nestjs/common';

/**
 * Eskiz.uz SMS shlyuzi orqali OTP yuborish. Login/parol .env'dan (ESKIZ_EMAIL/
 * ESKIZ_PASSWORD) — token doim ~30 kun amal qiladi, shuning uchun keshlab,
 * muddati tugaganda avtomatik qayta olinadi (statik tokenni qattiq yozib
 * qo'yish o'rniga — u muddati tugasa OTP jimgina to'xtab qolardi).
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private token: string | null = null;
  private tokenExpiresAt = 0;

  get isConfigured(): boolean {
    return !!(process.env.ESKIZ_EMAIL && process.env.ESKIZ_PASSWORD);
  }

  private async getToken(): Promise<string | null> {
    if (this.token && Date.now() < this.tokenExpiresAt) return this.token;

    const email = process.env.ESKIZ_EMAIL;
    const password = process.env.ESKIZ_PASSWORD;
    if (!email || !password) return null;

    try {
      const res = await fetch('https://notify.eskiz.uz/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data: any = await res.json();
      const token = data?.data?.token;
      if (!token) {
        this.logger.error(`Eskiz login xatosi: ${JSON.stringify(data)}`);
        return null;
      }
      this.token = token;
      this.tokenExpiresAt = Date.now() + 25 * 24 * 60 * 60 * 1000; // ~25 kun (muddati tugashidan oldin yangilanadi)
      return token;
    } catch (err: any) {
      this.logger.error(`Eskiz login so'rovi xatosi: ${err?.message}`);
      return null;
    }
  }

  /** @returns SMS haqiqatan yuborilgan bo'lsa true. */
  async sendOtp(phone: string, code: string): Promise<boolean> {
    const token = await this.getToken();
    if (!token) return false;

    const digits = phone.replace(/\D/g, '');
    const message = `PitGo tasdiqlash kodi: ${code}`;

    try {
      const res = await fetch('https://notify.eskiz.uz/api/message/sms/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ mobile_phone: digits, message, from: '4546' }),
      });
      const data: any = await res.json();
      // Eskiz xato bo'lganda ham ba'zan `id` qaytaradi — shuning uchun
      // `status` maydoni tekshiriladi, faqat `id` borligi yetarli emas.
      if (data?.id && data?.status !== 'error') {
        this.logger.log(`SMS yuborildi: ${digits} (eskiz id: ${data.id})`);
        return true;
      }
      this.logger.error(`Eskiz SMS xatosi (${digits}): ${JSON.stringify(data)}`);
      return false;
    } catch (err: any) {
      this.logger.error(`Eskiz SMS so'rovi xatosi (${digits}): ${err?.message}`);
      return false;
    }
  }
}
