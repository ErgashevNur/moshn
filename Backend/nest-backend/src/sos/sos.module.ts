import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { SosController } from './sos.controller';
import { SosService } from './sos.service';

@Module({
  imports: [NotificationsModule],
  controllers: [SosController],
  providers: [SosService],
  exports: [SosService],
})
export class SosModule {}
