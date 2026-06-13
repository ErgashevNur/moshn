import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor() {
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASSWORD;

    if (user && pass) {
      this.transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST ?? 'smtp.gmail.com',
        port: Number(process.env.SMTP_PORT ?? 587),
        secure: false,
        auth: { user, pass },
      });
    }
  }

  async sendOtp(to: string, code: string, lang: string): Promise<void> {
    const [subject, body] = this.otpContent(code, lang);
    await this.send(to, subject, body);
  }

  private async send(to: string, subject: string, body: string): Promise<void> {
    if (!this.transporter) {
      this.logger.log(`[email-dev] To: ${to} | Subject: ${subject}\n${body}`);
      return;
    }
    const from = process.env.SMTP_FROM ?? process.env.SMTP_USER;
    await this.transporter.sendMail({ from, to, subject, text: body });
  }

  private otpContent(code: string, lang: string): [string, string] {
    if (lang === 'ru') {
      return [
        'Shina24 — Код подтверждения',
        `Здравствуйте!\n\nВаш код подтверждения: ${code}\n\nКод действителен 10 минут.\n\n— Shina24`,
      ];
    }
    return [
      'Shina24 — Tasdiqlash kodi',
      `Salom!\n\nSizning tasdiqlash kodingiz: ${code}\n\nKod 10 daqiqa amal qiladi.\n\n— Shina24`,
    ];
  }

  static generateOtp(): string {
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += Math.floor(Math.random() * 10).toString();
    }
    return code;
  }
}
