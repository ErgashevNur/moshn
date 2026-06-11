import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

final _serviceBookingProvider =
    FutureProvider.autoDispose.family<Booking, String>(
  (ref, id) => BookingService().getBooking(id),
);

class ServiceBookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const ServiceBookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(_serviceBookingProvider(bookingId));

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
                    child: Text('booking.title'.tr(),
                        style: AppTypography.titleLarge),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: bookingAsync.when(
              data: (booking) => _Body(
                booking: booking,
                onRefresh: () => ref.invalidate(_serviceBookingProvider),
              ),
              loading: () => const Center(
                  child: CircularProgressIndicator.adaptive()),
              error: (e, _) => Center(
                child: Text('${'common.error'.tr()}: $e',
                    style:
                        AppTypography.body.copyWith(color: AppColors.danger)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const _Body({required this.booking, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CustomerCard(booking: booking),
          const SizedBox(height: AppSpacing.md),
          _DetailsCard(booking: booking),
          const SizedBox(height: AppSpacing.xl),
          _ActionButtons(booking: booking, onRefresh: onRefresh),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Booking booking;
  const _CustomerCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: AppColors.inverseBg(context).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.person_fill, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.customer?.name ?? '—',
                    style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(
                  booking.customer?.phone ?? '—',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: _statusColor(booking.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              _statusText(booking.status),
              style: AppTypography.labelMedium.copyWith(
                color: _statusColor(booking.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(String s) {
    const map = {
      'pending': 'booking.status_pending',
      'confirmed': 'booking.status_confirmed',
      'in_progress': 'booking.status_in_progress',
      'completed': 'booking.status_completed',
      'cancelled': 'booking.status_cancelled_short',
    };
    return (map[s] ?? s).tr();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':    return AppColors.gold;
      case 'confirmed':  return AppColors.success;
      case 'in_progress': return const Color(0xFF0A84FF);
      case 'completed':  return AppColors.success;
      case 'cancelled':  return AppColors.danger;
    }
    return const Color(0xFF8E8E93);
  }
}

class _DetailsCard extends StatelessWidget {
  final Booking booking;
  const _DetailsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          _Row(
              label: 'booking.service_type'.tr(),
              value: booking.serviceType?.nameFor(context.locale.languageCode) ?? '—'),
          _sep(context),
          _Row(
              label: 'booking.vehicle'.tr(),
              value: booking.vehicle?.displayName ?? '—'),
          _sep(context),
          _Row(
            label: 'booking.scheduled_at'.tr(),
            value: _fmt(booking.scheduledAt),
          ),
          if (booking.totalPrice > 0) ...[
            _sep(context),
            _Row(
              label: 'booking.price'.tr(),
              value: '${_price(booking.totalPrice)} ${'common.sum'.tr()}',
            ),
          ],
          if (booking.notes.isNotEmpty) ...[
            _sep(context),
            _Row(label: 'booking.notes'.tr(), value: booking.notes),
          ],
        ],
      ),
    );
  }

  Widget _sep(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Container(height: 0.5, color: AppColors.hairline(context)),
      );

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _price(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.text3(context))),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(value, style: AppTypography.body)),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const _ActionButtons({required this.booking, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = BookingService();

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        if (!context.mounted) return;
        onRefresh();
        context.pop();
      } catch (e) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface(ctx),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            title: Text('common.error'.tr()),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('common.ok'.tr()),
              ),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (booking.isPending)
          PrimaryButton(
            label: 'service.confirm'.tr(),
            onPressed: () => run(() => svc.confirmBooking(booking.id)),
          ),
        if (booking.isConfirmed)
          PrimaryButton(
            label: 'service.start'.tr(),
            onPressed: () => run(() => svc.startBooking(booking.id)),
          ),
        if (booking.isInProgress)
          PrimaryButton(
            label: 'service.complete'.tr(),
            onPressed: () => run(() => svc.completeBooking(booking.id)),
          ),
        if (booking.isPending || booking.isConfirmed) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => run(() => svc.shopCancelBooking(booking.id)),
            child: Text(
              'service.cancel'.tr(),
              style: AppTypography.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ],
    );
  }
}
