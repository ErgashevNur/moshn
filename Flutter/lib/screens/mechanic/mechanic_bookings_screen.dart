import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_plate.dart';

final _masterBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) {
  return BookingService().getMasterBookings();
});

class MechanicBookingsScreen extends ConsumerWidget {
  const MechanicBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_masterBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Мои записи',
                style: AppTypography.appbarTitle.copyWith(
                  color: AppColors.text(context),
                ),
              ),
            ),
            Expanded(
              child: async.when(
                data: (bookings) => RefreshIndicator(
                  onRefresh: () async => ref.refresh(_masterBookingsProvider.future),
                  child: bookings.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Записей пока нет',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.text3(context),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.lg,
                            AppSpacing.xl,
                          ),
                          itemCount: bookings.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) =>
                              _BookingCard(booking: bookings[i]),
                        ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text(
                    'Ошибка загрузки',
                    style: AppTypography.body.copyWith(
                      color: AppColors.text3(context),
                    ),
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

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final title = b.serviceType?.nameFor('ru') ?? 'Услуга';
    final customer = b.customer?.name ?? 'Клиент';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusChip(status: b.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.person_rounded,
                  size: 14, color: AppColors.text3(context)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer,
                  style: AppTypography.body.copyWith(
                    color: AppColors.text2(context),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (b.vehicle != null) ...[
                const SizedBox(width: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MPlate(plate: b.vehicle!.plate),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 14, color: AppColors.text3(context)),
              const SizedBox(width: 4),
              Text(
                _fmtDateTime(b.scheduledAt),
                style: AppTypography.mono.copyWith(
                  color: AppColors.text3(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (status) {
      case 'pending':
        label = 'Ожидает';
        color = AppColors.gold;
      case 'confirmed':
        label = 'Подтверждено';
        color = AppColors.gold;
      case 'in_progress':
        label = 'В работе';
        color = AppColors.gold;
      case 'completed':
        label = 'Завершено';
        color = AppColors.success;
      case 'cancelled':
        label = 'Отменено';
        color = AppColors.danger;
      default:
        label = status;
        color = AppColors.text3(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.r_full),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}
