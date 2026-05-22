import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/assignment.dart';
import '../../services/repair_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

final _assignmentsProvider =
    FutureProvider.autoDispose<List<Assignment>>((ref) {
  return RepairService().myAssignments();
});

class MechanicHomeScreen extends ConsumerWidget {
  const MechanicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              border: null,
              largeTitle: Text(
                '${'owner.home_title'.tr()}, ${user?.name ?? ""}',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOf(context)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                              ),
                              child: Icon(
                                CupertinoIcons.wrench_fill,
                                color: AppColors.primaryOf(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('mechanic.add_service'.tr(),
                                      style: AppTypography.headline),
                                  const SizedBox(height: 2),
                                  Text(
                                    'mechanic.voice_record'.tr(),
                                    style: AppTypography.footnote.copyWith(
                                      color: AppColors.labelTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          label: 'mechanic.add_service'.tr(),
                          icon: CupertinoIcons.add,
                          onPressed: () {
                            CupertinoTabController? c;
                            context.visitAncestorElements((el) {
                              final w = el.widget;
                              if (w is CupertinoTabScaffold) {
                                c = w.controller;
                                return false;
                              }
                              return true;
                            });
                            c?.index = 1;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _AssignmentsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    onTap: () => context.push('/profile'),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.person_circle,
                            color: AppColors.primaryOf(context), size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text('profile.settings'.tr(),
                              style: AppTypography.body),
                        ),
                        const Icon(CupertinoIcons.chevron_right,
                            color: AppColors.labelTertiary, size: 18),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ustaga operator tomonidan yo'naltirilgan SOS va tamirlash so'rovlari —
/// mijoz ma'lumotlari bilan.
class _AssignmentsSection extends ConsumerWidget {
  const _AssignmentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_assignmentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Icon(CupertinoIcons.bell_fill,
                  size: 18, color: AppColors.primaryOf(context)),
              const SizedBox(width: AppSpacing.sm),
              Text('Yo\'naltirilgan so\'rovlar', style: AppTypography.headline),
              const SizedBox(width: AppSpacing.sm),
              state.maybeWhen(
                data: (items) => Text('(${items.length})',
                    style: AppTypography.subhead
                        .copyWith(color: AppColors.labelTertiary)),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        state.when(
          data: (items) {
            if (items.isEmpty) {
              return SectionCard(
                child: Text(
                  'Hozircha sizga yo\'naltirilgan so\'rov yo\'q',
                  style: AppTypography.subhead
                      .copyWith(color: AppColors.labelTertiary),
                ),
              );
            }
            return Column(
              children: [
                for (final a in items) ...[
                  _AssignmentCard(item: a),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (_, _) => SectionCard(
            child: Text('common.error'.tr(),
                style: AppTypography.subhead
                    .copyWith(color: AppColors.labelTertiary)),
          ),
        ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment item;
  const _AssignmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isSos = item.kind == AssignmentKind.sos;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSos
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : CupertinoIcons.wrench_fill,
                size: 16,
                color: isSos ? AppColors.destructive : AppColors.primaryOf(context),
              ),
              const SizedBox(width: 6),
              Text(
                isSos ? 'SOS' : 'Tamirlash',
                style: AppTypography.caption1.copyWith(
                  color: isSos ? AppColors.destructive : AppColors.primaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(item.status, style: AppTypography.caption1.copyWith(
                color: AppColors.labelTertiary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.clientName.isEmpty ? 'Mijoz' : item.clientName,
              style: AppTypography.headline),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(CupertinoIcons.phone_fill,
                  size: 13, color: AppColors.primaryOf(context)),
              const SizedBox(width: 4),
              Text(item.phone,
                  style: AppTypography.subhead
                      .copyWith(color: AppColors.primaryOf(context))),
            ],
          ),
          if (isSos && item.address != null && item.address!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.location_solid,
                    size: 13, color: AppColors.labelTertiary),
                const SizedBox(width: 4),
                Expanded(child: Text(item.address!, style: AppTypography.footnote)),
              ],
            ),
          ],
          if (isSos && item.latitude != null && item.longitude != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Koordinata: ${item.latitude!.toStringAsFixed(5)}, ${item.longitude!.toStringAsFixed(5)}',
              style: AppTypography.caption1
                  .copyWith(color: AppColors.labelTertiary),
            ),
          ],
          if (!isSos) ...[
            if (item.carInfo != null && item.carInfo!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Mashina: ${item.carInfo}', style: AppTypography.footnote),
            ],
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(item.description!, style: AppTypography.subhead),
            ],
          ],
        ],
      ),
    );
  }
}
