import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(authorId: string, data: {
    bookingId: string;
    rating: number;
    comment?: string;
    reviewType: 'owner_to_shop' | 'shop_to_owner';
  }) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: data.bookingId, status: 'completed' },
    });
    if (!booking) throw new NotFoundException('Tugallangan bron topilmadi');

    if (data.reviewType === 'owner_to_shop' && booking.customerId !== authorId) {
      throw new BadRequestException('Faqat bron egasi sharh yoza oladi');
    }
    if (data.reviewType === 'shop_to_owner') {
      const shop = await this.prisma.shopProfile.findFirst({
        where: { id: booking.shopId, userId: authorId },
      });
      if (!shop) throw new BadRequestException('Faqat servis egasi sharh yoza oladi');
    }

    const existing = await this.prisma.review.findFirst({
      where: { bookingId: data.bookingId, reviewType: data.reviewType },
    });
    if (existing) throw new BadRequestException('Bu bron uchun sharh allaqachon yozilgan');

    const targetId = data.reviewType === 'shop_to_owner' ? booking.customerId : booking.shopId;

    const review = await this.prisma.review.create({
      data: {
        bookingId: data.bookingId,
        authorId,
        targetId,
        reviewType: data.reviewType,
        rating: data.rating,
        comment: data.comment ?? '',
      },
      include: { author: true },
    });

    if (data.reviewType === 'owner_to_shop') {
      await this.updateShopRating(booking.shopId);
    }

    return review;
  }

  async getById(id: string) {
    const review = await this.prisma.review.findUnique({
      where: { id },
      include: { author: true },
    });
    if (!review) throw new NotFoundException('Sharh topilmadi');
    return review;
  }

  async getShopReviews(shopId: string, limit: number, skip: number) {
    const [items, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { targetId: shopId, reviewType: 'owner_to_shop' },
        include: { author: true },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip,
      }),
      this.prisma.review.count({
        where: { targetId: shopId, reviewType: 'owner_to_shop' },
      }),
    ]);
    return { reviews: items, total };
  }

  async getCustomerReviews(customerId: string, limit: number, skip: number) {
    const [items, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { targetId: customerId, reviewType: 'shop_to_owner' },
        include: { author: true },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip,
      }),
      this.prisma.review.count({
        where: { targetId: customerId, reviewType: 'shop_to_owner' },
      }),
    ]);
    return { reviews: items, total };
  }

  private async updateShopRating(shopId: string) {
    const agg = await this.prisma.review.aggregate({
      where: { targetId: shopId, reviewType: 'owner_to_shop' },
      _avg: { rating: true },
      _count: { rating: true },
    });
    await this.prisma.shopProfile.update({
      where: { id: shopId },
      data: {
        ratingAvg: agg._avg.rating ?? 0,
        ratingCount: agg._count.rating,
      },
    });
  }
}
