import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';
import { BookingsModule } from './bookings/bookings.module';
import { EmailModule } from './email/email.module';
import { EvacuatorsModule } from './evacuators/evacuators.module';
import { MastersModule } from './masters/masters.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PaymentsModule } from './payments/payments.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProfileModule } from './profile/profile.module';
import { ReviewsModule } from './reviews/reviews.module';
import { ShopsModule } from './shops/shops.module';
import { SmsModule } from './sms/sms.module';
import { SosModule } from './sos/sos.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { WsModule } from './ws/ws.module';
import { PromosModule } from './promos/promos.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    PrismaModule,
    EmailModule,
    SmsModule,
    WsModule,
    AuthModule,
    ProfileModule,
    VehiclesModule,
    ShopsModule,
    MastersModule,
    BookingsModule,
    PaymentsModule,
    ReviewsModule,
    NotificationsModule,
    AdminModule,
    PromosModule,
    EvacuatorsModule,
    SosModule,
  ],
})
export class AppModule {}
