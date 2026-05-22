import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/mechanic.dart';
import '../../services/mechanic_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

final _queryProvider = StateProvider<String>((_) => '');

final _mechanicsProvider =
    FutureProvider.autoDispose<List<Mechanic>>((ref) {
  final q = ref.watch(_queryProvider);
  return MechanicService().search(q: q.isEmpty ? null : q);
});

class FindMechanicScreen extends ConsumerWidget {
  const FindMechanicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_mechanicsProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      placeholder: 'common.search'.tr(),
                      icon: CupertinoIcons.search,
                      onChanged: (v) =>
                          ref.read(_queryProvider.notifier).state = v,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.when(
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: CupertinoIcons.search,
                      title: 'common.search'.tr(),
                      subtitle: 'mechanic.specialization'.tr(),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemBuilder: (ctx, i) =>
                        _MechanicCard(mechanic: items[i]),
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
          ],
        ),
      ),
    );
  }
}

class _MechanicCard extends StatelessWidget {
  final Mechanic mechanic;
  const _MechanicCard({required this.mechanic});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: () => GoRouter.of(context).push('/owner/mechanics/${mechanic.id}'),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: AppColors.primaryOf(context),
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mechanic.name,
                        style: AppTypography.headline,
                      ),
                    ),
                    if (mechanic.verified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: AppColors.primaryOf(context),
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mechanic.specialization.isEmpty
                      ? 'mechanic.specialization'.tr()
                      : mechanic.specialization.join(', '),
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(CupertinoIcons.star_fill,
                        size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      mechanic.rating.toStringAsFixed(1),
                      style: AppTypography.caption1,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${mechanic.completedJobs} ${'mechanic.completed_jobs'.tr()}',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.labelTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
