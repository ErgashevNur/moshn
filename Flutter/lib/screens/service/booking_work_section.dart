import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/booking_shared.dart';

/// Usta/servis tomonidagi ish boshqaruvi: bosqichlarni siljitish,
/// fotohisobotga rasm qo'shish va qo'shimcha ish taklif qilish.
///
/// Backend bu uchalasini 15-avgustdan beri qo'llab-quvvatlaydi, lekin
/// ilovada ularni chaqiradigan joy yo'q edi — shu sababli mijozning
/// "В работе" ekranidagi bosqichlar hech qachon siljimasdi.
class BookingWorkSection extends ConsumerStatefulWidget {
  final Booking booking;
  final VoidCallback onChanged;

  const BookingWorkSection({
    super.key,
    required this.booking,
    required this.onChanged,
  });

  @override
  ConsumerState<BookingWorkSection> createState() => _BookingWorkSectionState();
}

class _BookingWorkSectionState extends ConsumerState<BookingWorkSection> {
  bool _busy = false;

  Booking get b => widget.booking;

  @override
  Widget build(BuildContext context) {
    if (b.isCancelled) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (b.stages.isNotEmpty) ...[
          // Mijoz ko'rayotgan timeline'ning o'zi — har bosqich ostida
          // ustaning boshqaruvi.
          BookingStagesTimeline(
            booking: b,
            below: (ctx, stage) => _stageAction(ctx, stage),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        BookingPhotoReport(photos: b.photos, onAdd: _busy ? () {} : _addPhoto),
        const SizedBox(height: AppSpacing.lg),
        BookingSectionLabel('service.work_extra'.tr()),
        const SizedBox(height: AppSpacing.sm),
        _card(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final e in b.extras) _extraRow(context, e),
              if (b.extras.isNotEmpty) const SizedBox(height: AppSpacing.sm),
              _action(
                context,
                icon: Icons.add_rounded,
                label: 'service.work_extra_add'.tr(),
                onTap: _proposeExtra,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext c, Widget child) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface(c),
          borderRadius: BorderRadius.circular(AppSpacing.r_lg),
          border: Border.all(color: AppColors.hairline(c)),
        ),
        child: child,
      );

  /// Bosqich ostidagi boshqaruv. Kelishuv bosqichida tugma yo'q — uni
  /// faqat mijozning javobi yopadi (server ham buni rad etadi).
  Widget? _stageAction(BuildContext context, BookingStage s) {
    if (s.isAwaiting) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'service.stage_locked'.tr(),
          style: AppTypography.body
              .copyWith(color: AppColors.danger, fontSize: 11.5),
        ),
      );
    }

    final (nextStatus, label) = switch (s.status) {
      'done' => (null, null),
      'in_progress' => ('done', 'service.stage_finish'.tr()),
      _ => ('in_progress', 'service.stage_start'.tr()),
    };
    if (nextStatus == null) return null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: _busy ? null : () => _setStage(s, nextStatus),
          child: Opacity(
            opacity: _busy ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(AppSpacing.r_full),
              ),
              child: Text(
                label!,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.gold, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Qo'shimcha ish ─────────────────────────────────────────────────────────

  Widget _extraRow(BuildContext context, BookingExtra e) {
    final (color, label) = switch (e.status) {
      'approved' => (AppColors.success, 'service.extra_approved'.tr()),
      'rejected' => (AppColors.danger, 'service.extra_rejected'.tr()),
      _ => (AppColors.gold, 'service.extra_waiting'.tr()),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.text(context))),
                const SizedBox(height: 2),
                Text(label,
                    style:
                        AppTypography.body.copyWith(color: color, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${formatAmount(e.price)} ${'common.sum'.tr()}',
            style: AppTypography.soraSize(13, weight: FontWeight.w600)
                .copyWith(color: AppColors.text(context)),
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Opacity(
        opacity: _busy ? 0.5 : 1,
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
              Icon(icon, size: 17, color: AppColors.text2(context)),
              const SizedBox(width: AppSpacing.sm),
              Text(label,
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.text(context))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Amallar ────────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_message(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Serverning izohli xatosini ko'rsatadi ("Mijozning javobi kutilmoqda"),
  /// bo'lmasa umumiy matn.
  String _message(Object e) {
    final s = e.toString();
    final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(s);
    return m?.group(1) ?? 'common.error'.tr();
  }

  void _setStage(BookingStage s, String status) =>
      _run(() => BookingService().setStageStatus(b.id, s.id, status));

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading:
                  Icon(Icons.photo_camera_rounded, color: AppColors.text(ctx)),
              title: Text('vehicle.photo_camera'.tr(),
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.text(ctx))),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading:
                  Icon(Icons.photo_library_rounded, color: AppColors.text(ctx)),
              title: Text('vehicle.photo_gallery'.tr(),
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.text(ctx))),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Server chegarasi 8 MB — katta faylni yubormaymiz.
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 1920, imageQuality: 85);
    if (picked == null) return;

    // Bajarilayotgan bosqich bo'lsa rasm o'shanga bog'lanadi.
    final stageId = b.activeStage?.id;
    await _run(() =>
        BookingService().addBookingPhoto(b.id, picked.path, stageId: stageId));
  }

  Future<void> _proposeExtra() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Text('service.work_extra_add'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(ctx, nameCtrl, 'service.work_extra_name'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _field(ctx, priceCtrl, 'service.work_extra_price'.tr(),
                number: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.send'.tr()),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final price = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (name.isEmpty || price == null || price <= 0) return;

    await _run(() =>
        BookingService().proposeExtra(b.id, name: name, price: price));
  }

  Widget _field(
    BuildContext ctx,
    TextEditingController c,
    String hint, {
    bool number = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body.copyWith(color: AppColors.text3(ctx)),
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
    );
  }
}
