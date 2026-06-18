import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminPromosController, PromosController } from './promos.controller';
import { PromosService } from './promos.service';

@Module({
  imports: [PrismaModule],
  controllers: [PromosController, AdminPromosController],
  providers: [PromosService],
  exports: [PromosService],
})
export class PromosModule {}
