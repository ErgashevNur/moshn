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

final _myServicesProvider =
    FutureProvider.autoDispose<List<ServiceRecord>>((ref) {
  return ServiceRecordService().myServices();
});

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_myServicesProvider);
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              border: null,
              largeTitle: Text('mechanic.clients'.tr()),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(_myServicesProvider);
                await ref.read(_myServicesProvider.future);
              },
            ),
            state.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: CupertinoIcons.person_2,
                      title: 'mechanic.no_services'.tr(),
                      subtitle: 'mechanic.no_services_subtitle'.tr(),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) => _ServiceCard(record: items[i]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
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

class _ServiceCard extends StatelessWidget {
  final ServiceRecord record;
  const _ServiceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: () => context.push('/services/${record.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.description.isEmpty
                      ? 'mechanic.service_description'.tr()
                      : record.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(status: record.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                formatDateTime(record.createdAt),
                style: AppTypography.caption1.copyWith(
                  color: AppColors.labelTertiary,
                ),
              ),
              const Spacer(),
              Text(
                formatCurrency(record.totalCost),
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
  }
}
