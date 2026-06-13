import 'dart:math' as math;

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

  const _CarCard({
    required this.vehicle,
    required this.isActive,
    required this.onToggle,
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
          // "Asosiy" chip + toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                _AsosiyChip(),
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
            child: Center(child: _UzPlate(plate: vehicle.plate)),
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
                Icon(CupertinoIcons.settings,
                    size: 18, color: AppColors.text3(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AsosiyChip extends StatelessWidget {
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
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _PlaceholderArea(),
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

// ── UZ Plate widget ─────────────────────────────────────────────────────────

class _UzPlate extends StatelessWidget {
  final String plate;
  const _UzPlate({required this.plate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x26000000)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              plate.toUpperCase(),
              style: AppTypography.mono.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111111),
                letterSpacing: 2.5,
              ),
            ),
          ),
          // UZ flag strip
          SizedBox(
            width: 34,
            child: Column(
              children: const [
                Expanded(child: ColoredBox(color: Color(0xFF1EB8E7))),
                SizedBox(height: 1.5, child: ColoredBox(color: Colors.white)),
                Expanded(child: ColoredBox(color: Colors.white)),
                SizedBox(height: 1.5, child: ColoredBox(color: Colors.white)),
                Expanded(child: ColoredBox(color: Color(0xFF2BB55F))),
              ],
            ),
          ),
          // "UZ" label overlay
          SizedBox(
            width: 0,
            child: OverflowBox(
              maxWidth: 34,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-34, 0),
                child: SizedBox(
                  width: 34,
                  child: Center(
                    child: Text(
                      'UZ',
                      style: AppTypography.eyebrow.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 1),
                              blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          icon: CupertinoIcons.bell,
          title: 'owner.feature.avto_signal'.tr(),
          subtitle: 'owner.feature.avto_signal_sub'.tr(),
        ),
        _FeatureTile(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.danger,
          title: 'owner.feature.jarimalar'.tr(),
          subtitle: 'owner.feature.jarimalar_sub'.tr(),
          subtitleColor: AppColors.danger,
        ),
        _FeatureTile(
          icon: CupertinoIcons.scope,
          title: 'owner.feature.shinomontaj'.tr(),
          subtitle: 'owner.feature.shinomontaj_sub'.tr(),
          onTap: () {},
        ),
        _FeatureTile(
          icon: CupertinoIcons.snow,
          title: 'owner.feature.mavsumiy'.tr(),
          subtitle: 'owner.feature.mavsumiy_sub'.tr(),
          showProgress: true,
          progressValue: 0.75,
        ),
        _FeatureTile(
          icon: Icons.sos_rounded,
          iconColor: AppColors.danger,
          title: 'owner.feature.sos'.tr(),
          subtitle: 'owner.feature.sos_sub'.tr(),
          accentLeft: true,
        ),
        _FeatureTile(
          icon: CupertinoIcons.clock,
          title: 'owner.feature.tashriflar'.tr(),
          subtitle: 'owner.feature.tashriflar_sub'.tr(),
        ),
      ];
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final bool showProgress;
  final double progressValue;
  final bool accentLeft;
  final VoidCallback? onTap;

  const _FeatureTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.showProgress = false,
    this.progressValue = 0.0,
    this.accentLeft = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Red left accent for SOS
            if (accentLeft)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: AppColors.danger,
                ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.fromLTRB(
                accentLeft ? AppSpacing.lg : AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                showProgress ? 24 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.eyebrow.copyWith(
                      color: subtitleColor ?? AppColors.text3(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Progress bar at bottom (Mavsumiy)
            if (showProgress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 3,
                  backgroundColor: AppColors.surface2(context),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
          ],
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
