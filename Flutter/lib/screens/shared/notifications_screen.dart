import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

final _notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return NotificationService().list();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_notificationsProvider);
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              border: null,
              largeTitle: Text('notifications.title'.tr()),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(_notificationsProvider);
                await ref.read(_notificationsProvider.future);
              },
            ),
            state.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: CupertinoIcons.bell,
                      title: 'notifications.empty'.tr(),
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
                      (ctx, i) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _NotificationCard(item: items[i]),
                      ),
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

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.read
                  ? CupertinoColors.systemGrey4
                  : AppColors.primaryOf(context),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.headline),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.labelSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatDateTime(item.createdAt),
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
