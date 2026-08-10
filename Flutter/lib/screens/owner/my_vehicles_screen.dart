import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_plate.dart';

final _vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  return VehicleService().getVehicles();
});

class MyVehiclesScreen extends ConsumerStatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  ConsumerState<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends ConsumerState<MyVehiclesScreen> {
  final int _primaryIndex = 0;
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(_vehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: vehiclesAsync.when(
          data: (vehicles) => _buildContent(context, vehicles),
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(_vehiclesProvider),
              child: Text('common.retry'.tr()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Vehicle> vehicles) {
    final idx = _primaryIndex.clamp(0, math.max(0, vehicles.length - 1)).toInt();
    final primary = vehicles.isNotEmpty ? vehicles[idx] : null;
    final displayName = primary == null
        ? 'tabs.garage'.tr()
        : '${primary.make} ${primary.model}'.trim().isEmpty
            ? primary.plate
            : '${primary.make} ${primary.model}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.xs, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'owner.my_garage'.tr().toUpperCase(),
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.text3(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayName,
                      style: AppTypography.displayLarge
                          .copyWith(color: AppColors.text(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    context.push('/owner/vehicles/new').then((_) {
                  ref.invalidate(_vehiclesProvider);
                }),
                icon: Icon(Icons.add_rounded,
                    color: AppColors.text(context), size: 26),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Scrollable body ──────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.huge +
                  MediaQuery.of(context).padding.bottom +
                  AppSpacing.xxxl,
            ),
            child: Column(
              children: [
                if (primary != null) ...[
                  _CarCard(
                    vehicle: primary,
                    isActive: _isActive,
                    onToggle: (v) => setState(() => _isActive = v),
                    onEdit: () =>
                        context.push('/owner/vehicles/edit', extra: primary).then((_) {
                      ref.invalidate(_vehiclesProvider);
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FeatureGrid(vehicle: primary),
                  const SizedBox(height: AppSpacing.lg),
                ] else
                  _EmptyState(),

                _AddVehicleButton(
                  onTap: () =>
                      context.push('/owner/vehicles/new').then((_) {
                    ref.invalidate(_vehiclesProvider);
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Car Card ────────────────────────────────────────────────────────────────

class _CarCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _CarCard({
    required this.vehicle,
    required this.isActive,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Чип "Основной" + переключатель
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                _PrimaryChip(),
                const Spacer(),
                CupertinoSwitch(
                  value: isActive,
                  onChanged: onToggle,
                  activeTrackColor: AppColors.success,
                ),
              ],
            ),
          ),

          // Photo area
          _PhotoArea(photoUrl: vehicle.photoUrl),

          // Plate
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(child: MPlate(plate: vehicle.plate, large: true)),
          ),

          // Tire info row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                Icon(CupertinoIcons.circle,
                    size: 16, color: AppColors.text2(context)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'R15 185/65',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.text2(context)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onEdit,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(CupertinoIcons.settings,
                      size: 18, color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface2(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_full),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Text(
        'owner.primary'.tr(),
        style: AppTypography.labelSmall
            .copyWith(color: AppColors.text2(context)),
      ),
    );
  }
}

class _PhotoArea extends StatelessWidget {
  final String? photoUrl;
  const _PhotoArea({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _PlaceholderArea(),
          errorWidget: (context, url, error) => _PlaceholderArea(),
        ),
      );
    }
    return _PlaceholderArea();
  }
}

class _PlaceholderArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _StripePainter()),
            Center(
              child: Text(
                'AVTO FOTOSI',
                style: AppTypography.eyebrow.copyWith(
                  color: AppColors.text3(context),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const gap = 18.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Feature Grid ─────────────────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  final Vehicle vehicle;
  const _FeatureGrid({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.15,
      ),
      itemCount: tiles.length,
      itemBuilder: (ctx, i) => tiles[i],
    );
  }

  List<Widget> _tiles(BuildContext context) => [
        _FeatureTile(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.text3(context),
          title: 'owner.feature.jarimalar'.tr(),
          locked: true,
        ),
        _FeatureTile(
          icon: CupertinoIcons.scope,
          title: 'owner.feature.shinomontaj'.tr(),
          subtitle: 'owner.feature.shinomontaj_sub'.tr(),
          onTap: () {},
        ),
      ];
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool locked;

  const _FeatureTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_md),
            border: Border.all(color: AppColors.hairline(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      locked ? Icons.lock_rounded : icon,
                      size: 22,
                      color: iconColor ?? AppColors.text2(context),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.text(context),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.eyebrow.copyWith(
                          color: AppColors.text3(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              if (locked)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface2(context),
                      borderRadius: BorderRadius.circular(AppSpacing.r_full),
                      border: Border.all(color: AppColors.hairline(context)),
                    ),
                    child: Text(
                      'profile.coming_soon'.tr(),
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.text2(context),
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Vehicle Button ───────────────────────────────────────────────────────

class _AddVehicleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddVehicleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSpacing.buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_lg),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20, color: AppColors.text2(context)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'owner.add_vehicle'.tr(),
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.text2(context)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.car_detailed,
                size: 52, color: AppColors.text3(context)),
            const SizedBox(height: AppSpacing.md),
            Text('owner.no_vehicles'.tr(),
                style: AppTypography.titleSmall
                    .copyWith(color: AppColors.text2(context))),
          ],
        ),
      ),
    );
  }
}
