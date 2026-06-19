import { Module } from '@nestjs/common';
import { AppConfigModule } from '../app-config/app-config.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ShopsModule } from '../shops/shops.module';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';

@Module({
  imports: [NotificationsModule, ShopsModule, AppConfigModule],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
