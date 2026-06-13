import { Body, Controller, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtGuard } from '../common/guards/jwt.guard';
import { PaymentsService } from './payments.service';

@ApiTags('payments')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard)
@Controller('v1/payments')
export class PaymentsController {
  constructor(private readonly svc: PaymentsService) {}

  @Get(':booking_id')
  @ApiOperation({ summary: "To'lov holati" })
  async getPayment(@Param('booking_id') bookingId: string) {
    return { data: await this.svc.getByBooking(bookingId) };
  }

  @Post(':booking_id/qr')
  @HttpCode(200)
  @ApiOperation({ summary: 'QR kod generatsiya (MVP mock)' })
  async generateQr(@Param('booking_id') bookingId: string) {
    return { data: await this.svc.generateQR(bookingId) };
  }

  @Post(':booking_id/pay')
  @HttpCode(200)
  @ApiOperation({ summary: "To'lovni tasdiqlash (cash / card_qr / installment)" })
  async markPaid(@Param('booking_id') bookingId: string, @Body('method') method: string) {
    return { data: await this.svc.markPaid(bookingId, method) };
  }

  @Post(':booking_id/tip')
  @HttpCode(201)
  @ApiOperation({ summary: 'Chayivoye (tip) qo\'shish' })
  async addTip(@Param('booking_id') bookingId: string, @Body('amount') amount: number) {
    return { data: await this.svc.addTip(bookingId, amount) };
  }
}
