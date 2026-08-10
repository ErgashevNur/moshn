import { Body, Controller, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { EvacuatorRoleGuard } from '../common/guards/evacuator-role.guard';
import { JwtGuard } from '../common/guards/jwt.guard';
import { MasterRoleGuard } from '../common/guards/master-role.guard';
import { ServiceRoleGuard } from '../common/guards/service-role.guard';
import { SosService } from './sos.service';

@ApiTags('sos')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard)
@Controller('v1')
export class SosController {
  constructor(private readonly svc: SosService) {}

  @Post('sos')
  @HttpCode(201)
  @ApiOperation({ summary: 'SOS so\'rovi ochish [owner]' })
  async create(@User('user_id') userId: string, @Body() body: any) {
    const data = await this.svc.createSosRequest(userId, {
      vehicleId: body.vehicle_id,
      serviceTypeId: body.service_type_id,
      lat: Number(body.lat),
      lng: Number(body.lng),
    });
    return { data };
  }

  @Get('sos/:id')
  @ApiOperation({ summary: "SOS so'rovi holati (kutish ekrani uchun poll)" })
  async getStatus(@Param('id') id: string) {
    return { data: await this.svc.getStatus(id) };
  }

  @UseGuards(MasterRoleGuard)
  @Get('master/sos-requests')
  @ApiOperation({ summary: 'Menga yuborilgan, hali javobsiz SOS so\'rovlari [master]' })
  async listForMaster(@User('user_id') userId: string) {
    return { data: await this.svc.listForMaster(userId) };
  }

  @UseGuards(MasterRoleGuard)
  @Get('master/sos-requests/active')
  @ApiOperation({ summary: "Men hozir bajarayotgan (qabul qilingan) SOS ishim, bo'lmasa null [master]" })
  async getActiveForMaster(@User('user_id') userId: string) {
    return { data: await this.svc.getActiveForMaster(userId) };
  }

  @UseGuards(MasterRoleGuard)
  @Post('master/sos-requests/:id/accept')
  @ApiOperation({ summary: "SOS so'rovini qabul qilish (atomik, kech qolish mumkin) [master]" })
  async accept(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.acceptSosRequest(userId, id) };
  }

  @UseGuards(ServiceRoleGuard)
  @Get('service/sos-requests')
  @ApiOperation({ summary: "Servisimga yuborilgan, hali javobsiz SOS so'rovlari (web-panel) [service]" })
  async listForShopOwner(@User('user_id') userId: string) {
    return { data: await this.svc.listForShopOwner(userId) };
  }

  @UseGuards(ServiceRoleGuard)
  @Get('service/sos-requests/active')
  @ApiOperation({ summary: "Servisning joriy (qabul qilingan) SOS ishi, bo'lmasa null (web-panel) [service]" })
  async getActiveForShopOwner(@User('user_id') userId: string) {
    return { data: await this.svc.getActiveForShopOwner(userId) };
  }

  @UseGuards(ServiceRoleGuard)
  @Post('service/sos-requests/:id/accept')
  @ApiOperation({ summary: "SOS so'rovini servis egasi sifatida qabul qilish (web-panel) [service]" })
  async acceptAsShopOwner(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.acceptAsShopOwner(userId, id) };
  }

  @Post('sos/:id/status')
  @ApiOperation({ summary: "Holatni surish: on_the_way / arrived / completed [master yoki evacuator]" })
  async updateStatus(@User('user_id') userId: string, @Param('id') id: string, @Body() body: { status: string }) {
    return { data: await this.svc.updateProgress(userId, id, body.status) };
  }

  @Post('sos/:id/cancel')
  @ApiOperation({ summary: "SOS so'rovini bekor qilish [owner]" })
  async cancel(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.cancelSosRequest(userId, id) };
  }

  @Post('sos/:id/request-evacuator')
  @ApiOperation({
    summary:
      "Hech kim topilmagandan keyin evakuator chaqirish (faqat status='no_master_found' bo'lganda) [owner]",
  })
  async requestEvacuator(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.requestEvacuator(userId, id) };
  }

  @UseGuards(EvacuatorRoleGuard)
  @Get('evacuator/sos-requests')
  @ApiOperation({ summary: "Menga yuborilgan, hali javobsiz so'rovlar [evacuator]" })
  async listForEvacuator(@User('user_id') userId: string) {
    return { data: await this.svc.listForEvacuator(userId) };
  }

  @UseGuards(EvacuatorRoleGuard)
  @Get('evacuator/sos-requests/active')
  @ApiOperation({ summary: "Men hozir bajarayotgan (qabul qilingan) ishim, bo'lmasa null [evacuator]" })
  async getActiveForEvacuator(@User('user_id') userId: string) {
    return { data: await this.svc.getActiveForEvacuator(userId) };
  }

  @UseGuards(EvacuatorRoleGuard)
  @Post('evacuator/sos-requests/:id/accept')
  @ApiOperation({ summary: "So'rovni qabul qilish (atomik, kech qolish mumkin) [evacuator]" })
  async acceptAsEvacuator(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.acceptAsEvacuator(userId, id) };
  }

  @Post('sos/:id/support')
  @ApiOperation({ summary: '"Mashinamga nima bo\'lganini bilmayman" — ichki qo\'llab-quvvatlashga signal [owner]' })
  async requestSupport(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.requestUnknownIssueSupport(userId, id) };
  }

  @Post('sos/:id/messages')
  @ApiOperation({ summary: 'SOS chatiga xabar yuborish (mijoz yoki qabul qilgan usta)' })
  async sendMessage(@User('user_id') userId: string, @Param('id') id: string, @Body() body: { body: string }) {
    return { data: await this.svc.sendMessage(userId, id, body.body) };
  }

  @Get('sos/:id/messages')
  @ApiOperation({ summary: 'SOS chat tarixi' })
  async getMessages(@User('user_id') userId: string, @Param('id') id: string) {
    return { data: await this.svc.getMessages(userId, id) };
  }

  @Post('sos/:id/price')
  @HttpCode(200)
  @ApiOperation({ summary: "Xizmat narxini kiritish (faqat 'completed' holatda) [master yoki evacuator]" })
  async setPrice(@User('user_id') userId: string, @Param('id') id: string, @Body('amount') amount: number) {
    return { data: await this.svc.setPrice(userId, id, Number(amount)) };
  }

  @Post('sos/:id/payment/confirm')
  @HttpCode(200)
  @ApiOperation({ summary: "To'lovni tasdiqlash (real gateway yo'q — MVP qo'lda tasdiqlash) [owner]" })
  async confirmPayment(@User('user_id') userId: string, @Param('id') id: string, @Body('method') method: string) {
    return { data: await this.svc.confirmPayment(userId, id, method) };
  }

  @Post('sos/:id/tip')
  @HttpCode(201)
  @ApiOperation({ summary: "Qabul qilgan tomonga chayevoy qoldirish [owner]" })
  async addTip(@User('user_id') userId: string, @Param('id') id: string, @Body('amount') amount: number) {
    return { data: await this.svc.addTip(userId, id, Number(amount)) };
  }
}
