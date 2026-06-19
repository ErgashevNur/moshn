import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/promo.dart';
import '../../models/service_type.dart';
import '../../models/shop.dart';
import '../../services/notification_service.dart';
import '../../services/promo_service.dart';
import '../../services/shop_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_moshn_icon.dart';
import '../../widgets/m_ph.dart';
import '../../widgets/m_service_tile.dart';
import '../../widgets/m_tag.dart';
import '../../widgets/m_workshop_card.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final serviceTypesProvider = FutureProvider.autoDispose<List<ServiceType>>((ref) {
  return ShopService().getServiceTypes();
});

final _unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final list = await NotificationService().list();
    return list.where((n) => !n.read).length;
  } catch (_) {
    return 0;
  }
});

final selectedServiceTypeProvider = StateProvider<String?>((ref) => null);

final shopsProvider = FutureProvider.autoDispose<List<Shop>>((ref) {
  final type = ref.watch(selectedServiceTypeProvider);
  return ShopService().getShops(serviceType: type);
});

final activePromosProvider = FutureProvider.autoDispose<List<Promo>>((ref) {
  return PromoService().getActive();
});

// ── Responsive helper ──────────────────────────────────────────────────────────

class _R {
  final double w;
  const _R(this.w);

  bool get isSmall  => w < 300;
  bool get isNormal => w >= 300 && w < 600;
  bool get isMedium => w >= 600 && w < 840;
  bool get isLarge  => w >= 840;
  bool get isWide   => w >= 600;

  double get hPad  => w < 340 ? 14 : isWide ? 24 : 18;
  int    get cols  => isLarge ? 5 : isMedium ? 4 : isSmall ? 2 : 3;
  double get titleSize  => isSmall ? 20 : isWide ? 30 : 25;
  double get sectionSize => isSmall ? 15 : isWide ? 20 : 17;
  double get bodySize    => isSmall ? 13 : 15;
  double get imgSize     => isSmall ? 60 : isWide ? 88 : 72;
  double get tileAspect  => isLarge ? 1.1 : isWide ? 1.0 : 0.85;
}

// ── Icon mapping ───────────────────────────────────────────────────────────────

