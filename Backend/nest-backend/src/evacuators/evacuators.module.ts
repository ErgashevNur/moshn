import { Module } from '@nestjs/common';
import { EvacuatorsController } from './evacuators.controller';
import { EvacuatorsService } from './evacuators.service';

@Module({
  controllers: [EvacuatorsController],
  providers: [EvacuatorsService],
  exports: [EvacuatorsService],
})
export class EvacuatorsModule {}
