import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_plate.dart';
import '../../widgets/section_card.dart';

final _completedTodayProvider = FutureProvider.autoDispose<List<Booking>>(
  (_) async {
    final list = await BookingService().getShopBookings(status: 'completed');
    final now = DateTime.now();
    return list
        .where((b) =>
            b.scheduledAt.year == now.year &&
            b.scheduledAt.month == now.month &&
            b.scheduledAt.day == now.day)
        .toList();
  },
);

class TerminalScreen extends ConsumerWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_completedTodayProvider);

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
              child: Text('Терминал', style: AppTypography.displayLarge),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Оплаты за сегодня',
                style: AppTypography.labelSmall.copyWith(
                    color: AppColors.text3(context), letterSpacing: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: async.when(
                data: (list) {
                  final total = list.fold<int>(0, (s, b) => s + b.totalPrice);
                  return Column(
                    children: [
                      if (total > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.successDim,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.r_md),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded,
                                    color: AppColors.success, size: 28),
                                const SizedBox(width: AppSpacing.md),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Общая выручка',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                color: AppColors.success)),
                                    Text(
                                      _fmtMoney(total),
                                      style: AppTypography.displaySmall
                                          .copyWith(color: AppColors.success),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: list.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.credit_card_rounded,
                                        size: 48,
                                        color: AppColors.text3(context)),
                                    const SizedBox(height: AppSpacing.md),
                                    Text('Сегодня нет оплат',
                                        style: AppTypography.titleSmall.copyWith(
                                            color: AppColors.text2(context))),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                itemCount: list.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (ctx, i) {
                                  final b = list[i];
                                  return SectionCard(
                                    onTap: () =>
                                        ctx.push('/service/bookings/${b.id}'),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.customer?.name ?? '—',
                                                style:
                                                    AppTypography.titleSmall,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                b.serviceType?.name ?? '—',
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                        color: AppColors
                                                            .text3(context)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (b.vehicle?.plate != null &&
                                            b.vehicle!.plate.isNotEmpty) ...[
                                          MPlate(plate: b.vehicle!.plate),
                                          const SizedBox(width: AppSpacing.sm),
                                        ],
                                        Text(
                                          _fmtMoney(b.totalPrice),
                                          style:
                                              AppTypography.labelMedium.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_completedTodayProvider),
                    child: const Text('Повторить'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtMoney(int amount) {
    if (amount == 0) return '0 сум';
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} сум';
  }
}
