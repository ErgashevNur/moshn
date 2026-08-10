import { Module } from '@nestjs/common';
import { ReviewsModule } from '../reviews/reviews.module';
import { MastersController } from './masters.controller';
import { MastersService } from './masters.service';

@Module({
  imports: [ReviewsModule],
  controllers: [MastersController],
  providers: [MastersService],
  exports: [MastersService],
})
export class MastersModule {}
