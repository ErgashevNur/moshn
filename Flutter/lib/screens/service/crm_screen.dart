import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/section_card.dart';

final _customersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ShopService().getCustomers();
});

class CrmScreen extends ConsumerWidget {
  const CrmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(_customersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Text(
                'service.customers'.tr(),
                style: AppTypography.displayLarge,
              ),
            ),
            Expanded(
              child: customersAsync.when(
                data: (customers) => customers.isEmpty
                    ? const _Empty()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(_customersProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                          itemCount: customers.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (ctx, i) {
                            final c = customers[i] as Map<String, dynamic>;
                            return _CustomerCard(
                              data: c,
                              onTap: () => ctx.push(
                                  '/service/customers/${c['id']}'),
                            );
                          },
                        ),
                      ),
                loading: () => const Center(
                    child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_customersProvider),
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

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _CustomerCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVip = (data['is_vip'] ?? false) as bool;
    final name = (data['customer_name'] ?? '—') as String;
    final phone = (data['customer_phone'] ?? '') as String;
    final visits = (data['visit_count'] ?? 0) as int;

    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isVip
                  ? CupertinoColors.systemYellow.withValues(alpha: 0.2)
                  : AppColors.inverseBg(context).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isVip ? '⭐' : _initials(name),
                style: AppTypography.titleSmall.copyWith(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isVip) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemYellow
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Text(
                          'VIP',
                          style: AppTypography.labelMedium.copyWith(
                            color: CupertinoColors.systemYellow,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (phone.isNotEmpty)
                  Text(phone,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.text3(context))),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$visits', style: AppTypography.titleSmall),
              Text(
                'crm.visits'.tr(),
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.text3(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👥', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          Text('service.no_customers'.tr(), style: AppTypography.titleSmall),
        ],
      ),
    );
  }
}
