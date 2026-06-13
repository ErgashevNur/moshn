import { Body, Controller, Get, HttpCode, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { User } from '../common/decorators/user.decorator';
import { JwtGuard } from '../common/guards/jwt.guard';
import { ReviewsService } from './reviews.service';

@ApiTags('reviews')
@ApiBearerAuth('JWT')
@UseGuards(JwtGuard)
@Controller('v1/reviews')
export class ReviewsController {
  constructor(private readonly svc: ReviewsService) {}

  @Post()
  @HttpCode(201)
  @ApiOperation({ summary: 'Baholash qoldirish (owner→shop yoki shop→owner)' })
  async create(
    @User('user_id') userId: string,
    @Body() body: { booking_id: string; rating: number; comment?: string; review_type: 'owner_to_shop' | 'shop_to_owner' },
  ) {
    return { data: await this.svc.create(userId, { bookingId: body.booking_id, rating: body.rating, comment: body.comment, reviewType: body.review_type }) };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Sharh tafsilotlari' })
  async getOne(@Param('id') id: string) {
    return { data: await this.svc.getById(id) };
  }

  @Get('customer/:id')
  @ApiOperation({ summary: 'Mijozga yozilgan sharhlar (servis → owner)' })
  async getCustomerReviews(@Param('id') customerId: string, @Query('page') page = '1', @Query('limit') limit = '20') {
    const p = Math.max(1, Number(page));
    const l = Math.min(100, Math.max(1, Number(limit)));
    return { data: await this.svc.getCustomerReviews(customerId, l, (p - 1) * l) };
  }
}
