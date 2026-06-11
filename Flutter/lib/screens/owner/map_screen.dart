import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/shop.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_workshop_card.dart';
import 'home_screen.dart' show shopsProvider;

// ── Provider ──────────────────────────────────────────────────────────────────

final _activeShopIdProvider = StateProvider<String?>((ref) => null);

// ── Mock pin positions (fractional offset on a 375-wide canvas) ───────────────

class _PinData {
  final String shopId;
  final String priceLabel; // e.g. "35 000"
  final double left; // fraction of width  0..1
  final double top; // fraction of height 0..1

  const _PinData({
    required this.shopId,
    required this.priceLabel,
    required this.left,
    required this.top,
  });
}

// We use deterministic fractional positions so the map looks reasonable
// on any screen size.
List<_PinData> _buildPins(List<Shop> shops) {
  const positions = [
    (0.18, 0.22),
    (0.55, 0.15),
    (0.72, 0.35),
    (0.30, 0.50),
    (0.60, 0.55),
    (0.15, 0.62),
    (0.80, 0.68),
    (0.42, 0.72),
  ];
  return List.generate(shops.length.clamp(0, positions.length), (i) {
    final s = shops[i];
    final price = s.ratingAvg > 0
        ? '${(s.ratingAvg * 10000).round()} so\'m'
        : '35 000';
    return _PinData(
      shopId: s.id,
      priceLabel: price,
      left: positions[i].$1,
      top: positions[i].$2,
    );
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopsProvider);
    final activeId = ref.watch(_activeShopIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // 1. Stylized background map
          const Positioned.fill(child: _MapBackground()),

          // 2. Price pin bubbles
          shopsAsync.maybeWhen(
            data: (shops) {
              final pins = _buildPins(shops);
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: pins.map((pin) {
                      final isActive = pin.shopId == activeId;
                      return Positioned(
                        left: pin.left * constraints.maxWidth,
                        top: pin.top * (constraints.maxHeight * 0.62),
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(_activeShopIdProvider.notifier)
                                .state = pin.shopId;
                          },
                          child: _PriceBubble(
                            label: pin.priceLabel,
                            active: isActive,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // 3. Floating top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _TopBar(onBack: () => context.pop()),
          ),

          // 4. My location button
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.38,
            child: _MyLocationButton(),
          ),

          // 5. Bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.44,
            minChildSize: 0.18,
            maxChildSize: 0.82,
            builder: (context, scrollController) {
              return _BottomSheetContent(
                shopsAsync: shopsAsync,
                activeId: activeId,
                scrollController: scrollController,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Map background painter ────────────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(context: context),
      size: Size.infinite,
    );
  }
}

class _MapPainter extends CustomPainter {
  final BuildContext context;
  _MapPainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    // Land fill
    final bgPaint = Paint()..color = AppColors.bg(context);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Blocks (surface3)
    final blockPaint = Paint()..color = AppColors.surface3(context);
    final blocks = [
      Rect.fromLTWH(size.width * 0.05, size.height * 0.05, size.width * 0.28, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.38, size.height * 0.03, size.width * 0.24, size.height * 0.09),
      Rect.fromLTWH(size.width * 0.68, size.height * 0.06, size.width * 0.26, size.height * 0.14),
      Rect.fromLTWH(size.width * 0.06, size.height * 0.23, size.width * 0.18, size.height * 0.16),
      Rect.fromLTWH(size.width * 0.30, size.height * 0.22, size.width * 0.32, size.height * 0.10),
      Rect.fromLTWH(size.width * 0.68, size.height * 0.28, size.width * 0.25, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.08, size.height * 0.44, size.width * 0.20, size.height * 0.14),
      Rect.fromLTWH(size.width * 0.35, size.height * 0.40, size.width * 0.18, size.height * 0.16),
      Rect.fromLTWH(size.width * 0.62, size.height * 0.46, size.width * 0.30, size.height * 0.10),
      Rect.fromLTWH(size.width * 0.10, size.height * 0.64, size.width * 0.22, size.height * 0.10),
      Rect.fromLTWH(size.width * 0.40, size.height * 0.60, size.width * 0.16, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.64, size.height * 0.62, size.width * 0.28, size.height * 0.13),
    ];
    const radius = Radius.circular(6);
    for (final r in blocks) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, radius), blockPaint);
    }

    // Roads (surface2)
    final roadPaint = Paint()
      ..color = AppColors.surface2(context)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Horizontal roads
    final hRoads = [0.19, 0.34, 0.50, 0.66];
    for (final frac in hRoads) {
      canvas.drawLine(
        Offset(0, size.height * frac),
        Offset(size.width, size.height * frac),
        roadPaint,
      );
    }

    // Vertical roads
    final vRoads = [0.26, 0.50, 0.64, 0.82];
    for (final frac in vRoads) {
      canvas.drawLine(
        Offset(size.width * frac, 0),
        Offset(size.width * frac, size.height * 0.7),
        roadPaint,
      );
    }

    // Diagonal accent road
    final diagPaint = Paint()
      ..color = AppColors.surface2(context)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.55, size.height * 0.22),
      diagPaint,
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) => false;
}

