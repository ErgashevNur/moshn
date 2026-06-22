import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../models/shop.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import 'home_screen.dart' show serviceTypesProvider;

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

  bool get _validCoords => shop.latitude != 0 || shop.longitude != 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: _validCoords
                ? IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(shop.latitude, shop.longitude),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'uz.moshn.moshn',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(shop.latitude, shop.longitude),
                              width: 36,
                              height: 36,
                              child: const Icon(
                                CupertinoIcons.location_solid,
                                color: Color(0xFFE5382B),
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: AppColors.inverseBg(context).withValues(alpha: 0.06),
                    child: const Center(
                      child: Text('🔧', style: TextStyle(fontSize: 64)),
                    ),
                  ),
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
              'Не подтверждён',
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
            label: 'Адрес',
            value: shop.address,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: _Divider(),
          ),
          _Row(
            icon: CupertinoIcons.clock,
            label: 'Часы работы',
            value: shop.workingHours,
          ),
          if (shop.phone.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: _Divider(),
            ),
            _Row(
              icon: CupertinoIcons.phone,
              label: 'Телефон',
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

class _ServiceTypesSection extends ConsumerWidget {
  final Shop shop;
  const _ServiceTypesSection({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shop.serviceTypes.isEmpty) return const SizedBox.shrink();

    final locale = context.locale.languageCode;
    final typesAsync = ref.watch(serviceTypesProvider);
    final typeMap = typesAsync.valueOrNull != null
        ? { for (final t in typesAsync.valueOrNull!) t.slug: t }
        : <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('owner.services_prices'.tr(), style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: shop.serviceTypes.map((slug) {
            final label = typeMap[slug] != null
                ? typeMap[slug]!.nameFor(locale)
                : slug;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.inverseBg(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
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
