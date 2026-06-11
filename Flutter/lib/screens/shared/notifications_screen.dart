import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.text(context), size: 17),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('notifications.title'.tr(),
                        style: AppTypography.titleLarge),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: state.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: CupertinoIcons.bell,
                    title: 'notifications.empty'.tr(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(_notificationsProvider);
                    await ref.read(_notificationsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) =>
                        _NotificationCard(item: items[i]),
                  ),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator.adaptive()),
              error: (_, _) => EmptyState(
                icon: CupertinoIcons.exclamationmark_triangle,
                title: 'common.error'.tr(),
              ),
            ),
          ),
        ],
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
            width: 8, height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.read
                  ? const Color(0xFFC7C7CC)
                  : AppColors.inverseBg(context),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.text2(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatDateTime(item.createdAt),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.text3(context),
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
