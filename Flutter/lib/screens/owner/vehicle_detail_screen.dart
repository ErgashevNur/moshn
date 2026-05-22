import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_record.dart';
import '../../models/vehicle.dart';
import '../../services/service_record_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';

final _vehicleProvider =
    FutureProvider.autoDispose.family<Vehicle, String>((ref, id) {
  return VehicleService().get(id);
});

final _historyProvider = FutureProvider.autoDispose
    .family<List<ServiceRecord>, String>((ref, id) {
  return ServiceRecordService().listForVehicle(id);
});

class VehicleDetailScreen extends ConsumerWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(_vehicleProvider(vehicleId));
    final history = ref.watch(_historyProvider(vehicleId));

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('owner.vehicle_detail'.tr()),
      ),
      child: SafeArea(
        bottom: false,
        child: vehicle.when(
          data: (v) => CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(_vehicleProvider(vehicleId));
                  ref.invalidate(_historyProvider(vehicleId));
                  await ref.read(_historyProvider(vehicleId).future);
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _VehicleHeader(vehicle: v),
                    const SizedBox(height: AppSpacing.xl),
                    SectionCard(
                      child: Column(
                        children: [
                          _kv('owner.vin'.tr(), v.vin),
                          _divider(),
                          _kv('owner.plate'.tr(), v.plate),
                          _divider(),
                          _kv('owner.year'.tr(), v.year.toString()),
                          if (v.color != null && v.color!.isNotEmpty) ...[
                            _divider(),
                            _kv('owner.color'.tr(), v.color!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('owner.recent_services'.tr(),
                        style: AppTypography.title3),
                    const SizedBox(height: AppSpacing.md),
                    _HistorySection(state: history),
                    const SizedBox(height: AppSpacing.huge),
                  ]),
                ),
              ),
            ],
          ),
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => EmptyState(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: 'common.error'.tr(),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: AppTypography.subhead.copyWith(
                  color: AppColors.labelTertiary,
                ),
              ),
            ),
            Text(v, style: AppTypography.body),
          ],
        ),
      );

  Widget _divider() => Container(
        height: 0.5,
        color: AppColors.separator,
      );
}

class _VehicleHeader extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleHeader({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryOf(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(
            CupertinoIcons.car_detailed,
            color: AppColors.primaryOf(context),
            size: 36,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicle.fullName, style: AppTypography.title2),
              const SizedBox(height: 2),
              Text(
                vehicle.plate,
                style: AppTypography.body.copyWith(
                  color: AppColors.labelTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  final AsyncValue<List<ServiceRecord>> state;
  const _HistorySection({required this.state});

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (items) {
        if (items.isEmpty) {
          return SectionCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'notifications.empty'.tr(),
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
              ),
            ),
          );
        }
        return Column(
          children: items
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SectionCard(
                    onTap: () => GoRouter.of(context)
                        .push('/owner/services/${s.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.mechanicName,
                                  style: AppTypography.headline),
                            ),
                            StatusChip(status: s.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          s.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.subhead.copyWith(
                            color: AppColors.labelSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(CupertinoIcons.calendar,
                                size: 14, color: AppColors.labelTertiary),
                            const SizedBox(width: 4),
                            Text(
                              formatDate(s.createdAt),
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.labelTertiary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatCurrency(s.totalCost),
                              style: AppTypography.subhead.copyWith(
                                color: AppColors.primaryOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
