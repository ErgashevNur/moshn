import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/shop.dart';
import '../../models/review.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_button.dart';
import '../../widgets/m_ph.dart';
import '../../widgets/m_stars.dart';
import '../../widgets/m_tag.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _shopDetailProvider =
    FutureProvider.autoDispose.family<Shop, String>(
  (ref, id) => ShopService().getShop(id),
);

// Reviews placeholder — a real ReviewService would be injected here.
final _shopReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>(
  (ref, shopId) async {
    // Placeholder: return empty list until ReviewService is wired.
    return const [];
  },
);

// ── Icon mapping ───────────────────────────────────────────────────────────────

IconData _iconForServiceSlug(String slug) {
  switch (slug) {
    case 'podkachka':
      return Icons.air_rounded;
    case 'perezobuvka':
      return Icons.tire_repair_rounded;
    case 'disk_repair':
      return Icons.album_rounded;
    case 'balanslash':
      return Icons.album_outlined;
    case 'remont_prokola':
      return Icons.build_rounded;
    case 'hranenie':
      return Icons.layers_rounded;
    default:
      return Icons.miscellaneous_services_rounded;
  }
}

String _labelForSlug(String slug, String locale) {
  const labelsUz = {
    'podkachka': 'Podkachka',
    'perezobuvka': 'Perezobuvka',
    'disk_repair': "Disk ta'mir",
    'balanslash': 'Balanslash',
    'remont_prokola': "Prokol ta'mir",
    'hranenie': 'Shina saqlash',
  };
  const labelsRu = {
    'podkachka': 'Подкачка',
    'perezobuvka': 'Переобувка',
    'disk_repair': 'Ремонт диска',
    'balanslash': 'Балансировка',
    'remont_prokola': 'Ремонт прокола',
    'hranenie': 'Хранение шин',
  };
  final map = locale == 'ru' ? labelsRu : labelsUz;
  return map[slug] ?? slug;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(_shopDetailProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: shopAsync.when(
        data: (shop) => _ShopDetailBody(shop: shop),
        loading: () => const _LoadingBody(),
        error: (e, _) => _ErrorBody(message: e.toString()),
      ),
    );
  }
}

// ── Loading / Error ───────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          child: _BackButton(onTap: () => context.pop()),
        ),
        Expanded(
          child: Center(
            child: Text(
              'common.error'.tr(),
              style:
                  AppTypography.body.copyWith(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _ShopDetailBody extends ConsumerWidget {
  final Shop shop;
  const _ShopDetailBody({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_shopReviewsProvider(shop.id));

    return Column(
      children: [
        // ── Scrollable content ─────────────────────────────────────────────
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero ─────────────────────────────────────────────────
                  _HeroSection(shop: shop),

                  // ── Content ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + tags
                        _ShopNameRow(shop: shop),
                        const SizedBox(height: 10),

                        // Rating + open status
                        _RatingRow(shop: shop),
                        const SizedBox(height: 10),

                        // Address
                        _AddressRow(shop: shop),
                        const SizedBox(height: 16),

                        // Action buttons
                        _ActionButtons(shop: shop),
                        const SizedBox(height: 24),

                        // About
                        _SectionLabel(label: 'shop.about'.tr()),
                        const SizedBox(height: 8),
                        Text(
                          shop.shopName.isNotEmpty
                              ? 'shop.desc_long'.tr(namedArgs: {'name': shop.shopName})
                              : 'shop.desc_default'.tr(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.text2(context),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Services & prices
                        _SectionLabel(label: 'shop.services_prices'.tr()),
                        const SizedBox(height: 10),
                        _ServicesCard(serviceTypes: shop.serviceTypes),
                        const SizedBox(height: 24),

                        // Reviews
                        reviewsAsync.maybeWhen(
                          data: (reviews) => _ReviewsSection(reviews: reviews),
                          orElse: () => const SizedBox.shrink(),
                        ),

                        SizedBox(
                            height:
                                MediaQuery.of(context).padding.bottom + 24),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),

        // ── Sticky bottom bar ───────────────────────────────────────────────
        _StickyBookingBar(shop: shop),
      ],
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final Shop shop;
  const _HeroSection({required this.shop});

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final heroH = (screenH * 0.35).clamp(200.0, 280.0) + safeTop;
    return SizedBox(
      height: heroH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo placeholder
          MPh(
            width: double.infinity,
            height: heroH,
            radius: 0,
            label: 'shop.photo_placeholder'.tr(),
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.65, 1.0],
                  colors: [
                    AppColors.scrim(context),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.bg(context),
                  ],
                ),
              ),
            ),
          ),

          // Top left: back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _BackButton(onTap: () => context.pop()),
          ),

          // Top right: favorite button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _IconCircleButton(
              icon: Icons.favorite_border_rounded,
              onTap: () {},
            ),
          ),

          // Bottom right: image dots
          Positioned(
            bottom: 14,
            right: 16,
            child: _ImageDots(count: 3, activeIndex: 0),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bg(context).withAlpha(204),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline(context), width: 1),
        ),
        child: Icon(
          Icons.chevron_left_rounded,
          size: 22,
          color: AppColors.text(context),
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bg(context).withAlpha(204),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline(context), width: 1),
        ),
        child: Icon(icon, size: 20, color: AppColors.text(context)),
      ),
    );
  }
}

