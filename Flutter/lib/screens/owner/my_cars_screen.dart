import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

final _vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  return VehicleService().list();
});

class MyCarsScreen extends ConsumerWidget {
  const MyCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(_vehiclesProvider);
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              border: null,
              largeTitle: Text('owner.my_cars'.tr()),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.push('/owner/vehicles/new'),
                child: const Icon(CupertinoIcons.add, size: 24),
              ),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(_vehiclesProvider);
                await ref.read(_vehiclesProvider.future);
              },
            ),
            vehicles.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: CupertinoIcons.car,
                      title: 'owner.no_cars'.tr(),
                      subtitle: 'owner.no_cars_subtitle'.tr(),
                      action: PrimaryButton(
                        label: 'owner.add_car'.tr(),
                        icon: CupertinoIcons.add,
                        onPressed: () => context.push('/owner/vehicles/new'),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final v = items[i];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: SectionCard(
                            onTap: () =>
                                context.push('/owner/vehicles/${v.id}'),
                            child: _VehicleRow(vehicle: v),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (_, _) => SliverFillRemaining(
                child: EmptyState(
                  icon: CupertinoIcons.exclamationmark_triangle,
                  title: 'common.error'.tr(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleRow({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryOf(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            CupertinoIcons.car_detailed,
            color: AppColors.primaryOf(context),
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicle.fullName, style: AppTypography.headline),
              const SizedBox(height: 2),
              Text(
                '${vehicle.plate} • ${vehicle.year}',
                style: AppTypography.subhead.copyWith(
                  color: AppColors.labelTertiary,
                ),
              ),
            ],
          ),
        ),
        const Icon(CupertinoIcons.chevron_right,
            color: AppColors.labelTertiary, size: 18),
      ],
    );
  }
}
