import { Body, Controller, Get, HttpCode, Param, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { NotificationsService } from './notifications.service';

@ApiTags('notifications')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard)
@Controller('v1/notifications')
export class NotificationsController {
  constructor(private readonly svc: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Mening bildirishnomalarim (unread_count bilan)' })
  async getAll(
    @User('user_id') userId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    const { items, total, unreadCount } = await this.svc.getNotifications(userId, l, (p - 1) * l);
    return { data: { notifications: items, total, unread_count: unreadCount, page: p, limit: l } };
  }

  @Put('read-all')
  @HttpCode(200)
  @ApiOperation({ summary: "Barchasini o'qildi deb belgilash" })
  async markAllRead(@User('user_id') userId: string) {
    await this.svc.markAllAsRead(userId);
    return { data: { message: "Barchasi o'qildi" } };
  }

  @Put(':id/read')
  @HttpCode(200)
  @ApiOperation({ summary: "Bitta bildirishnomani o'qildi deb belgilash" })
  async markRead(@Param('id') id: string, @User('user_id') userId: string) {
    await this.svc.markAsRead(id, userId);
    return { data: { message: "O'qildi" } };
  }

  @Post('fcm-token')
  @ApiOperation({ summary: 'FCM push token saqlash' })
  async registerFcm(
    @User('user_id') userId: string,
    @Body('token') token: string,
    @Body('platform') platform: string,
  ) {
    if (!token) return { data: { message: 'token majburiy' } };
    await this.svc.saveFcmToken(userId, token, platform ?? 'android');
    return { data: { message: 'Token saqlandi' } };
  }
}