class _ImageDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _ImageDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return Container(
          width: active ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(AppSpacing.r_full),
          ),
        );
      }),
    );
  }
}

// ── Name row ──────────────────────────────────────────────────────────────────

class _ShopNameRow extends StatelessWidget {
  final Shop shop;
  const _ShopNameRow({required this.shop});

  @override
  Widget build(BuildContext context) {
    final isVerified = shop.verificationStatus == 'verified';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            shop.shopName,
            style: AppTypography.soraSize(24, weight: FontWeight.w700).copyWith(
              color: AppColors.text(context),
              letterSpacing: 24 * -0.03,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isVerified)
              MTag(
                label: 'VIP',
                variant: MTagVariant.gold,
                icon: Icons.workspace_premium_rounded,
              ),
            const SizedBox(height: 4),
            MTag(
              label: '24/7',
              variant: MTagVariant.default_,
              icon: Icons.access_time_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Rating row ────────────────────────────────────────────────────────────────

class _RatingRow extends StatelessWidget {
  final Shop shop;
  const _RatingRow({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
        const SizedBox(width: 4),
        Text(
          shop.ratingAvg.toStringAsFixed(1),
          style: AppTypography.soraSize(14, weight: FontWeight.w600)
              .copyWith(color: AppColors.text(context)),
        ),
        const SizedBox(width: 4),
        Text(
          '(${shop.ratingCount} ${'shop.reviews_count'.tr()})',
          style: AppTypography.body.copyWith(color: AppColors.text2(context)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.successDim,
            borderRadius: BorderRadius.circular(AppSpacing.r_xs),
          ),
          child: Text(
            'shop.open'.tr(),
            style: AppTypography.soraSize(12, weight: FontWeight.w600)
                .copyWith(color: AppColors.success),
          ),
        ),
      ],
    );
  }
}

// ── Address row ───────────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final Shop shop;
  const _AddressRow({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 16,
          color: AppColors.text3(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            shop.address.isNotEmpty ? shop.address : 'shop.no_address'.tr(),
            style: AppTypography.body.copyWith(color: AppColors.text2(context)),
          ),
        ),
      ],
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final Shop shop;
  const _ActionButtons({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MButton(
            label: 'shop.direction'.tr(),
            variant: MButtonVariant.secondary,
            small: true,
            leading: const Icon(Icons.directions_rounded),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MButton(
            label: 'shop.call'.tr(),
            variant: MButtonVariant.secondary,
            small: true,
            leading: const Icon(Icons.phone_rounded),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.soraSize(17, weight: FontWeight.w700).copyWith(
        color: AppColors.text(context),
        letterSpacing: 17 * -0.02,
      ),
    );
  }
}

// ── Services card ─────────────────────────────────────────────────────────────

class _ServicesCard extends StatelessWidget {
  final List<String> serviceTypes;
  const _ServicesCard({required this.serviceTypes});

  @override
  Widget build(BuildContext context) {
    if (serviceTypes.isEmpty) return const SizedBox.shrink();

    final prices = [35000, 80000, 150000, 50000, 45000, 120000];
    final minLabel = 'shop.min'.tr();
    final durations = [
      '15 $minLabel', '30 $minLabel', '60 $minLabel',
      '20 $minLabel', '25 $minLabel', '45 $minLabel',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        border: Border.all(color: AppColors.hairline(context), width: 1),
      ),
      child: Column(
        children: serviceTypes.asMap().entries.map((entry) {
          final i = entry.key;
          final slug = entry.value;
          final isLast = i == serviceTypes.length - 1;
          final price = i < prices.length ? prices[i] : 50000;
          final duration = i < durations.length ? durations[i] : '30 daq';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon box
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surface2(context),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        _iconForServiceSlug(slug),
                        size: 18,
                        color: AppColors.text2(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + duration
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelForSlug(slug, context.locale.languageCode),
                            style: AppTypography.soraSize(14,
                                    weight: FontWeight.w500)
                                .copyWith(color: AppColors.text(context)),
                          ),
                          Text(
                            duration,
                            style: AppTypography.body.copyWith(
                              color: AppColors.text3(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Text(
                      '${_formatPrice(price)} ${'common.sum'.tr()}',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.text(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.hairline(context),
                  indent: 14,
                  endIndent: 14,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Reviews section ───────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  const _ReviewsSection({required this.reviews});

  @override
  Widget build(BuildContext context) {
    // Show mock reviews when the list is empty to demonstrate the UI
    final locale = context.locale.languageCode;
    final displayReviews = reviews.isNotEmpty
        ? reviews
        : [
            Review(
              id: 'mock1',
              bookingId: '',
              authorId: '',
              targetId: '',
              reviewType: 'owner_to_shop',
              rating: 5,
              comment: locale == 'ru'
                  ? 'Отличный сервис! Быстро и качественно.'
                  : 'Juda yaxshi xizmat! Tez va sifatli bajarishdi.',
              authorName: 'Dilshod T.',
              isModerated: false,
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
            Review(
              id: 'mock2',
              bookingId: '',
              authorId: '',
              targetId: '',
              reviewType: 'owner_to_shop',
              rating: 4,
              comment: locale == 'ru'
                  ? 'Цена приемлемая, обслуживание отличное.'
                  : "Narxi qulay, xizmat a'lo darajada.",
              authorName: 'Malika R.',
              isModerated: false,
              createdAt: DateTime.now().subtract(const Duration(days: 5)),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel(label: 'shop.reviews'.tr()),
            const SizedBox(width: 8),
            Text(
              '${displayReviews.length} ${'shop.reviews_count'.tr()}',
              style: AppTypography.body.copyWith(color: AppColors.text3(context)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayReviews.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: r),
            )),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        border: Border.all(color: AppColors.hairline(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              ClipOval(
                child: MPh(width: 34, height: 34, radius: 17, label: 'AV'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName.isNotEmpty
                          ? review.authorName
                          : 'profile.user_placeholder'.tr(),
                      style: AppTypography.soraSize(13, weight: FontWeight.w600)
                          .copyWith(color: AppColors.text(context)),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _formatDate(review.createdAt!, context),
                        style: AppTypography.body.copyWith(
                          color: AppColors.text3(context),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              MStars(value: review.rating.toDouble(), size: 13),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: AppTypography.body.copyWith(
                color: AppColors.text2(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'dates.today'.tr();
    if (diff.inDays == 1) return 'dates.yesterday'.tr();
    if (diff.inDays < 7) {
      return 'dates.days_ago'.tr(namedArgs: {'count': '${diff.inDays}'});
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── Sticky booking bar ────────────────────────────────────────────────────────

class _StickyBookingBar extends StatelessWidget {
  final Shop shop;
  const _StickyBookingBar({required this.shop});

  @override
  Widget build(BuildContext context) {
    const basePrice = 35000;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgElevated(context),
        border: Border(
          top: BorderSide(color: AppColors.hairline(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Price column
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'payment.price_from'.tr(),
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.text3(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatPrice(basePrice)} ${'common.sum'.tr()}',
                  style: AppTypography.mono.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Book button
          Expanded(
            child: MButton(
              label: 'booking.book_slot'.tr(),
              variant: MButtonVariant.primary,
              onTap: () => context.push(
                '/owner/shops/${shop.id}/book',
                extra: {
                  'name': shop.shopName,
                  'address': shop.address,
                  'isVerified': shop.verificationStatus == 'verified',
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
