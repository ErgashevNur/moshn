import { Body, Controller, Delete, Get, HttpCode, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminRoleGuard } from '../common/guards/admin-role.guard';
import { JwtGuard } from '../common/guards/jwt.guard';
import { AdminService } from './admin.service';

@ApiTags('admin')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard, AdminRoleGuard)
@Controller('v1/admin')
export class AdminController {
  constructor(private readonly svc: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Umumiy statistika' })
  async getStats() {
    return { data: await this.svc.getStats() };
  }

  @Get('shops')
  @ApiOperation({ summary: 'Barcha servislar ro\'yxati' })
  async listShops(@Query('status') status = '', @Query('page') page = '1', @Query('limit') limit = '20') {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.svc.listShops(status, l, (p - 1) * l) };
  }

  @Post('shops')
  @HttpCode(201)
  @ApiOperation({ summary: 'Yangi servis yaratish' })
  async createShop(@Body() body: any) {
    return { data: await this.svc.createShop(body) };
  }

  @Put('shops/:id/verify')
  @ApiOperation({ summary: 'Servisni tasdiqlash yoki rad etish' })
  async verifyShop(@Param('id') id: string, @Body('status') status: string, @Body('notes') notes?: string) {
    return { data: await this.svc.verifyShop(id, status, notes) };
  }

  @Get('bookings')
  @ApiOperation({ summary: 'Barcha bronlar' })
  async listBookings(@Query('status') status = '', @Query('page') page = '1', @Query('limit') limit = '20') {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.svc.listBookings(status, l, (p - 1) * l) };
  }

  @Get('users')
  @ApiOperation({ summary: 'Foydalanuvchilar ro\'yxati' })
  async listUsers(@Query('search') search = '', @Query('role') role = '', @Query('page') page = '1', @Query('limit') limit = '20') {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.svc.listUsers(search, role, l, (p - 1) * l) };
  }

  @Get('vehicles')
  @ApiOperation({ summary: 'Barcha avtomobillar' })
  async listVehicles(@Query('search') search = '', @Query('page') page = '1', @Query('limit') limit = '20') {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.svc.listVehicles(search, l, (p - 1) * l) };
  }

  @Get('reviews')
  @ApiOperation({ summary: 'Sharhlar moderatsiya' })
  async listReviews(@Query('type') type = '', @Query('page') page = '1', @Query('limit') limit = '20') {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.svc.listReviews(type, l, (p - 1) * l) };
  }

  @Put('reviews/:id/moderate')
  @ApiOperation({ summary: 'Sharhni tasdiqlash yoki o\'chirish' })
  async moderateReview(@Param('id') id: string, @Body('approve') approve: boolean) {
    await this.svc.moderateReview(id, approve);
    return { data: { message: 'Sharh moderatsiya qilindi' } };
  }

  @Get('service-types')
  @ApiOperation({ summary: 'Xizmat turlari katalogi' })
  async listServiceTypes() {
    return { data: await this.svc.listServiceTypes() };
  }

  @Post('service-types')
  @HttpCode(201)
  @ApiOperation({ summary: 'Yangi xizmat turi qo\'shish' })
  async createServiceType(@Body() body: any) {
    return { data: await this.svc.createServiceType(body) };
  }

  @Put('service-types/:id')
  @ApiOperation({ summary: 'Xizmat turini yangilash' })
  async updateServiceType(@Param('id') id: string, @Body() body: any) {
    return { data: await this.svc.updateServiceType(id, body) };
  }

  @Get('seasonal-rules')
  @ApiOperation({ summary: 'Mavsum bildirshnoma qoidalari' })
  async listSeasonalRules() {
    return { data: await this.svc.listSeasonalRules() };
  }

  @Post('seasonal-rules')
  @HttpCode(201)
  @ApiOperation({ summary: 'Yangi mavsum qoidasi' })
  async createSeasonalRule(@Body() body: any) {
    return { data: await this.svc.createSeasonalRule(body) };
  }

  @Put('seasonal-rules/:id')
  @ApiOperation({ summary: 'Mavsum qoidasini yangilash' })
  async updateSeasonalRule(@Param('id') id: string, @Body() body: any) {
    return { data: await this.svc.updateSeasonalRule(id, body) };
  }

  @Post('seasonal-rules/:id/send')
  @HttpCode(200)
  @ApiOperation({ summary: 'Mavsum bildirishnomani hozir yuborish' })
  async sendSeasonalNow(@Param('id') id: string) {
    await this.svc.sendSeasonalNow(id);
    return { data: { message: 'Mavsum bildirshnomalari yuborildi' } };
  }

  @Post('notifications/broadcast')
  @HttpCode(200)
  @ApiOperation({ summary: "Foydalanuvchilarga (yoki segmentga) push yuborish" })
  async broadcast(@Body('title') title: string, @Body('body') body: string, @Body('segment') segment?: string) {
    await this.svc.broadcast(title, body, segment);
    return { data: { message: 'Bildirishnoma yuborildi' } };
  }

  @Get('config')
  @ApiOperation({ summary: 'Ilova konfiguratsiyasi (slot hold, VIP chegarasi va h.k.)' })
  async getConfig() {
    return { data: await this.svc.getConfig() };
  }

  @Put('config/:key')
  @ApiOperation({ summary: 'Bitta konfiguratsiya qiymatini yangilash' })
  async setConfig(@Param('key') key: string, @Body('value') value: string) {
    return { data: await this.svc.setConfig(key, value) };
  }

  // ── Super Admin: O'chirish ─────────────────────────────────────────────────

  @Get('users/:id')
  @ApiOperation({ summary: 'Foydalanuvchini ID bo\'yicha olish' })
  async getUserById(@Param('id') id: string) {
    return { data: await this.svc.getUserById(id) };
  }

  @Delete('users/:id')
  @HttpCode(200)
  @ApiOperation({ summary: 'Foydalanuvchini ID bo\'yicha o\'chirish (kaskad)' })
  async deleteUser(@Param('id') id: string) {
    return { data: await this.svc.deleteUser(id) };
  }

  @Get('shops/:id')
  @ApiOperation({ summary: 'Servisni ID bo\'yicha olish' })
  async getShopById(@Param('id') id: string) {
    return { data: await this.svc.getShopById(id) };
  }

  @Delete('shops/:id')
  @HttpCode(200)
  @ApiOperation({ summary: 'Servisni ID bo\'yicha o\'chirish (kaskad)' })
  async deleteShop(@Param('id') id: string) {
    return { data: await this.svc.deleteShop(id) };
  }
}
