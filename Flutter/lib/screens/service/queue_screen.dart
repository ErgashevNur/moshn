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

final _queueProvider = FutureProvider.autoDispose<List<Booking>>(
  (_) async {
    final all = await BookingService().getShopBookings(status: 'confirmed');
    final inProg = await BookingService().getShopBookings(status: 'in_progress');
    final pending = await BookingService().getShopBookings(status: 'pending');
    return [...pending, ...all, ...inProg]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  },
);

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_queueProvider);

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
              child: Row(
                children: [
                  Expanded(
                    child: Text('Очередь', style: AppTypography.displayLarge),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(_queueProvider),
                    icon: Icon(Icons.refresh_rounded,
                        color: AppColors.text2(context)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                data: (list) => list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list_alt_rounded,
                                size: 48, color: AppColors.text3(context)),
                            const SizedBox(height: AppSpacing.md),
                            Text('Очередь пуста',
                                style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.text2(context))),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(_queueProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (ctx, i) => _QueueCard(
                            index: i + 1,
                            booking: list[i],
                            onTap: () =>
                                ctx.push('/service/bookings/${list[i].id}'),
                          ),
                        ),
                      ),
                loading: () => const Center(
                    child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_queueProvider),
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

class _QueueCard extends StatelessWidget {
  final int index;
  final Booking booking;
  final VoidCallback onTap;

  const _QueueCard(
      {required this.index, required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface2(context),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: AppTypography.soraSize(13, weight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customer?.name ?? '—',
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  booking.serviceType?.nameUz ?? '—',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
          if (booking.vehicle?.plate != null &&
              booking.vehicle!.plate.isNotEmpty)
            MPlate(plate: booking.vehicle!.plate),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _fmt(booking.scheduledAt),
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.text3(context)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
