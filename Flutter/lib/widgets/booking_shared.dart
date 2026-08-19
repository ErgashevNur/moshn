import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/api.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/formatters.dart';

/// Bron tafsilotlarining ikkala tomonda bir xil ko'rinadigan qismlari.
///
/// Mijoz ekrani (`booking_detail_screen`) va Pro ekrani
/// (`service_booking_detail_screen`) shu vidjetlardan foydalanadi —
/// usta mijoz nimani ko'rayotganini aynan ko'radi va ikki ekran vaqt
/// o'tib bir-biridan uzoqlashib ketmaydi.

/// "09:35"
String bookingHhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Bo'lim sarlavhasi ("ЭТАПЫ РАБОТ").
class BookingSectionLabel extends StatelessWidget {
  final String text;
  const BookingSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTypography.eyebrow.copyWith(color: AppColors.text3(context)),
      );
}

BoxDecoration _cardDecoration(BuildContext c) => BoxDecoration(
      color: AppColors.surface(c),
      borderRadius: BorderRadius.circular(AppSpacing.r_lg),
      border: Border.all(color: AppColors.hairline(c)),
    );

// ── Jarayon sarlavhasi ───────────────────────────────────────────────────────

class BookingProgressHeader extends StatelessWidget {
  final Booking booking;
  const BookingProgressHeader({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final step = b.currentStep;
    final active = b.activeStage;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'booking.order_no'.tr(namedArgs: {'no': '${b.orderNo}'}),
                  style: AppTypography.eyebrow
                      .copyWith(color: AppColors.text3(context)),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(AppSpacing.r_full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'booking.step_of'.tr(namedArgs: {
                        'step': '$step',
                        'total': '${b.stages.length}',
                      }),
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.gold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _statusTitle(),
            style: AppTypography.soraSize(27, weight: FontWeight.w700)
                .copyWith(color: AppColors.text(context), height: 1.15),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle(context),
            style: AppTypography.body
                .copyWith(color: AppColors.text3(context), fontSize: 12.5),
          ),
          if (active != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.r_full),
              child: LinearProgressIndicator(
                value: b.progress,
                minHeight: 7,
                backgroundColor: AppColors.surface2(context),
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'booking.step_label'
                        .tr(namedArgs: {'step': '$step', 'name': active.name}),
                    style: AppTypography.body.copyWith(
                        color: AppColors.text2(context), fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'booking.percent_done'.tr(
                    namedArgs: {'percent': '${(b.progress * 100).round()}'},
                  ),
                  style: AppTypography.soraSize(12, weight: FontWeight.w700)
                      .copyWith(color: AppColors.gold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "Замена масла · 18 августа, 10:30 · PitGo Юнусабад".
  /// Bo'sh qismlar tushib qoladi — ajratgich osilib qolmasin.
  String _subtitle(BuildContext context) {
    final lang = context.locale.languageCode;
    final parts = <String>[
      booking.package?.name ?? booking.serviceType?.nameFor(lang) ?? '',
      '${formatDayMonth(booking.scheduledAt, lang)}, '
          '${bookingHhmm(booking.scheduledAt)}',
      booking.shop?.shopName ?? '',
    ].where((e) => e.trim().isNotEmpty);
    return parts.join(' · ');
  }

  String _statusTitle() {
    if (booking.isInProgress) return 'booking.status_in_progress'.tr();
    if (booking.isCompleted) return 'booking.status_done'.tr();
    if (booking.isConfirmed) return 'booking.status_confirmed'.tr();
    if (booking.isCancelled) return 'booking.status_cancelled'.tr();
    return 'booking.status_pending'.tr();
  }
}

// ── Bosqichlar timeline'i ────────────────────────────────────────────────────

/// Bosqich ostiga qo'shiladigan qism: mijozda — rozilik tugmalari,
/// Pro'da — "Boshlash / Bajarildi". `null` qaytarilsa hech nima qo'shilmaydi.
typedef StageSlotBuilder = Widget? Function(BuildContext, BookingStage);

class BookingStagesTimeline extends StatelessWidget {
  final Booking booking;
  final StageSlotBuilder? below;

  const BookingStagesTimeline({
    super.key,
    required this.booking,
    this.below,
  });

  /// Kutilayotgan bosqichlar uchun taxminiy tugash vaqti ("≈ 11:30").
  ///
  /// Oxirgi ma'lum vaqtdan (yoki hozirdan — ish kechikkan bo'lsa) boshlab
  /// har bir qolgan bosqichga paket davomiyligining teng ulushi beriladi.
  /// Aniq prognoz emas, shuning uchun "≈" bilan ko'rsatiladi.
  Map<String, DateTime> _estimates() {
    final stages = booking.stages;
    if (stages.isEmpty) return const {};

    final perMin = ((booking.package?.durationMin ?? 60) / stages.length)
        .round()
        .clamp(5, 240);

    DateTime? last;
    for (final s in stages) {
      final t = s.completedAt ?? s.startedAt;
      if (t != null && (last == null || t.isAfter(last))) last = t;
    }
    var cursor = last ?? booking.scheduledAt;
    final now = DateTime.now();
    if (cursor.isBefore(now)) cursor = now;

    final out = <String, DateTime>{};
    for (final s in stages) {
      if (s.isDone || s.isActive || s.isAwaiting) continue;
      cursor = cursor.add(Duration(minutes: perMin));
      out[s.id] = cursor;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final stages = booking.stages;
    final etas = _estimates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingSectionLabel('booking.stages'.tr()),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              for (var i = 0; i < stages.length; i++)
                _StageRow(
                  stage: stages[i],
                  eta: etas[stages[i].id],
                  isLast: i == stages.length - 1,
                  below: below?.call(context, stages[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  final BookingStage stage;
  final DateTime? eta;
  final bool isLast;
  final Widget? below;

  const _StageRow({
    required this.stage,
    required this.eta,
    required this.isLast,
    required this.below,
  });

  @override
  Widget build(BuildContext context) {
    final s = stage;
    final (icon, color, label) = switch (s.status) {
      'done' => (
          Icons.check_rounded,
          AppColors.success,
          'booking.stage_done'.tr()
        ),
      'in_progress' => (
          Icons.wb_sunny_rounded,
          AppColors.gold,
          'booking.stage_active'.tr()
        ),
      'awaiting_customer' => (
          Icons.priority_high_rounded,
          s.isOverdue ? AppColors.danger : AppColors.gold,
          s.isOverdue
              ? 'booking.stage_overdue'.tr()
              : 'booking.stage_awaiting'.tr()
        ),
      _ => (
          Icons.schedule_rounded,
          AppColors.text3(context),
          'booking.stage_waiting'.tr()
        ),
    };

    // Vaqt ustuni: bajarilgan/kutilayotgan — aniq soat, bajarilayotgan —
    // "сейчас", hali boshlanmagan — "≈ 11:30".
    final String timeLabel;
    if (s.isActive) {
      timeLabel = 'booking.now'.tr();
    } else if (s.completedAt != null || s.startedAt != null) {
      timeLabel = bookingHhmm((s.completedAt ?? s.startedAt)!);
    } else if (eta != null) {
      timeLabel = '≈ ${bookingHhmm(eta!)}';
    } else {
      timeLabel = '';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ikonka + pastga ketuvchi ulash chizig'i.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1.5,
                        color: AppColors.hairline2(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.only(top: 2, bottom: isLast ? 2 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          s.name,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.text(context),
                            fontWeight: s.isActive || s.isAwaiting
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: AppTypography.mono.copyWith(
                            color: s.isActive
                                ? AppColors.gold
                                : AppColors.text3(context),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      style: AppTypography.body
                          .copyWith(color: color, fontSize: 11.5)),
                  ?below,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fotohisobot ──────────────────────────────────────────────────────────────

class BookingPhotoReport extends StatelessWidget {
  final List<BookingPhoto> photos;

  /// Pro tomonda rasm qo'shish tugmasi. Mijozda `null`.
  final VoidCallback? onAdd;

  const BookingPhotoReport({super.key, required this.photos, this.onAdd});

  /// Maketda ikkita rasm ko'rinadi, qolgani "+N фото" ostida.
  static const _visible = 2;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && onAdd == null) return const SizedBox.shrink();

    final shown = photos.take(_visible).toList();
    final hidden = photos.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: BookingSectionLabel('booking.photo_report_master'.tr()),
            ),
            if (photos.isNotEmpty)
              Text(
                bookingHhmm(photos.last.createdAt),
                style: AppTypography.mono.copyWith(
                    color: AppColors.text3(context), fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (photos.isNotEmpty)
          SizedBox(
            height: 96,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _thumb(context, i)),
                    ],
                    // Bitta rasm bo'lsa lenta yarim bo'sh qolmasin.
                    if (shown.length == 1) const Spacer(),
                  ],
                ),
                if (hidden > 0)
                  Positioned(
                    right: AppSpacing.sm,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => openPhotoViewer(context, photos, _visible),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.78),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.r_sm),
                          ),
                          child: Text(
                            'booking.more_photos'
                                .tr(namedArgs: {'count': '$hidden'}),
                            style: AppTypography.labelMedium
                                .copyWith(color: Colors.white, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (onAdd != null) ...[
          if (photos.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: AppSpacing.buttonHeightSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline2(context)),
                borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_rounded,
                      size: 17, color: AppColors.text2(context)),
                  const SizedBox(width: AppSpacing.sm),
                  Text('service.work_photo_add'.tr(),
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.text(context))),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumb(BuildContext context, int i) => GestureDetector(
        onTap: () => openPhotoViewer(context, photos, i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.r_sm),
          child: CachedNetworkImage(
            imageUrl: ApiClient.mediaUrl(photos[i].url),
            height: 96,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                Container(color: AppColors.surface2(context)),
            errorWidget: (_, _, _) => Container(
              color: AppColors.surface2(context),
              child: Icon(Icons.broken_image_rounded,
                  color: AppColors.text3(context)),
            ),
          ),
        ),
      );
}

/// To'liq ekranda ko'rish — suvurat mayda ko'rinsa ish sifati baholanmaydi.
void openPhotoViewer(
  BuildContext context,
  List<BookingPhoto> photos,
  int index,
) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.pop(ctx),
      child: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: index),
            itemCount: photos.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: ApiClient.mediaUrl(photos[i].url),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 40,
            right: 20,
            child: Icon(Icons.close_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    ),
  );
}

// ── К оплате ─────────────────────────────────────────────────────────────────

class BookingPaymentCard extends StatelessWidget {
  final Booking booking;
  final bool isPaid;

  const BookingPaymentCard({
    super.key,
    required this.booking,
    this.isPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    // Asosiy qator: paket nomi (bo'lmasa — xizmat turi). Narxi `basePrice`
    // dan olinadi, shunda qatorlar yig'indisi doim "Итого" ga teng chiqadi.
    final baseLabel = booking.package != null
        ? 'booking.package_row'.tr(namedArgs: {'name': booking.package!.name})
        : (booking.serviceType?.nameFor(lang) ?? 'booking.price'.tr());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookingSectionLabel('booking.to_payment'.tr()),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              _row(context, baseLabel, booking.basePrice),
              for (final e in booking.approvedExtras) ...[
                const SizedBox(height: AppSpacing.md),
                _row(context, e.name, e.price),
              ],
              const SizedBox(height: AppSpacing.md),
              Container(height: 0.5, color: AppColors.hairline(context)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'booking.total'.tr(),
                      style: AppTypography.soraSize(15, weight: FontWeight.w700)
                          .copyWith(color: AppColors.text(context)),
                    ),
                  ),
                  Text(
                    '${formatAmount(booking.totalPrice)} ${'common.sum'.tr()}',
                    style: AppTypography.soraSize(17, weight: FontWeight.w700)
                        .copyWith(color: AppColors.gold),
                  ),
                ],
              ),
              if (isPaid) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'booking.paid'.tr(),
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, int amount) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body
                  .copyWith(color: AppColors.text2(context), fontSize: 13.5),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${formatAmount(amount)} ${'common.sum'.tr()}',
            style: AppTypography.soraSize(13.5, weight: FontWeight.w600)
                .copyWith(color: AppColors.text(context)),
          ),
        ],
      );
}
