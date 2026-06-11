import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/section_card.dart';

final _vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  return VehicleService().getVehicles();
});

class MyVehiclesScreen extends ConsumerWidget {
  const MyVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(_vehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.xs, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'tabs.vehicles'.tr(),
                      style: AppTypography.displayLarge,
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
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: vehiclesAsync.when(
                data: (vehicles) => vehicles.isEmpty
                    ? _Empty()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(_vehiclesProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                          itemCount: vehicles.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (ctx, i) =>
                              _VehicleCard(vehicle: vehicles[i]),
                        ),
                      ),
                loading: () => const Center(
                    child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_vehiclesProvider),
                    child: Text('common.retry'.tr()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: AppColors.inverseBg(context).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(CupertinoIcons.car_detailed, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: AppTypography.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  vehicle.plate,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.inverseBg(context),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (vehicle.year > 0)
            Text(
              vehicle.year.toString(),
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.text3(context)),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚗', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          Text('owner.no_vehicles'.tr(), style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => context.push('/owner/vehicles/new'),
            child: Text('owner.add_vehicle'.tr()),
          ),
        ],
      ),
    );
  }
}
