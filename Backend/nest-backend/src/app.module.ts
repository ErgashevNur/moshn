import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminModule } from './admin/admin.module';
import { AuthModule } from './auth/auth.module';
import { BookingsModule } from './bookings/bookings.module';
import { EmailModule } from './email/email.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PaymentsModule } from './payments/payments.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProfileModule } from './profile/profile.module';
import { PromosModule } from './promos/promos.module';
import { ReviewsModule } from './reviews/reviews.module';
import { ShopsModule } from './shops/shops.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { WsModule } from './ws/ws.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    EmailModule,
    WsModule,
    AuthModule,
    ProfileModule,
    VehiclesModule,
    ShopsModule,
    BookingsModule,
    PaymentsModule,
    PromosModule,
    ReviewsModule,
    NotificationsModule,
    AdminModule,
  ],
})
export class AppModule {}
