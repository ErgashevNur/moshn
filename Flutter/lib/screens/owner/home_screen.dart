import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/promo.dart';
import '../../models/service_category.dart';
import '../../models/service_type.dart';
import '../../models/shop.dart';
import '../../models/vehicle.dart';
import '../../services/notification_service.dart';
import '../../services/promo_service.dart';
import '../../services/shop_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_pitgo_icon.dart';
import '../../widgets/m_plate.dart';
import '../../widgets/m_tag.dart';
import '../../widgets/m_workshop_card.dart';
import 'my_vehicles_screen.dart' show vehiclesProvider;

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

  // Xizmat kataklari: telefonda 2 ustun (katakda ikonka + sarlavha + izoh
  // bo'lgani uchun kenglik kerak), planshetda ko'proq.
  int    get tileCols    => isLarge ? 4 : isMedium ? 3 : 2;
  // Balandlik kontent uchun yetarli bo'lishi shart — juda "yassi" qilinsa
  // izoh qatori sig'may qoladi.
  double get tileAspect  => isLarge ? 1.85 : isWide ? 1.7 : 1.5;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(authProvider).user;
    final shopsAsync  = ref.watch(shopsProvider);
    final promosAsync = ref.watch(activePromosProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);

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

                  // Mijozning avtomobili — yuklanmaguncha/xato bo'lsa joy
                  // egallamaydi (bosh ekran sakrab ketmasin).
                  vehiclesAsync.maybeWhen(
                    data: (vehicles) => Column(
                      children: [
                        _VehicleCarousel(vehicles: vehicles, r: r),
                        SizedBox(height: r.isSmall ? 14 : 20),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // Qidiruv
                  _SearchBar(onTap: () => context.push('/owner/search'), r: r),
                  SizedBox(height: r.isSmall ? 16 : 22),

                  // "Servislar" bo'lim sarlavhasi + butun katalogga havola
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'category.title'.tr(),
                          style: AppTypography.soraSize(r.sectionSize,
                                  weight: FontWeight.w700)
                              .copyWith(color: AppColors.text(context)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/owner/category/all'),
                        child: Text(
                          'category.all_services'.tr(),
                          style: AppTypography.soraSize(r.isSmall ? 12 : 13,
                                  weight: FontWeight.w600)
                              .copyWith(color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.isSmall ? 10 : 14),

                  // Xizmat kategoriyalari — 5 guruh + SOS. Ro'yxat statik
                  // (`kServiceCategories`), shuning uchun tarmoq javobini
                  // kutmasdan darhol chiziladi; kategoriya ichidagi aniq
                  // xizmatlar keyingi ekranda yuklanadi.
                  _ServiceCategoryGrid(
                    r: r,
                    onTap: (categoryId) => context.push('/owner/category/$categoryId'),
                    onSosTap: () => context.push('/owner/sos'),
                  ),
                  SizedBox(height: r.isSmall ? 16 : 24),

                  // Промо-баннер(ы) — показывается только если есть активные промо с backend'а
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

  /// "Salom, {ism}" — ism bo'lmasa faqat salomlashuv (yangi foydalanuvchi
  /// profilni hali to'ldirmagan bo'lishi mumkin).
  String _greeting() {
    final name = (user?.name as String?)?.trim() ?? '';
    if (name.isEmpty) return 'home.greeting_plain'.tr();
    final first = name.split(RegExp(r'\s+')).first;
    return 'home.greeting'.tr(namedArgs: {'name': first});
  }

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
                // Joylashuv — kichik, tepada
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PitGoIcon(
                      name: 'pin',
                      size: r.isSmall ? 11 : 12,
                      color: AppColors.text3(context),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'home.location_all'.tr().toUpperCase(),
                        style: AppTypography.eyebrow
                            .copyWith(color: AppColors.text3(context)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Salomlashuv — asosiy sarlavha
                Text(
                  _greeting(),
                  style: AppTypography.soraSize(
                          r.isSmall ? 19 : 23, weight: FontWeight.w700)
                      .copyWith(
                    color: AppColors.text(context),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: r.isSmall ? 6 : 10),

          // SOS endi pastki bar markazida (owner_root.dart, centerDocked FAB).

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

// ── Service category grid ────────────────────────────────────────────────────
// Xizmat turlari soni o'sib boraveradi (admin istagancha qo'shadi) — bosh
// ekranda tartibsiz to'planib qolmasin uchun avval kategoriya tanlanadi,
// keyin o'sha kategoriya ichidagi turlar ko'rsatiladi (service_group_screen.dart).

class _ServiceCategoryGrid extends StatelessWidget {
  final _R r;
  final void Function(String categoryId) onTap;
  final VoidCallback onSosTap;

  const _ServiceCategoryGrid({
    required this.r,
    required this.onTap,
    required this.onSosTap,
  });

  @override
  Widget build(BuildContext context) {
    // Oltala katak DOIM ko'rinadi — 5 kategoriya + SOS. Kataklar ortida hozir
    // xizmat turi bor-yo'qligiga qarab yashirilmaydi: bosh ekran tarkibi
    // barqaror bo'lishi kerak (admin katalogni to'ldirgani sayin o'zgarib
    // ketmasin). Bo'sh kategoriya ochilsa — `category.empty` xabari chiqadi
    // (service_group_screen.dart).
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kServiceCategories.length + 1,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: r.tileCols,
        crossAxisSpacing: r.isSmall ? 8 : 10,
        mainAxisSpacing: r.isSmall ? 8 : 10,
        childAspectRatio: r.tileAspect,
      ),
      itemBuilder: (context, i) {
        if (i == kServiceCategories.length) {
          return _ServiceCard(
            title: 'category.sos'.tr(),
            subtitle: 'category.sos_sub'.tr(),
            iconName: 'wrench',
            accent: AppColors.danger,
            isSos: true,
            onTap: onSosTap,
          );
        }
        final c = kServiceCategories[i];
        return _ServiceCard(
          title: c.labelKey.tr(),
          subtitle: c.subLabelKey.tr(),
          iconName: c.icon,
          accent: AppColors.gold,
          onTap: () => onTap(c.id),
        );
      },
    );
  }
}

// ── Xizmat katagi ─────────────────────────────────────────────────────────────
// Ikonka tepada chapda (brend rangida), ostida sarlavha va nima kirishini
// bir qarashda ko'rsatuvchi izoh.

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconName;
  final Color accent;
  final bool isSos;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.accent,
    required this.onTap,
    this.isSos = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final pad = (w * 0.09).clamp(10.0, 16.0);
        final iconSize = (w * 0.16).clamp(18.0, 26.0);
        final titleSize = (w * 0.105).clamp(12.5, 16.0);
        final subSize = (w * 0.082).clamp(10.0, 12.5);

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_lg),
            border: Border.all(color: AppColors.hairline(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SOS uchun ikonka o'rniga "SOS" belgisi — icon to'plamida
              // mos belgi yo'q, `_SosFab` ham shu ko'rinishda.
              if (isSos)
                Container(
                  height: iconSize,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppSpacing.r_full),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'SOS',
                      style: AppTypography.soraSize(10, weight: FontWeight.w800)
                          .copyWith(color: Colors.white, letterSpacing: -0.2),
                    ),
                  ),
                )
              else
                PitGoIcon(name: iconName, size: iconSize, color: accent),
              SizedBox(height: pad * 0.55),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.soraSize(titleSize,
                            weight: FontWeight.w700)
                        .copyWith(color: AppColors.text(context), height: 1.15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.text3(context),
                      fontSize: subSize,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Mashina kartasi karuseli ──────────────────────────────────────────────────
// Bosh ekran tepasida mijozning o'z avtomobil(lar)i. Bir nechta bo'lsa —
// suriladi (`_PromoCarousel` bilan bir xil andoza), umuman bo'lmasa —
// "mashina qo'shish" taklifi.

class _VehicleCarousel extends StatefulWidget {
  final List<Vehicle> vehicles;
  final _R r;

  const _VehicleCarousel({required this.vehicles, required this.r});

  @override
  State<_VehicleCarousel> createState() => _VehicleCarouselState();
}

class _VehicleCarouselState extends State<_VehicleCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = widget.vehicles;
    final r = widget.r;

    if (vehicles.isEmpty) return _AddVehicleCard(r: r);
    if (vehicles.length == 1) return _VehicleCard(vehicle: vehicles.first, r: r);

    return Column(
      children: [
        SizedBox(
          height: _cardHeight(r),
          child: PageView.builder(
            controller: _controller,
            itemCount: vehicles.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              // Kartalar orasida ozgina havo — surilganda chekkasi ko'rinadi
              padding: EdgeInsets.only(right: r.isSmall ? 8 : 10),
              child: _VehicleCard(vehicle: vehicles[i], r: r),
            ),
          ),
        ),
        SizedBox(height: r.isSmall ? 8 : 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(vehicles.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active ? AppColors.text(context) : AppColors.text3(context),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Qora "hero" karta — mavzudan qat'i nazar to'q (dizayn shunday), shuning
// uchun ranglar shu yerda aniq belgilangan, AppColors token'lari emas.
const _cardBg = Color(0xFF121214);
const _cardPanel = Color(0xFF1C1C20);
const _cardBorder = Color(0xFF2A2A30);
const _cardTextDim = Color(0xFF8A8A94);

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final _R r;

  const _VehicleCard({required this.vehicle, required this.r});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final title = [v.make, v.model].where((s) => s.isNotEmpty).join(' ');
    final photo = v.photoUrl;
    final small = r.isSmall;
    final thumb = small ? 56.0 : 66.0;
    final kmLeft = v.kmToService;

    return GestureDetector(
      onTap: () => context.push('/owner/vehicles/edit', extra: v),
      child: Container(
        padding: EdgeInsets.all(small ? 12 : 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.r_sm),
                  child: SizedBox(
                    width: thumb,
                    height: thumb,
                    child: photo != null && photo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photo,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const _VehiclePhotoFallback(),
                            errorWidget: (_, _, _) => const _VehiclePhotoFallback(),
                          )
                        : const _VehiclePhotoFallback(),
                  ),
                ),
                SizedBox(width: small ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Holat belgisi
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.r_full),
                        ),
                        child: Text(
                          'vehicle.active'.tr(),
                          style: AppTypography.soraSize(9.5,
                                  weight: FontWeight.w600)
                              .copyWith(color: AppColors.success),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title.isNotEmpty ? title : v.plate,
                        style: AppTypography.soraSize(small ? 15 : 17,
                                weight: FontWeight.w700)
                            .copyWith(color: Colors.white, height: 1.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: MPlate(plate: v.plate),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: _cardTextDim),
              ],
            ),
            // Probeg / keyingi TO — faqat mijoz kiritgan bo'lsa.
            if (v.mileageKm > 0 || kmLeft != null) ...[
              SizedBox(height: small ? 10 : 12),
              Row(
                children: [
                  if (v.mileageKm > 0)
                    Expanded(
                      child: _VehicleStat(
                        label: 'vehicle.mileage_short'.tr(),
                        value: '${_fmtKm(v.mileageKm)} km',
                        small: small,
                      ),
                    ),
                  if (v.mileageKm > 0 && kmLeft != null)
                    SizedBox(width: small ? 8 : 10),
                  if (kmLeft != null)
                    Expanded(
                      child: _VehicleStat(
                        label: 'vehicle.next_service_short'.tr(),
                        value: 'vehicle.in_km'
                            .tr(namedArgs: {'km': _fmtKm(kmLeft)}),
                        valueColor: AppColors.gold,
                        small: small,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmtKm(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

/// Karusel (`PageView`) chegaralangan balandlik talab qiladi. Qiymat eng
/// "to'la" holatga (probeg + TO paneli bilan) mo'ljallangan — ma'lumoti
/// kamroq kartalar yuqoriga tekislanadi.
double _cardHeight(_R r) => r.isSmall ? 158 : (r.isWide ? 196 : 178);

class _VehicleStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool small;

  const _VehicleStat({
    required this.label,
    required this.value,
    required this.small,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 12, vertical: small ? 8 : 10),
      decoration: BoxDecoration(
        color: _cardPanel,
        borderRadius: BorderRadius.circular(AppSpacing.r_sm),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.soraSize(9.5, weight: FontWeight.w500)
                .copyWith(color: _cardTextDim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.soraSize(small ? 12.5 : 14,
                    weight: FontWeight.w700)
                .copyWith(color: valueColor ?? Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VehiclePhotoFallback extends StatelessWidget {
  const _VehiclePhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface2(context),
      alignment: Alignment.center,
      child: PitGoIcon(
        name: 'car',
        size: 44,
        color: AppColors.text3(context),
      ),
    );
  }
}

class _AddVehicleCard extends StatelessWidget {
  final _R r;

  const _AddVehicleCard({required this.r});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/owner/vehicles/new'),
      child: Container(
        padding: EdgeInsets.all(r.isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_lg),
          border: Border.all(
            color: AppColors.hairline2(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: r.isSmall ? 36 : 42,
              height: r.isSmall ? 36 : 42,
              decoration: BoxDecoration(
                color: AppColors.surface2(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add_rounded,
                  size: 20, color: AppColors.text2(context)),
            ),
            SizedBox(width: r.isSmall ? 10 : 14),
            Expanded(
              child: Text(
                'vehicle.add'.tr(),
                style: AppTypography.soraSize(r.isSmall ? 13 : 15,
                        weight: FontWeight.w600)
                    .copyWith(color: AppColors.text(context)),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.text3(context)),
          ],
        ),
      ),
    );
  }
}

// ── Промо-карусель (если активно несколько баннеров) ─────────────────────────────

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
    // Баннер показался на экране — засчитывается одноразовый "view"
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
      children: List.generate(shops.length, (i) {
        final s = shops[i];
        return Padding(
          padding: EdgeInsets.only(bottom: r.isSmall ? 8 : 10),
          child: _ShopRow(
            shop: s,
            rank: i + 1,
            r: r,
            onTap: () => context.push('/owner/shops/${s.id}'),
          ),
        );
      }),
    );
  }
}

// ── Servis qatori (bosh ekran, "top" ro'yxati) ────────────────────────────────
// Reytingga ko'ra tartiblangan ro'yxat bo'lgani uchun har qator o'z o'rin
// raqami bilan chiqadi. Umumiy `WorkshopCard` boshqa 3 ta ekranda
// ishlatilgani uchun unga tegilmadi — bu ko'rinish faqat shu yerga xos.

class _ShopRow extends StatelessWidget {
  final Shop shop;
  final int rank;
  final _R r;
  final VoidCallback onTap;

  const _ShopRow({
    required this.shop,
    required this.rank,
    required this.r,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = shop;
    final small = r.isSmall;
    final sub = [
      if (s.address.isNotEmpty) s.address,
      if (s.distanceKm != null) '${s.distanceKm!.toStringAsFixed(1)} km',
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(small ? 10 : 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Row(
          children: [
            // O'rin raqami
            Container(
              width: small ? 24 : 28,
              height: small ? 24 : 28,
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(AppSpacing.r_xs),
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: AppTypography.soraSize(small ? 11 : 12.5,
                        weight: FontWeight.w700)
                    .copyWith(color: AppColors.gold),
              ),
            ),
            SizedBox(width: small ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.shopName.isNotEmpty ? s.shopName : 'PitGo',
                    style: AppTypography.soraSize(small ? 13 : 14.5,
                            weight: FontWeight.w700)
                        .copyWith(color: AppColors.text(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: AppTypography.body.copyWith(
                        color: AppColors.text3(context),
                        fontSize: small ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: small ? 12 : 13, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text(
                        s.ratingCount > 0
                            ? s.ratingAvg.toStringAsFixed(1)
                            : '—',
                        style: AppTypography.soraSize(small ? 11 : 12,
                                weight: FontWeight.w600)
                            .copyWith(color: AppColors.text2(context)),
                      ),
                      if (s.ratingCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          'home.reviews_count'
                              .tr(namedArgs: {'count': '${s.ratingCount}'}),
                          style: AppTypography.body.copyWith(
                            color: AppColors.text3(context),
                            fontSize: small ? 10.5 : 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.text3(context)),
          ],
        ),
      ),
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
