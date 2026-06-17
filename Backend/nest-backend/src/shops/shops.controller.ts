import { Body, Controller, Get, Param, Put, Query, UseGuards, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { ServiceRoleGuard } from '../common/guards/service-role.guard';
import { ReviewsService } from '../reviews/reviews.service';
import { ShopsService } from './shops.service';

@ApiTags('shops')
@Controller('v1')
export class ShopsController {
  constructor(
    private readonly svc: ShopsService,
    private readonly reviewsSvc: ReviewsService,
  ) {}

  @Get('service-types')
  @ApiOperation({ summary: 'Xizmat turlari katalogi (ommaviy)' })
  async getServiceTypes() {
    return { data: await this.svc.getServiceTypes() };
  }

  @Get('shops')
  @ApiOperation({ summary: 'Shinomontaj servislarni qidirish (geo + xizmat turi)' })
  async findAll(
    @Query('lat') lat?: string,
    @Query('lng') lng?: string,
    @Query('service_type') serviceType?: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    const result = await this.svc.findMany({
      serviceType,
      lat: lat ? Number(lat) : undefined,
      lng: lng ? Number(lng) : undefined,
      limit: l,
      skip: (p - 1) * l,
    });
    return { data: { ...result, page: p, limit: l } };
  }

  @Get('shops/:id')
  @ApiOperation({ summary: 'Servis profili' })
  async findOne(@Param('id') id: string) {
    return { data: await this.svc.findById(id) };
  }

  @Get('shops/:id/reviews')
  @ApiOperation({ summary: 'Servis sharhlari' })
  async getReviews(
    @Param('id') id: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.reviewsSvc.getShopReviews(id, l, (p - 1) * l) };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Get('service/profile')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Mening servis profilim [service]' })
  async getMyShop(@User('user_id') userId: string) {
    return { data: await this.svc.findByUserId(userId) };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Put('service/profile')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Servis profilini yangilash [service]' })
  async updateProfile(@User('user_id') userId: string, @Body() body: any) {
    return { data: await this.svc.updateProfile(userId, body) };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Get('service/customers')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Mijozlar bazasi — CRM [service]' })
  async getCustomers(
    @User('user_id') userId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const shop = await this.svc.findByUserId(userId);
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: { ...await this.svc.getCustomers(shop.id, l, (p - 1) * l), page: p } };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Get('service/customers/:customer_id')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Mijoz kartochkasi [service]' })
  async getCustomerCard(@User('user_id') userId: string, @Param('customer_id') customerId: string) {
    const shop = await this.svc.findByUserId(userId);
    return { data: await this.svc.getCustomerCard(shop.id, customerId) };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Put('service/customers/:customer_id')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Mijoz kartochkasini yangilash (VIP, eslatma) [service]' })
  async updateCustomerCard(
    @User('user_id') userId: string,
    @Param('customer_id') customerId: string,
    @Body() body: { is_vip?: boolean; notes?: string },
  ) {
    const shop = await this.svc.findByUserId(userId);
    return { data: await this.svc.updateCustomerCard(shop.id, customerId, { isVip: body.is_vip, notes: body.notes }) };
  }

  // ── Xizmat narxlari ────────────────────────────────────────────────────────

  @Get('shops/:id/prices')
  @ApiOperation({ summary: 'Servis narxlari (ommaviy)' })
  async getShopPrices(@Param('id') id: string) {
    return { data: await this.svc.getServicePrices(id) };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Get('service/prices')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: "O'z narxlarimni ko'rish [service]" })
  async getMyPrices(@User('user_id') userId: string) {
    const shop = await this.svc.findByUserId(userId);
    return { data: await this.svc.getServicePrices(shop.id) };
  }

  @UseGuards(JwtGuard, ServiceRoleGuard)
  @Put('service/prices')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Xizmat narxlarini belgilash [service]' })
  async upsertMyPrices(
    @User('user_id') userId: string,
    @Body() body: { prices: { serviceTypeId: string; priceMin: number; priceMax: number }[] },
  ) {
    const shop = await this.svc.findByUserId(userId);
    return { data: await this.svc.upsertServicePrices(shop.id, body.prices) };
  }
}
