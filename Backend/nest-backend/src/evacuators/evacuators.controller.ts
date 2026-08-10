import { Body, Controller, Get, Post, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { EvacuatorRoleGuard } from '../common/guards/evacuator-role.guard';
import { JwtGuard } from '../common/guards/jwt.guard';
import { EvacuatorsService } from './evacuators.service';

@ApiTags('evacuators')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard)
@Controller('v1/evacuators')
export class EvacuatorsController {
  constructor(private readonly svc: EvacuatorsService) {}

  @Post('profile')
  @ApiOperation({ summary: "Evakuator profilini yaratish — ro'yxatdan o'tish paytida" })
  async createProfile(@User('user_id') userId: string, @Body() body: any) {
    return {
      data: await this.svc.createProfile(userId, {
        fullName: body.full_name ?? body.fullName,
        phone: body.phone,
        vehiclePlate: body.vehicle_plate ?? body.vehiclePlate,
      }),
    };
  }

  @UseGuards(EvacuatorRoleGuard)
  @Get('profile')
  @ApiOperation({ summary: 'Mening evakuator profilim [evacuator]' })
  async getProfile(@User('user_id') userId: string) {
    return { data: await this.svc.getOwnProfile(userId) };
  }

  @UseGuards(EvacuatorRoleGuard)
  @Put('location')
  @ApiOperation({ summary: "Joriy joylashuvni yangilash [evacuator]" })
  async updateLocation(@User('user_id') userId: string, @Body() body: { lat: number; lng: number }) {
    return { data: await this.svc.updateLocation(userId, Number(body.lat), Number(body.lng)) };
  }

  @UseGuards(EvacuatorRoleGuard)
  @Put('availability')
  @ApiOperation({ summary: "Onlayn/oflayn holatni almashtirish [evacuator]" })
  async setAvailability(@User('user_id') userId: string, @Body() body: { is_available?: boolean; isAvailable?: boolean }) {
    const value = body.is_available ?? body.isAvailable ?? true;
    return { data: await this.svc.setAvailability(userId, value) };
  }
}
