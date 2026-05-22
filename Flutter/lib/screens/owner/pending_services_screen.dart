import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_record.dart';
import '../../services/service_record_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';

final _pendingProvider =
    FutureProvider.autoDispose<List<ServiceRecord>>((ref) {
  return ServiceRecordService().pendingForOwner();
});

class PendingServicesScreen extends ConsumerWidget {
  const PendingServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_pendingProvider);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('owner.pending_services'.tr()),
      ),
      child: SafeArea(
        child: state.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: CupertinoIcons.checkmark_seal,
                title: 'notifications.empty'.tr(),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemBuilder: (ctx, i) {
                final s = items[i];
                return SectionCard(
                  onTap: () => context.push('/owner/services/${s.id}'),
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
                          Text(
                            formatDateTime(s.createdAt),
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
                );
              },
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemCount: items.length,
            );
          },
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
}
