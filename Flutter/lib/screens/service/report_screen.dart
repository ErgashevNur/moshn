import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/section_card.dart';

final _reportProvider = FutureProvider.autoDispose<_ReportData>(
  (_) async {
    final all = await BookingService().getShopBookings();
    return _ReportData.fromBookings(all);
  },
);

class _ReportData {
  final int todayTotal;
  final int todayCompleted;
  final int todayRevenue;
  final int weekTotal;
  final int weekCompleted;
  final int weekRevenue;
  final int monthTotal;
  final int monthCompleted;
  final int monthRevenue;

  _ReportData({
    required this.todayTotal,
    required this.todayCompleted,
    required this.todayRevenue,
    required this.weekTotal,
    required this.weekCompleted,
    required this.weekRevenue,
    required this.monthTotal,
    required this.monthCompleted,
    required this.monthRevenue,
  });

  factory _ReportData.fromBookings(List<Booking> all) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    List<Booking> filter(DateTime from) => all
        .where((b) => b.scheduledAt.isAfter(from) || b.scheduledAt == from)
        .toList();

    int rev(List<Booking> list) => list
        .where((b) => b.status == 'completed')
        .fold(0, (s, b) => s + b.totalPrice);

    int comp(List<Booking> list) =>
        list.where((b) => b.status == 'completed').length;

    final today = filter(todayStart);
    final week = filter(weekStart);
    final month = filter(monthStart);

    return _ReportData(
      todayTotal: today.length,
      todayCompleted: comp(today),
      todayRevenue: rev(today),
      weekTotal: week.length,
      weekCompleted: comp(week),
      weekRevenue: rev(week),
      monthTotal: month.length,
      monthCompleted: comp(month),
      monthRevenue: rev(month),
    );
  }
}

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_reportProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                      child:
                          Text('Отчёт', style: AppTypography.displayLarge)),
                  IconButton(
                    onPressed: () => ref.invalidate(_reportProvider),
                    icon: Icon(Icons.refresh_rounded,
                        color: AppColors.text2(context)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                data: (data) => ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  children: [
                    _PeriodSection(
                      title: 'СЕГОДНЯ',
                      total: data.todayTotal,
                      completed: data.todayCompleted,
                      revenue: data.todayRevenue,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PeriodSection(
                      title: 'ЭТА НЕДЕЛЯ',
                      total: data.weekTotal,
                      completed: data.weekCompleted,
                      revenue: data.weekRevenue,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PeriodSection(
                      title: 'ЭТОТ МЕСЯЦ',
                      total: data.monthTotal,
                      completed: data.monthCompleted,
                      revenue: data.monthRevenue,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_reportProvider),
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
}

class _PeriodSection extends StatelessWidget {
  final String title;
  final int total;
  final int completed;
  final int revenue;

  const _PeriodSection({
    required this.title,
    required this.total,
    required this.completed,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.soraSize(10, weight: FontWeight.w600).copyWith(
              color: AppColors.text3(context), letterSpacing: 1.0),
        ),
        const SizedBox(height: AppSpacing.sm),
        SectionCard(
          child: Column(
            children: [
              _Row(label: 'Всего записей', value: total.toString()),
              _Divider(),
              _Row(
                  label: 'Выполнено',
                  value: '$completed/$total',
                  valueColor: AppColors.success),
              _Divider(),
              _Row(
                  label: 'Выручка',
                  value: _fmt(revenue),
                  valueColor: AppColors.gold),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n == 0) return '0 сум';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} сум';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.text2(context))),
          ),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: valueColor ?? AppColors.text(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: AppColors.hairline(context),
      );
}
