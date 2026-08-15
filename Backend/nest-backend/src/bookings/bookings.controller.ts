import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Post,
  Put,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiConsumes } from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { randomUUID } from 'crypto';
import { mkdirSync } from 'fs';
import { extname, join } from 'path';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { MasterRoleGuard } from '../common/guards/master-role.guard';
import { ServiceRoleGuard } from '../common/guards/service-role.guard';
import { BookingsService } from './bookings.service';

const MAX_PHOTO_BYTES = 8 * 1024 * 1024;
const ALLOWED_PHOTO_EXT = ['.jpg', '.jpeg', '.png', '.webp', '.heic'];

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
      masterId: body.master_id,
      vehicleId: body.vehicle_id,
      serviceTypeId: body.service_type_id,
      packageId: body.package_id,
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

  @UseGuards(MasterRoleGuard)
  @Get('master/bookings')
  @ApiOperation({ summary: 'Ustaga tegishli bronlar [master]' })
  async getMasterBookings(
    @User('user_id') userId: string,
    @Query('status') status = '',
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: { ...await this.svc.getMasterBookings(userId, status, l, (p - 1) * l), page: p, limit: l } };
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

  // ── Ish bosqichlari va fotohisobot ─────────────────────────────────────────
  // Servis egasi ham, tayinlangan usta ham boshqara oladi (tekshiruv
  // servis qatlamida) — shuning uchun rol guard'i qo'yilmagan.

  @Put('bookings/:id/stages/:stageId')
  @ApiOperation({ summary: 'Bosqich holatini belgilash [master/service]' })
  async setStage(
    @Param('id') id: string,
    @Param('stageId') stageId: string,
    @User('user_id') userId: string,
    @Body('status') status: string,
  ) {
    return { data: await this.svc.setStageStatus(id, stageId, userId, status) };
  }

  @Post('bookings/:id/photos')
  @HttpCode(201)
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Fotohisobotga rasm qo\'shish [master/service]' })
  @UseInterceptors(
    FileInterceptor('photo', {
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          const dir = join(process.cwd(), 'uploads', 'bookings');
          mkdirSync(dir, { recursive: true });
          cb(null, dir);
        },
        filename: (_req, file, cb) =>
          cb(null, `${randomUUID()}${extname(file.originalname).toLowerCase()}`),
      }),
      limits: { fileSize: MAX_PHOTO_BYTES },
      fileFilter: (_req, file, cb) => {
        const ext = extname(file.originalname).toLowerCase();
        if (!file.mimetype.startsWith('image/') || !ALLOWED_PHOTO_EXT.includes(ext)) {
          return cb(new BadRequestException('Faqat rasm yuklash mumkin'), false);
        }
        cb(null, true);
      },
    }),
  )
  async addPhoto(
    @Param('id') id: string,
    @User('user_id') userId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body('stage_id') stageId?: string,
  ) {
    if (!file) throw new BadRequestException('Rasm topilmadi');
    return {
      data: await this.svc.addPhoto(id, userId, `/uploads/bookings/${file.filename}`, stageId),
    };
  }
}
