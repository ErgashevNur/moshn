import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../models/shop.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_workshop_card.dart';
import 'home_screen.dart' show shopsProvider;

// ── Центр Ташкента ───────────────────────────────────────────────────────────
const _tashkent = Point(latitude: 41.2995, longitude: 69.2401);

// ── Провайдер активного сервиса ─────────────────────────────────────────────
final _activeShopIdProvider = StateProvider<String?>((ref) => null);

// ── Screen ────────────────────────────────────────────────────────────────────

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  YandexMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _moveTo(Point point, {double zoom = 14}) async {
    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: zoom),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.6,
      ),
    );
  }

  List<MapObject> _buildMapObjects(List<Shop> shops) {
    return shops
        .where((s) => s.latitude != 0 || s.longitude != 0)
        .map((shop) {
      final isActive = shop.id == ref.read(_activeShopIdProvider);
      return PlacemarkMapObject(
        mapId: MapObjectId(shop.id),
        point: Point(latitude: shop.latitude, longitude: shop.longitude),
        opacity: 1.0,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(
              isActive
                  ? 'assets/images/pin_active.png'
                  : 'assets/images/pin.png',
            ),
            scale: isActive ? 2.2 : 1.8,
            anchor: const Offset(0.5, 1.0),
          ),
        ),
        text: PlacemarkText(
          text: shop.shopName,
          style: PlacemarkTextStyle(
            size: 11,
            color: const Color(0xFF1A1A1A),
            outlineColor: const Color(0xFFFFFFFF),
            placement: TextStylePlacement.bottom,
            offset: 4,
            offsetFromIcon: true,
          ),
        ),
        onTap: (_, p) {
          ref.read(_activeShopIdProvider.notifier).state = shop.id;
          _moveTo(Point(latitude: shop.latitude, longitude: shop.longitude));
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsProvider);
    final activeId = ref.watch(_activeShopIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // ── Yandex xarita ──────────────────────────────────────────────────
          Positioned.fill(
            child: shopsAsync.when(
              data: (shops) => YandexMap(
                onMapCreated: (controller) async {
                  _mapController = controller;
                  await _moveTo(_tashkent, zoom: 12);
                },
                mapObjects: _buildMapObjects(shops),
                onMapTap: (_) {
                  ref.read(_activeShopIdProvider.notifier).state = null;
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, p) => YandexMap(
                onMapCreated: (controller) async {
                  _mapController = controller;
                  await _moveTo(_tashkent, zoom: 12);
                },
                mapObjects: const [],
              ),
            ),
          ),

          // ── Yuqori panel ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _TopBar(onBack: () => context.pop()),
          ),

          // ── Кнопка "Моё местоположение" ──────────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 72,
            child: _MyLocationButton(
              onTap: () => _moveTo(_tashkent, zoom: 13),
            ),
          ),

          // ── Pastki sheet ────────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.15,
            maxChildSize: 0.80,
            builder: (context, scrollController) {
              return _BottomSheet(
                shopsAsync: shopsAsync,
                activeId: activeId,
                scrollController: scrollController,
                onShopTap: (shop) {
                  ref.read(_activeShopIdProvider.notifier).state = shop.id;
                  _moveTo(
                    Point(latitude: shop.latitude, longitude: shop.longitude),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.bgElevated(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        boxShadow: AppSpacing.shadow2,
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.chevron_left_rounded,
                    size: 22, color: AppColors.text(context)),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Карта сервисов',
              style: AppTypography.soraSize(14, weight: FontWeight.w600)
                  .copyWith(color: AppColors.text(context)),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ── My location button ────────────────────────────────────────────────────────

class _MyLocationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MyLocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.bgElevated(context),
          shape: BoxShape.circle,
          boxShadow: AppSpacing.shadow2,
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Icon(Icons.my_location_rounded,
            size: 20, color: AppColors.text(context)),
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final AsyncValue<List<Shop>> shopsAsync;
  final String? activeId;
  final ScrollController scrollController;
  final void Function(Shop) onShopTap;

  const _BottomSheet({
    required this.shopsAsync,
    required this.activeId,
    required this.scrollController,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated(context),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppSpacing.r_2xl)),
        boxShadow: AppSpacing.shadowPop,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface3(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_full),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                shopsAsync.maybeWhen(
                  data: (shops) => Text(
                    'home.nearby_count'
                        .tr(namedArgs: {'count': '${shops.length}'}),
                    style: AppTypography.soraSize(17, weight: FontWeight.w700)
                        .copyWith(color: AppColors.text(context)),
                  ),
                  orElse: () => Text(
                    'common.loading'.tr(),
                    style: AppTypography.soraSize(17, weight: FontWeight.w600)
                        .copyWith(color: AppColors.text2(context)),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: shopsAsync.when(
              data: (shops) {
                if (shops.isEmpty) {
                  return Center(
                    child: Text('home.no_shops'.tr(),
                        style: AppTypography.body
                            .copyWith(color: AppColors.text2(context))),
                  );
                }
                final sorted = [...shops];
                if (activeId != null) {
                  sorted.sort((a, b) {
                    if (a.id == activeId) return -1;
                    if (b.id == activeId) return 1;
                    return 0;
                  });
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: sorted.length,
                  separatorBuilder: (_, p) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = sorted[i];
                    return WorkshopCard(
                      name: s.shopName,
                      rating: s.ratingAvg,
                      reviewCount: s.ratingCount,
                      address: s.address,
                      distance: s.distanceKm != null
                          ? '${s.distanceKm!.toStringAsFixed(1)} km'
                          : null,
                      duration: s.workingHours.isNotEmpty
                          ? s.workingHours
                          : null,
                      isOpen: true,
                      onTap: () {
                        onShopTap(s);
                        context.push('/owner/shops/${s.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Text('common.error'.tr(),
                    style:
                        AppTypography.body.copyWith(color: AppColors.danger)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
