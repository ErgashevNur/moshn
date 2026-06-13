import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_type.dart';
import '../../models/shop.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_moshn_icon.dart';
import '../../widgets/m_workshop_card.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _catShopsProvider =
    FutureProvider.autoDispose.family<List<Shop>, String>((ref, slug) {
  return ShopService().getShops(serviceType: slug);
});

final _serviceTypesForCatProvider =
    FutureProvider.autoDispose<List<ServiceType>>((ref) {
  return ShopService().getServiceTypes();
});

// ── Slug → icon / accent ──────────────────────────────────────────────────────

typedef _SlugMeta = ({String iconName, Color accent});

_SlugMeta _slugMeta(String slug) {
  return switch (slug) {
    'podkachka' || 'pumping'   => (iconName: 'gauge',  accent: const Color(0xFF4CA8D9)),
    'perezobuvka' || 'tire_change' || 'tire_storage' =>
                                  (iconName: 'disc',   accent: const Color(0xFFD4A843)),
    'balancing'                => (iconName: 'disc',   accent: const Color(0xFF30D158)),
    'vulkanizatsiya' || 'patch' || 'remont_prokola' =>
                                  (iconName: 'wrench', accent: const Color(0xFFE87D3E)),
    'disk_repair' || 'rim_repair' =>
                                  (iconName: 'disc',   accent: const Color(0xFF9B72CF)),
    'storage' || 'hranenie'    => (iconName: 'layers', accent: const Color(0xFF2EC6C6)),
    _                          => (iconName: 'wrench', accent: const Color(0xFFD4A843)),
  };
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ServiceCategoryScreen extends ConsumerWidget {
  final String slug;
  const ServiceCategoryScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final shopsAsync = ref.watch(_catShopsProvider(slug));
    final typesAsync = ref.watch(_serviceTypesForCatProvider);

    final apiType = typesAsync.asData?.value
        .where((t) => t.slug == slug)
        .firstOrNull;

    final title = locale == 'ru'
        ? (apiType?.nameRu ?? slug)
        : (apiType?.nameUz ?? slug);

    final m = _slugMeta(slug);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Header(title: title, accent: m.accent, iconName: m.iconName),
          ),

          // ── "Yaqin servislar" sarlavhasi ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'service_category.near_services'.tr(),
                      style: AppTypography.soraSize(17, weight: FontWeight.w700)
                          .copyWith(
                        color: AppColors.text(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/owner/map'),
                    child: Text(
                      'home.view_on_map'.tr(),
                      style: AppTypography.soraSize(12.5, weight: FontWeight.w500)
                          .copyWith(color: AppColors.text2(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Servislar ro'yxati ───────────────────────────────────────────────
          shopsAsync.when(
            data: (shops) {
              if (shops.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyShops(accent: m.accent),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                sliver: SliverList.separated(
                  itemCount: shops.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final s = shops[i];
                    return WorkshopCard(
                      name: s.shopName,
                      imageUrl: null,
                      rating: s.ratingAvg,
                      reviewCount: s.ratingCount,
                      address: s.address,
                      distance: s.distanceKm != null
                          ? '${s.distanceKm!.toStringAsFixed(1)} km'
                          : null,
                      isOpen: true,
                      onTap: () => ctx.push('/owner/shops/${s.id}'),
                    );
                  },
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 32,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final Color accent;
  final String iconName;

  const _Header({
    required this.title,
    required this.accent,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(18, safeTop + 12, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          bottom: BorderSide(color: AppColors.hairline(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Orqaga
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline(context)),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.chevron_left_rounded,
                  size: 22, color: AppColors.text(context)),
            ),
          ),
          const SizedBox(width: 14),

          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withAlpha(26),
              border: Border.all(color: accent.withAlpha(60)),
            ),
            alignment: Alignment.center,
            child: MoshnIcon(name: iconName, size: 22, color: accent),
          ),
          const SizedBox(width: 12),

          // Sarlavha
          Expanded(
            child: Text(
              title,
              style: AppTypography.soraSize(18, weight: FontWeight.w700)
                  .copyWith(
                color: AppColors.text(context),
                letterSpacing: -0.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bo'sh holat ───────────────────────────────────────────────────────────────

class _EmptyShops extends StatelessWidget {
  final Color accent;
  const _EmptyShops({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Column(
          children: [
            Icon(Icons.location_searching_rounded,
                size: 36, color: AppColors.text3(context)),
            const SizedBox(height: 10),
            Text(
              'service_category.no_services'.tr(),
              style: AppTypography.soraSize(14, weight: FontWeight.w600)
                  .copyWith(color: AppColors.text(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'service_category.no_services_hint'.tr(),
              style: AppTypography.body.copyWith(
                  color: AppColors.text2(context), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