// ── Price bubble ──────────────────────────────────────────────────────────────

class _PriceBubble extends StatelessWidget {
  final String label;
  final bool active;

  const _PriceBubble({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.inverseBg(context) : AppColors.bgElevated(context);
    final fg = active ? AppColors.inverseText(context) : AppColors.text(context);
    final scale = active ? 1.1 : 1.0;

    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              boxShadow: active ? AppSpacing.shadow2 : AppSpacing.shadow1,
            ),
            child: Text(
              label,
              style: AppTypography.soraSize(active ? 13 : 12,
                      weight: active ? FontWeight.w700 : FontWeight.w500)
                  .copyWith(color: fg),
            ),
          ),
          // Triangle
          CustomPaint(
            size: const Size(12, 6),
            painter: _TrianglePainter(color: bg),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
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
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: AppColors.text(context),
                ),
              ),
            ),
          ),
          // Search field
          Expanded(
            child: Text(
              'Servis qidiring…',
              style: AppTypography.soraSize(14).copyWith(
                color: AppColors.text3(context),
              ),
            ),
          ),
          // Filter button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: AppColors.text(context),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── My location button ────────────────────────────────────────────────────────

class _MyLocationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.bgElevated(context),
        shape: BoxShape.circle,
        boxShadow: AppSpacing.shadow2,
        border: Border.all(color: AppColors.hairline(context), width: 1),
      ),
      child: Icon(
        Icons.my_location_rounded,
        size: 20,
        color: AppColors.text(context),
      ),
    );
  }
}

// ── Bottom sheet content ──────────────────────────────────────────────────────

class _BottomSheetContent extends StatelessWidget {
  final AsyncValue<List<Shop>> shopsAsync;
  final String? activeId;
  final ScrollController scrollController;

  const _BottomSheetContent({
    required this.shopsAsync,
    required this.activeId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.r_2xl),
        ),
        boxShadow: AppSpacing.shadowPop,
      ),
      child: Column(
        children: [
          // Grip
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
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                shopsAsync.maybeWhen(
                  data: (shops) => Text(
                    'home.nearby_count'.tr(namedArgs: {'count': '${shops.length}'}),
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
          const SizedBox(height: 14),

          // List
          Expanded(
            child: shopsAsync.when(
              data: (shops) {
                if (shops.isEmpty) {
                  return Center(
                    child: Text(
                      'home.no_shops'.tr(),
                      style: AppTypography.body
                          .copyWith(color: AppColors.text2(context)),
                    ),
                  );
                }

                // Sort: active shop first
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
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                      duration: s.workingHours.isNotEmpty ? s.workingHours : null,
                      isOpen: true,
                      onTap: () => context.push('/owner/shops/${s.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  'common.error'.tr(),
                  style:
                      AppTypography.body.copyWith(color: AppColors.danger),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
