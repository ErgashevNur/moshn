import { Body, Controller, Get, HttpCode, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { ServiceRoleGuard } from '../common/guards/service-role.guard';
import { BookingsService } from './bookings.service';

@ApiTags('bookings')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard)
@Controller('v1')
export class BookingsController {
  constructor(private readonly svc: BookingsService) {}

  @Post('bookings')
  @HttpCode(201)
  @ApiOperation({ summary: 'Yangi bron yaratish [owner]' })
  async create(@User('user_id') userId: string, @Body() body: any) {
    const b = await this.svc.create(userId, {
      shopId: body.shop_id,
      vehicleId: body.vehicle_id,
      serviceTypeId: body.service_type_id,
      scheduledAt: body.scheduled_at,
      notes: body.notes,
      totalPrice: body.total_price,
    });
    return { data: b };
  }

  @Get('bookings')
  @ApiOperation({ summary: 'Mening bronlarim [owner]' })
  async getMyBookings(
    @User('user_id') userId: string,
    @Query('status') status = '',
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: { ...await this.svc.getCustomerBookings(userId, status, l, (p - 1) * l), page: p, limit: l } };
  }

  @Get('bookings/:id')
  @ApiOperation({ summary: 'Bron tafsilotlari' })
  async getOne(@Param('id') id: string) {
    return { data: await this.svc.getById(id) };
  }

  @Put('bookings/:id/cancel')
  @ApiOperation({ summary: 'Bronni bekor qilish [owner]' })
  async cancelBooking(@Param('id') id: string, @User('user_id') userId: string, @Body('reason') reason?: string) {
    await this.svc.cancelByCustomer(id, userId, reason);
    return { data: { message: 'Bron bekor qilindi' } };
  }

  @UseGuards(ServiceRoleGuard)
  @Get('service/bookings')
  @ApiOperation({ summary: 'Servisga kelgan bronlar [service]' })
  async getShopBookings(
    @User('user_id') userId: string,
    @Query('status') status = '',
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: { ...await this.svc.getShopBookings(userId, status, l, (p - 1) * l), page: p, limit: l } };
  }

  @UseGuards(ServiceRoleGuard)
  @Put('service/bookings/:id/confirm')
  @ApiOperation({ summary: 'Bronni tasdiqlash [service]' })
  async confirm(@Param('id') id: string, @User('user_id') userId: string) {
    return { data: await this.svc.confirmByShop(id, userId) };
  }

  @UseGuards(ServiceRoleGuard)
  @Put('service/bookings/:id/start')
  @ApiOperation({ summary: 'Xizmatni boshlash [service]' })
  async start(@Param('id') id: string, @User('user_id') userId: string) {
    return { data: await this.svc.startByShop(id, userId) };
  }

  @UseGuards(ServiceRoleGuard)
  @Put('service/bookings/:id/complete')
  @ApiOperation({ summary: 'Xizmat bajarildi [service]' })
  async complete(@Param('id') id: string, @User('user_id') userId: string) {
    return { data: await this.svc.completeByShop(id, userId) };
  }

  @UseGuards(ServiceRoleGuard)
  @Put('service/bookings/:id/cancel')
  @ApiOperation({ summary: 'Servis tomonidan bekor qilish [service]' })
  async shopCancel(@Param('id') id: string, @User('user_id') userId: string, @Body('reason') reason?: string) {
    await this.svc.cancelByShop(id, userId, reason);
    return { data: { message: 'Bron bekor qilindi' } };
  }
}
