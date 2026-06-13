import { Module } from '@nestjs/common';
import { ReviewsModule } from '../reviews/reviews.module';
import { ShopsController } from './shops.controller';
import { ShopsService } from './shops.service';

@Module({
  imports: [ReviewsModule],
  controllers: [ShopsController],
  providers: [ShopsService],
  exports: [ShopsService],
})
export class ShopsModule {}