String _iconForSlug(String slug) {
  switch (slug) {
    case 'tire_change':  return 'disc';
    case 'pumping':      return 'gauge';
    case 'patch':        return 'wrench';
    case 'balancing':    return 'disc';
    case 'rim_repair':   return 'disc';
    case 'storage':      return 'layers';
    default:             return 'wrench';
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(authProvider).user;
    final typesAsync  = ref.watch(serviceTypesProvider);
    final shopsAsync  = ref.watch(shopsProvider);
    final selected    = ref.watch(selectedServiceTypeProvider);
    final promosAsync = ref.watch(activePromosProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, constraints) {
          final r = _R(constraints.maxWidth);

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r.hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeAppBar(user: user, r: r),
                  SizedBox(height: r.isSmall ? 14 : 20),

                  // Title
                  Text(
                    'home.what_service'.tr(),
                    style: AppTypography.soraSize(r.titleSize,
                            weight: FontWeight.w700)
                        .copyWith(
                      color: AppColors.text(context),
                      letterSpacing: r.titleSize * -0.03,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: r.isSmall ? 12 : 16),

                  // Search bar
                  _SearchBar(onTap: () => context.push('/owner/map'), r: r),
                  SizedBox(height: r.isSmall ? 14 : 20),

                  // Service type grid
                  typesAsync.when(
                    data: (types) => _ServiceTypeGrid(
                      types: types,
                      selectedSlug: selected,
                      r: r,
                      onTap: (slug) => context.push('/owner/services/$slug'),
                    ),
                    loading: () => SizedBox(
                      height: r.isSmall ? 120 : 160,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (e, st) => Padding(
                      padding: EdgeInsets.symmetric(vertical: r.isSmall ? 16 : 24),
                      child: Column(
                        children: [
                          Text(
                            'home.service_types_error'.tr(),
                            style: AppTypography.body.copyWith(color: AppColors.text3(context)),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => ref.invalidate(serviceTypesProvider),
                            child: Text(
                              'common.retry'.tr(),
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.text(context),
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.text(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: r.isSmall ? 16 : 24),

                  // Promo banner(lar) — backenddan kelgan faol promolar bo'lsagina ko'rinadi
                  promosAsync.maybeWhen(
                    data: (promos) => promos.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              _PromoCarousel(promos: promos, r: r),
                              SizedBox(height: r.isSmall ? 20 : 28),
                            ],
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // Section header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'home.top_services'.tr(),
                          style: AppTypography.soraSize(r.sectionSize,
                                  weight: FontWeight.w700)
                              .copyWith(color: AppColors.text(context)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/owner/map'),
                        child: Text(
                          'home.view_on_map'.tr(),
                          style: AppTypography.soraSize(r.isSmall ? 12 : 13,
                                  weight: FontWeight.w500)
                              .copyWith(color: AppColors.text2(context)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.isSmall ? 10 : 14),

                  // Shop list
                  shopsAsync.when(
                    data: (shops) => shops.isEmpty
                        ? _EmptyShops(r: r)
                        : r.isWide
                            ? _ShopGrid(shops: shops, r: r)
                            : _ShopList(shops: shops, r: r),
                    loading: () => Padding(
                      padding: EdgeInsets.symmetric(vertical: r.isSmall ? 24 : 40),
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('home.error_label'.tr(),
                            style: AppTypography.body
                                .copyWith(color: AppColors.danger)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── AppBar ─────────────────────────────────────────────────────────────────────

class _HomeAppBar extends ConsumerWidget {
  final dynamic user;
  final _R r;
  const _HomeAppBar({required this.user, required this.r});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconSize = r.isSmall ? 36.0 : 42.0;
    final unread = ref.watch(_unreadCountProvider).valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'home.near_you'.tr(),
                  style: AppTypography.eyebrow
                      .copyWith(color: AppColors.text3(context)),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoshnIcon(
                      name: 'pin',
                      size: r.isSmall ? 13 : 15,
                      color: AppColors.text(context),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'home.location_all'.tr(),
                        style: AppTypography.soraSize(
                                r.isSmall ? 13 : 15,
                                weight: FontWeight.w600)
                            .copyWith(color: AppColors.text(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: r.isSmall ? 6 : 10),

          // Bell
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _IconCircle(size: iconSize, child:
                  Icon(Icons.notifications_outlined,
                      size: iconSize * 0.48, color: AppColors.text(context))),
                if (unread > 0)
                  Positioned(
                    top: iconSize * 0.18,
                    right: iconSize * 0.18,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFFE5382B), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: r.isSmall ? 6 : 8),

          // Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: iconSize, height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline(context), width: 1),
              ),
              child: ClipOval(child: MPh(width: iconSize, height: iconSize, label: 'AV')),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final double size;
  final Widget child;
  const _IconCircle({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface(context),
        border: Border.all(color: AppColors.hairline(context), width: 1),
      ),
      child: child,
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final _R r;
  const _SearchBar({required this.onTap, required this.r});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: r.isSmall ? 46 : 52,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(color: AppColors.hairline(context), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: r.isSmall ? 18 : 20, color: AppColors.text3(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'home.search_hint'.tr(),
                style: AppTypography.soraSize(r.isSmall ? 13 : 15)
                    .copyWith(color: AppColors.text3(context)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service type grid ──────────────────────────────────────────────────────────

class _ServiceTypeGrid extends StatelessWidget {
  final List<ServiceType> types;
  final String? selectedSlug;
  final _R r;
  final void Function(String) onTap;

  const _ServiceTypeGrid({
    required this.types,
    required this.selectedSlug,
    required this.r,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: types.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: r.cols,
        crossAxisSpacing: r.isSmall ? 8 : 10,
        mainAxisSpacing: r.isSmall ? 8 : 10,
        childAspectRatio: r.tileAspect,
      ),
      itemBuilder: (context, i) {
        final t = types[i];
        final locale = context.locale.languageCode;
        return MServiceTile(
          label: t.nameFor(locale),
          iconName: _iconForSlug(t.slug),
          active: selectedSlug == t.slug,
          onTap: () => onTap(t.slug),
        );
      },
    );
  }
}

// ── Promo carousel (bir nechta faol banner bo'lsa) ───────────────────────────────

class _PromoCarousel extends StatefulWidget {
  final List<Promo> promos;
  final _R r;
  const _PromoCarousel({required this.promos, required this.r});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promos = widget.promos;
    final r      = widget.r;

    if (promos.length == 1) {
      return _PromoBanner(promo: promos.first, r: r);
    }

    return Column(
      children: [
        SizedBox(
          height: r.isSmall ? 96 : 116,
          child: PageView.builder(
            controller: _controller,
            itemCount: promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _PromoBanner(promo: promos[i], r: r),
          ),
        ),
        SizedBox(height: r.isSmall ? 8 : 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(promos.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active
                    ? AppColors.text(context)
                    : AppColors.text3(context),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Promo banner ───────────────────────────────────────────────────────────────

class _PromoBanner extends StatefulWidget {
  final Promo promo;
  final _R r;
  const _PromoBanner({required this.promo, required this.r});

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  @override
  void initState() {
    super.initState();
    // Banner ekranga chiqdi — bir martalik "view" hisoblanadi
    PromoService().trackView(widget.promo.id);
  }

  @override
  Widget build(BuildContext context) {
    final r        = widget.r;
    final promo    = widget.promo;
    final locale   = context.locale.languageCode;
    final badge    = promo.badgeFor(locale);
    final title    = promo.titleFor(locale);

    return GestureDetector(
      onTap: () => PromoService().trackClick(promo.id),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: r.isSmall ? 96 : 116),
        decoration: BoxDecoration(
          color: AppColors.inverseBg(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
          child: Stack(
            children: [
              Positioned(
                top: -28, right: -20,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.inverseText(context).withAlpha(20),
                  ),
                ),
              ),
              Positioned(
                bottom: -40, right: 60,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.inverseText(context).withAlpha(13),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: r.isSmall ? 16 : 20,
                    vertical: r.isSmall ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge.isNotEmpty)
                      MTag(label: badge, variant: MTagVariant.gold),
                    if (badge.isNotEmpty) const SizedBox(height: 10),
                    Text(
                      title,
                      style: AppTypography.soraSize(
                              r.isSmall ? 16 : 19,
                              weight: FontWeight.w700)
                          .copyWith(
                        color: AppColors.inverseText(context),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shop list (phone) ──────────────────────────────────────────────────────────

class _ShopList extends StatelessWidget {
  final List<Shop> shops;
  final _R r;
  const _ShopList({required this.shops, required this.r});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: shops.map((s) => Padding(
        padding: EdgeInsets.only(bottom: r.isSmall ? 8 : 10),
        child: WorkshopCard(
          name: s.shopName,
          rating: s.ratingAvg,
          reviewCount: s.ratingCount,
          address: s.address,
          distance: s.distanceKm != null
              ? '${s.distanceKm!.toStringAsFixed(1)} km'
              : null,
          duration: null,
          isOpen: true,
          onTap: () => context.push('/owner/shops/${s.id}'),
        ),
      )).toList(),
    );
  }
}

// ── Shop grid (tablet) ─────────────────────────────────────────────────────────

class _ShopGrid extends StatelessWidget {
  final List<Shop> shops;
  final _R r;
  const _ShopGrid({required this.shops, required this.r});

  @override
  Widget build(BuildContext context) {
    final cols = r.isLarge ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shops.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) {
        final s = shops[i];
        return WorkshopCard(
          name: s.shopName,
          rating: s.ratingAvg,
          reviewCount: s.ratingCount,
          address: s.address,
          distance: s.distanceKm != null
              ? '${s.distanceKm!.toStringAsFixed(1)} km'
              : null,
          isOpen: true,
          compact: true,
          onTap: () => context.push('/owner/shops/${s.id}'),
        );
      },
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyShops extends StatelessWidget {
  final _R r;
  const _EmptyShops({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: r.isSmall ? 28 : 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        border: Border.all(color: AppColors.hairline(context), width: 1),
      ),
      child: Column(
        children: [
          Text('🔍', style: TextStyle(fontSize: r.isSmall ? 32 : 40)),
          SizedBox(height: r.isSmall ? 8 : 12),
          Text(
            'home.no_shops'.tr(),
            style: AppTypography.soraSize(r.isSmall ? 14 : 16,
                    weight: FontWeight.w600)
                .copyWith(color: AppColors.text(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'home.no_shops_hint'.tr(),
            style: AppTypography.body
                .copyWith(color: AppColors.text2(context)),
          ),
        ],
      ),
    );
  }
}
