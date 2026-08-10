import { Body, Controller, Delete, Get, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { MasterRoleGuard } from '../common/guards/master-role.guard';
import { ServiceRoleGuard } from '../common/guards/service-role.guard';
import { ReviewsService } from '../reviews/reviews.service';
import { MastersService } from './masters.service';

@ApiTags('masters')
@Controller('v1')
export class MastersController {
  constructor(
    private readonly svc: MastersService,
    private readonly reviewsSvc: ReviewsService,
  ) {}

  // ── Servis egasi: ustalarni boshqarish ─────────────────────────────────────

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Get('service/masters')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: "Mening ustalarim ro'yxati [service]" })
  async listMine(@User('user_id') userId: string) {
    return { data: await this.svc.listByOwner(userId) };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Post('service/masters')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Yangi usta qo\'shish (login yaratiladi) [service]' })
  async create(@User('user_id') userId: string, @Body() body: any) {
    return {
      data: await this.svc.createMaster(userId, {
        phone: body.phone,
        email: body.email,
        password: body.password,
        fullName: body.full_name ?? body.fullName,
        position: body.position,
        avatarUrl: body.avatar_url ?? body.avatarUrl,
        serviceTypeIds: body.service_type_ids ?? body.serviceTypeIds,
      }),
    };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Put('service/masters/:id')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Ustani yangilash [service]' })
  async update(@User('user_id') userId: string, @Param('id') id: string, @Body() body: any) {
    return {
      data: await this.svc.updateMaster(userId, id, {
        fullName: body.full_name ?? body.fullName,
        position: body.position,
        avatarUrl: body.avatar_url ?? body.avatarUrl,
        isActive: body.is_active ?? body.isActive,
        serviceTypeIds: body.service_type_ids ?? body.serviceTypeIds,
      }),
    };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Delete('service/masters/:id')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Ustani o\'chirish (nofaol qilish) [service]' })
  async remove(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.deactivateMaster(userId, id) };
  }

  // ── Usta o'z kabineti ──────────────────────────────────────────────────────

  @UseGuards(JwtGuard, MasterRoleGuard)
  @Get('master/profile')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Mening usta profilim [master]' })
  async myProfile(@User('user_id') userId: string) {
    return { data: await this.svc.getOwnProfile(userId) };
  }

  // ── Ommaviy (mijoz uchun) ──────────────────────────────────────────────────

  @Get('shops/:id/masters')
  @ApiOperation({ summary: 'Servis ustalari (ommaviy — yozilish uchun)' })
  async listByShop(@Param('id') shopId: string) {
    return { data: await this.svc.listPublicByShop(shopId) };
  }

  @Get('masters/:id')
  @ApiOperation({ summary: 'Usta kartochkasi (ommaviy)' })
  async card(@Param('id') id: string) {
    return { data: await this.svc.getMasterCard(id) };
  }

  @Get('masters/:id/booked-slots')
  @ApiOperation({ summary: "Ustaning band vaqtlari (bron kalendari uchun)" })
  async bookedSlots(
    @Param('id') id: string,
    @Query('date_from') dateFrom: string,
    @Query('date_to') dateTo: string,
  ) {
    return { data: await this.svc.getBookedSlots(id, dateFrom, dateTo) };
  }

  @Get('masters/:id/reviews')
  @ApiOperation({ summary: 'Usta sharhlari' })
  async reviews(
    @Param('id') id: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.reviewsSvc.getMasterReviews(id, l, (p - 1) * l) };
  }
}
