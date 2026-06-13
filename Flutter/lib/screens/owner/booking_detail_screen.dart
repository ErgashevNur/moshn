import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

final _bookingDetailProvider =
    FutureProvider.autoDispose.family<Booking, String>(
  (ref, id) => BookingService().getBooking(id),
);

final _bookingPaymentProvider =
    FutureProvider.autoDispose.family<Payment?, String>(
  (ref, bookingId) => BookingService().getPayment(bookingId),
);

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(_bookingDetailProvider(bookingId));

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
                onRefresh: () => ref.invalidate(_bookingDetailProvider),
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
    final paymentAsync = ref.watch(_bookingPaymentProvider(booking.id));
    final isPaid = paymentAsync.valueOrNull?.isPaid == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(booking: booking),
          const SizedBox(height: AppSpacing.md),
          _InfoCard(booking: booking),
          const SizedBox(height: AppSpacing.xl),
          if (booking.isCompleted && !isPaid) ...[
            PrimaryButton(
              label: 'booking.pay_now'.tr(),
              onPressed: () => context.push(
                  '/owner/bookings/${booking.id}/pay?amount=${booking.totalPrice}'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => _showTipDialog(context, ref),
              child: Text('booking.add_tip'.tr()),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (booking.isCompleted && isPaid) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              alignment: Alignment.center,
              child: Text(
                'booking.paid'.tr(),
                style: AppTypography.labelMedium.copyWith(color: AppColors.success),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (booking.canCancel)
            TextButton(
              onPressed: () => _confirmCancel(context, ref),
              child: Text(
                'booking.cancel'.tr(),
                style: AppTypography.body.copyWith(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Text('booking.cancel'.tr()),
        content: Text('booking.cancel_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.no'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.yes'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await BookingService().cancelBooking(booking.id);
        if (!context.mounted) return;
        onRefresh();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('booking.cancel_error'.tr()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showTipDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Text('booking.add_tip'.tr()),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: '10 000',
              hintStyle:
                  AppTypography.body.copyWith(color: AppColors.text3(ctx)),
              filled: true,
              fillColor: AppColors.surface2(ctx),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(ctrl.text.replaceAll(' ', ''));
              if (amount != null && amount > 0) {
                await BookingService().addTip(booking.id, amount);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('common.send'.tr()),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Booking booking;
  const _StatusCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: _statusColor(booking.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              _statusText(booking.status),
              style: AppTypography.titleSmall.copyWith(
                color: _statusColor(booking.status),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            booking.shop?.shopName ?? '—',
            style: AppTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            booking.serviceType?.nameFor(context.locale.languageCode) ?? '—',
            style:
                AppTypography.body.copyWith(color: AppColors.text3(context)),
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
      'cancelled': 'booking.status_cancelled',
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

class _InfoCard extends StatelessWidget {
  final Booking booking;
  const _InfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
              label: 'booking.vehicle'.tr(),
              value: booking.vehicle?.displayName ?? '—'),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 0.5, color: AppColors.hairline(context)),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            label: 'booking.scheduled_at'.tr(),
            value: _formatDate(booking.scheduledAt),
          ),
          if (booking.totalPrice > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(height: 0.5, color: AppColors.hairline(context)),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              label: 'booking.price'.tr(),
              value: '${_formatPrice(booking.totalPrice)} ${'common.sum'.tr()}',
            ),
          ],
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(height: 0.5, color: AppColors.hairline(context)),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(label: 'booking.notes'.tr(), value: booking.notes),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

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
