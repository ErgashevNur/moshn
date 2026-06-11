import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/shop.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

final _shopProvider = FutureProvider.autoDispose.family<Shop, String>(
  (ref, id) => ShopService().getShop(id),
);

class ShopProfileScreen extends ConsumerWidget {
  final String shopId;
  const ShopProfileScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(_shopProvider(shopId));

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(border: null),
      child: shopAsync.when(
        data: (shop) => _Body(shop: shop),
        loading: () =>
            const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Text('${'common.error'.tr()}: $e',
              style: AppTypography.body
                  .copyWith(color: AppColors.danger)),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Shop shop;
  const _Body({required this.shop});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _Header(shop: shop),
                const SizedBox(height: AppSpacing.xl),
                _InfoSection(shop: shop),
                const SizedBox(height: AppSpacing.xl),
                _ServiceTypesSection(shop: shop),
                const SizedBox(height: AppSpacing.xxxl),
                PrimaryButton(
                  label: 'owner.book_now'.tr(),
                  onPressed: () => context.push(
                    '/owner/shops/${shop.id}/book',
                    extra: shop.shopName,
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Shop shop;
  const _Header({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.inverseBg(context).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: const Center(
            child: Text('🔧', style: TextStyle(fontSize: 64)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(shop.shopName, style: AppTypography.displayLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(CupertinoIcons.star_fill,
                size: 14, color: CupertinoColors.systemYellow),
            const SizedBox(width: 4),
            Text(
              '${shop.ratingAvg.toStringAsFixed(1)}  (${shop.ratingCount})',
              style: AppTypography.labelSmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: AppSpacing.md),
            if (shop.distanceKm != null)
              Text(
                '${shop.distanceKm!.toStringAsFixed(1)} km',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.text3(context)),
              ),
          ],
        ),
        if (shop.verificationStatus != 'verified') ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              'Hali tasdiqlanmagan',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Shop shop;
  const _InfoSection({required this.shop});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          _Row(
            icon: CupertinoIcons.location,
            label: 'Manzil',
            value: shop.address,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: _Divider(),
          ),
          _Row(
            icon: CupertinoIcons.clock,
            label: 'Ish vaqti',
            value: shop.workingHours,
          ),
          if (shop.phone.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: _Divider(),
            ),
            _Row(
              icon: CupertinoIcons.phone,
              label: 'Telefon',
              value: shop.phone,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.text3(context)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.text3(context))),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceTypesSection extends StatelessWidget {
  final Shop shop;
  const _ServiceTypesSection({required this.shop});

  @override
  Widget build(BuildContext context) {
    if (shop.serviceTypes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Xizmatlar', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: shop.serviceTypes
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.inverseBg(context)
                        .withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    t,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: AppColors.hairline(context));
  }
}
