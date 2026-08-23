import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../models/review.dart';
import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import '../../services/ws_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/m_stars.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/booking_shared.dart';
import '../../widgets/section_card.dart';
import 'owner_root.dart';

final _bookingDetailProvider = FutureProvider.autoDispose
    .family<Booking, String>((ref, id) => BookingService().getBooking(id));

final _bookingPaymentProvider = FutureProvider.autoDispose
    .family<Payment?, String>(
      (ref, bookingId) => BookingService().getPayment(bookingId),
    );

final _bookingReviewProvider = FutureProvider.autoDispose
    .family<Review?, String>(
      (ref, bookingId) => ReviewService().getByBooking(bookingId),
    );

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    // Usta bosqichni belgilasa, rasm yuklasa yoki qo'shimcha ish taklif
    // qilsa — ekran darhol yangilansin (mijoz "ish qayerga yetdi" deb
    // qayta-qayta ochib ko'rmasin).
    const live = {'booking_stage', 'booking_photo', 'booking_extra'};
    _wsSub = WsService.instance.events.listen((e) {
      if (!live.contains(e.type)) return;
      if (e.data['id'] != widget.bookingId) return;
      ref.invalidate(_bookingDetailProvider(widget.bookingId));
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.bookingId;
    final bookingAsync = ref.watch(_bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      // Maketda bron tafsilotlarida ham pastki navigatsiya turadi. Bu ekran
      // shell ichida emas (router oddiy GoRoute daraxti), shuning uchun
      // bar shu yerda chiziladi va bosilganda `/owner` ning kerakli
      // tabiga o'tadi. Faol tab — "Записи", bron o'sha bo'limga tegishli.
      bottomNavigationBar: OwnerBottomBar(
        index: 1,
        showSosSlot: false,
        onTap: (i) => context.go('/owner', extra: i),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              // Maketda alohida sarlavha yo'q — karta darhol boshlanadi.
              // Orqaga tugmasi qoladi: bo'lmasa ekrandan chiqib bo'lmaydi.
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.text(context),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: bookingAsync.when(
              data: (booking) => _Body(
                booking: booking,
                onRefresh: () => ref.invalidate(_bookingDetailProvider),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (e, _) => Center(
                child: Text(
                  '${'common.error'.tr()}: $e',
                  style: AppTypography.body.copyWith(color: AppColors.danger),
                ),
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
    final reviewAsync = booking.isCompleted
        ? ref.watch(_bookingReviewProvider(booking.id))
        : null;

    // To'lov paneli maketdagidek pastda YOPISHIB turadi — ish davomida ham
    // ko'rinadi (mijoz tugashini kutmasdan to'lay oladi).
    final showPayBar = !isPaid &&
        booking.totalPrice > 0 &&
        !booking.isCancelled;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bosqichlar bo'lsa — jarayon sarlavhasi eski status kartasi
                // o'rniga (u yerda ham holat, ham progress bor).
                if (booking.stages.isNotEmpty)
                  BookingProgressHeader(booking: booking)
                else
                  _StatusCard(booking: booking),
                const SizedBox(height: AppSpacing.lg),
                if (booking.stages.isNotEmpty) ...[
                  BookingStagesTimeline(
                    booking: booking,
                    // Kelishuv bosqichi ostida "Согласен / Отказаться".
                    below: (_, stage) => stage.isAwaiting
                        ? _StageApproval(booking: booking, stage: stage)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (booking.photos.isNotEmpty) ...[
                  BookingPhotoReport(photos: booking.photos),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (booking.totalPrice > 0) ...[
                  BookingPaymentCard(booking: booking, isPaid: isPaid),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _InfoCard(booking: booking),
                const SizedBox(height: AppSpacing.lg),
                if (booking.isCompleted && reviewAsync != null) ...[
                  _ReviewSection(booking: booking, reviewAsync: reviewAsync),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (booking.isCompleted && isPaid)
                  TextButton(
                    onPressed: () => _showTipDialog(context, ref),
                    child: Text('booking.add_tip'.tr()),
                  ),
                if (booking.canCancel)
                  TextButton(
                    onPressed: () => _confirmCancel(context, ref),
                    child: Text(
                      'booking.cancel'.tr(),
                      style:
                          AppTypography.body.copyWith(color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
        if (showPayBar) _PayBar(booking: booking),
      ],
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
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.text3(ctx),
              ),
              filled: true,
              fillColor: AppColors.surface2(ctx),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
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
              if (ctx.mounted) {
                FocusScope.of(ctx).unfocus();
                Navigator.pop(ctx);
              }
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
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
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
            style: AppTypography.body.copyWith(color: AppColors.text3(context)),
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
      case 'pending':
        return AppColors.gold;
      case 'confirmed':
        return AppColors.success;
      case 'in_progress':
        return const Color(0xFF0A84FF);
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
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
          // Sana sarlavha kartasida, narx "К оплате"da — bu yerda
          // takrorlanmaydi. Qoladigani: mashina, usta va izoh.
          _InfoRow(
            label: 'booking.vehicle'.tr(),
            value: booking.vehicle?.displayName ?? '—',
          ),
          if ((booking.master?.fullName ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(height: 0.5, color: AppColors.hairline(context)),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              label: 'booking.master'.tr(),
              value: booking.master!.fullName,
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
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.text3(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(value, style: AppTypography.body)),
      ],
    );
  }
}

// ── Отзыв ────────────────────────────────────────────────────────────────────

class _ReviewSection extends ConsumerWidget {
  final Booking booking;
  final AsyncValue<Review?> reviewAsync;
  const _ReviewSection({required this.booking, required this.reviewAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return reviewAsync.when(
      data: (review) {
        if (review == null) {
          return PrimaryButton(
            label: 'booking.leave_review'.tr(),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _showLeaveReviewSheet(context, ref, booking);
            },
          );
        }
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('review.title'.tr(), style: AppTypography.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              MStars(value: review.rating.toDouble(), size: 18),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  review.comment,
                  style: AppTypography.body.copyWith(
                    color: AppColors.text2(context),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

Future<void> _showLeaveReviewSheet(
  BuildContext context,
  WidgetRef ref,
  Booking booking,
) async {
  int rating = 0;
  int masterRating = 0;
  final commentCtrl = TextEditingController();
  bool saving = false;
  final hasMaster = booking.masterId != null;
  final masterName = booking.master?.fullName ?? 'Мастер';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline(ctx),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'review.title'.tr(),
                  style: AppTypography.soraSize(
                    18,
                    weight: FontWeight.w700,
                  ).copyWith(color: AppColors.text(ctx)),
                ),
                const SizedBox(height: 6),
                Text(
                  'review.subtitle'.tr(
                    namedArgs: {'shop': booking.shop?.shopName ?? ''},
                  ),
                  style: AppTypography.body.copyWith(
                    color: AppColors.text3(ctx),
                  ),
                ),
                const SizedBox(height: 20),
                if (hasMaster) ...[
                  Center(
                    child: Text(
                      'Сервис',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.text3(ctx)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final filled = i < rating;
                      return GestureDetector(
                        onTap: () => setModalState(() => rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 36,
                            color: filled
                                ? AppColors.gold
                                : AppColors.text3(ctx),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (hasMaster) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Мастер · $masterName',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.text3(ctx)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final filled = i < masterRating;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => masterRating = i + 1),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 32,
                              color: filled
                                  ? AppColors.gold
                                  : AppColors.text3(ctx),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  style: AppTypography.body.copyWith(
                    color: AppColors.text(ctx),
                  ),
                  decoration: InputDecoration(
                    hintText: 'review.comment_hint'.tr(),
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.text3(ctx),
                    ),
                    filled: true,
                    fillColor: AppColors.surface(ctx),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r_md),
                      borderSide: BorderSide(color: AppColors.hairline(ctx)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r_md),
                      borderSide: BorderSide(color: AppColors.hairline(ctx)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r_md),
                      borderSide: BorderSide(
                        color: AppColors.inverseBg(ctx),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.inverseBg(ctx),
                      foregroundColor: AppColors.inverseText(ctx),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r_md),
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            if (rating == 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('review.rating_required'.tr()),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setModalState(() => saving = true);
                            try {
                              await ReviewService().createReview(
                                bookingId: booking.id,
                                targetId: booking.shopId,
                                reviewType: 'owner_to_shop',
                                rating: rating,
                                comment: commentCtrl.text.trim(),
                              );
                              // Ustaga ham baho (agar tanlansa)
                              if (hasMaster && masterRating > 0) {
                                await ReviewService().createReview(
                                  bookingId: booking.id,
                                  targetId: booking.masterId!,
                                  reviewType: 'owner_to_master',
                                  rating: masterRating,
                                  comment: commentCtrl.text.trim(),
                                );
                              }
                              if (ctx.mounted) {
                                FocusScope.of(ctx).unfocus();
                                Navigator.pop(ctx);
                              }
                              ref.invalidate(
                                _bookingReviewProvider(booking.id),
                              );
                            } catch (e) {
                              if (ctx.mounted) {
                                setModalState(() => saving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Ошибка: ${e.toString().split('\n').first}',
                                    ),
                                    backgroundColor: AppColors.danger,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('review.submit'.tr()),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  commentCtrl.dispose();
}

// ── Ish jarayoni ─────────────────────────────────────────────────────────────
// Mijoz ish boshlanganidan yakuniga qadar xabardor bo'lib turadi:
// nechanchi bosqich, qaysi bosqich hozir bajarilyapti, usta yuborgan rasmlar.

/// Kelishuv bosqichi ostida chiqadigan taklif kartochkasi — mijoz shu
/// yerda javob beradi. Timeline'ning o'zi umumiy vidjetda
/// (`booking_shared.dart`), bu esa faqat mijozga xos qism.
class _StageApproval extends ConsumerStatefulWidget {
  final Booking booking;
  final BookingStage stage;

  const _StageApproval({required this.booking, required this.stage});

  @override
  ConsumerState<_StageApproval> createState() => _StageApprovalState();
}

class _StageApprovalState extends ConsumerState<_StageApproval> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final proposals = widget.booking.proposedExtras
        .where((e) => e.stageId == widget.stage.id)
        .toList();
    if (proposals.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [for (final e in proposals) _proposal(context, e)],
    );
  }

  Widget _proposal(BuildContext context, BookingExtra e) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface2(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.text(context)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${formatAmount(e.price)} ${'common.sum'.tr()}',
                style: AppTypography.soraSize(13, weight: FontWeight.w700)
                    .copyWith(color: AppColors.text(context)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _answerBtn(
                  label: 'booking.extra_approve'.tr(),
                  color: AppColors.success,
                  filled: true,
                  onTap: () => _respond(e, true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _answerBtn(
                  label: 'booking.extra_reject'.tr(),
                  color: AppColors.danger,
                  filled: false,
                  onTap: () => _respond(e, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerBtn({
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        height: AppSpacing.buttonHeightSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border:
              filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppSpacing.r_sm),
        ),
        child: Opacity(
          opacity: _busy ? 0.5 : 1,
          child: Text(
            label,
            style: AppTypography.labelMedium
                .copyWith(color: filled ? Colors.white : color),
          ),
        ),
      ),
    );
  }

  Future<void> _respond(BookingExtra e, bool approve) async {
    setState(() => _busy = true);
    try {
      await BookingService()
          .respondToExtra(widget.booking.id, e.id, approve: approve);
      ref.invalidate(_bookingDetailProvider(widget.booking.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ── Pastda yopishgan to'lov paneli ───────────────────────────────────────────

class _PayBar extends StatelessWidget {
  final Booking booking;
  const _PayBar({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        border: Border(top: BorderSide(color: AppColors.hairline(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              // Maketdagi kichik dumaloq tugma. Vazifasi hali
              // belgilanmagan — ko'rinadi, lekin bosilmaydi.
              Opacity(
                opacity: 0.4,
                child: Container(
                  width: AppSpacing.buttonHeight,
                  height: AppSpacing.buttonHeight,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.hairline2(context)),
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    size: 19,
                    color: AppColors.text2(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  brand: true,
                  radius: AppSpacing.r_lg,
                  label: 'booking.pay_amount'.tr(
                    namedArgs: {'amount': formatAmount(booking.totalPrice)},
                  ),
                  onPressed: () => context.push(
                    '/owner/bookings/${booking.id}/pay'
                    '?amount=${booking.totalPrice}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
