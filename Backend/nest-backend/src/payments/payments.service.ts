import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  async getOrCreate(bookingId: string, amount: number, method: string) {
    const existing = await this.prisma.payment.findUnique({ where: { bookingId } });
    if (existing) return existing;

    const qrCode = method === 'card_qr' ? `shina24://pay/${bookingId}/${amount}` : '';
    return this.prisma.payment.create({
      data: { bookingId, amount, method, status: 'pending', qrCode },
    });
  }

  async getByBooking(bookingId: string) {
    const p = await this.prisma.payment.findUnique({ where: { bookingId } });
    if (!p) throw new NotFoundException("To'lov topilmadi");
    return p;
  }

  async generateQR(bookingId: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Bron topilmadi');

    let payment = await this.prisma.payment.findUnique({ where: { bookingId } });
    if (!payment) {
      payment = await this.prisma.payment.create({
        data: {
          bookingId,
          amount: booking.totalPrice,
          method: 'card_qr',
          status: 'pending',
          qrCode: `shina24://pay/${bookingId}/${booking.totalPrice}`,
        },
      });
    } else if (!payment.qrCode) {
      payment = await this.prisma.payment.update({
        where: { id: payment.id },
        data: { qrCode: `shina24://pay/${bookingId}/${payment.amount}` },
      });
    }
    return payment;
  }

  async markPaid(bookingId: string, method: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Bron topilmadi');

    let payment = await this.prisma.payment.findUnique({ where: { bookingId } });
    if (!payment) {
      payment = await this.prisma.payment.create({
        data: { bookingId, amount: booking.totalPrice, method, status: 'pending' },
      });
    }
    if (payment.status === 'paid') return payment;

    return this.prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'paid', paidAt: new Date(), method },
    });
  }

  async addTip(bookingId: string, amount: number) {
    if (amount <= 0) throw new BadRequestException("Tip miqdori noto'g'ri");
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Bron topilmadi');

    return this.prisma.tip.create({ data: { bookingId, amount } });
  }
}
