import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/mechanic.dart';
import '../../models/review.dart';
import '../../services/mechanic_service.dart';
import '../../services/repair_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

final _mechanicProvider =
    FutureProvider.autoDispose.family<Mechanic, String>((ref, id) {
  return MechanicService().get(id);
});

final _reviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>((ref, id) {
  return MechanicService().reviews(id);
});

class MechanicProfileScreen extends ConsumerWidget {
  final String mechanicId;
  const MechanicProfileScreen({super.key, required this.mechanicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_mechanicProvider(mechanicId));
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(),
      child: SafeArea(
        child: state.when(
          data: (m) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: AppColors.primaryOf(context),
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m.name, style: AppTypography.title2),
                      if (m.verified) ...[
                        const SizedBox(width: 6),
                        Icon(CupertinoIcons.checkmark_seal_fill,
                            color: AppColors.primaryOf(context), size: 20),
                      ],
                    ],
                  ),
                ),
                if (m.bio != null && m.bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    m.bio!,
                    textAlign: TextAlign.center,
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.labelTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _stat(
                          icon: CupertinoIcons.star_fill,
                          color: AppColors.warning,
                          value: m.rating.toStringAsFixed(1),
                          label: 'mechanic.rating'.tr(),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        height: 40,
                        color: AppColors.separator,
                      ),
                      Expanded(
                        child: _stat(
                          icon: CupertinoIcons.wrench_fill,
                          color: AppColors.primaryOf(context),
                          value: m.completedJobs.toString(),
                          label: 'mechanic.completed_jobs'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mechanic.specialization'.tr(),
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.labelTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: m.specialization
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.fillPrimary,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull),
                                  ),
                                  child: Text(s,
                                      style: AppTypography.footnote),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                if (m.address != null && m.address!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.location_solid,
                            color: AppColors.primaryOf(context)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(m.address!, style: AppTypography.body),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: () => showCupertinoModalPopup(
                    context: context,
                    builder: (_) => _RequestSheet(
                      mechanicId: m.id,
                      mechanicName: m.name,
                      defaultPhone: ref.read(authProvider).user?.phone ?? '',
                    ),
                  ),
                  child: Text('Tamirlash so\'rovini yuborish',
                      style: AppTypography.headline
                          .copyWith(color: AppColors.onPrimaryOf(context))),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ReviewsSection(mechanicId: mechanicId),
              ],
            ),
          ),
          loading: () =>
              const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => EmptyState(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: 'common.error'.tr(),
          ),
        ),
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.title3),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption1.copyWith(
            color: AppColors.labelTertiary,
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  final String mechanicId;
  const _ReviewsSection({required this.mechanicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_reviewsProvider(mechanicId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.chat_bubble_2_fill,
                  size: 18, color: AppColors.primaryOf(context)),
              const SizedBox(width: AppSpacing.sm),
              Text('mechanic.reviews'.tr(), style: AppTypography.headline),
              const SizedBox(width: AppSpacing.sm),
              state.maybeWhen(
                data: (items) => Text(
                  '(${items.length})',
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        state.when(
          data: (items) {
            if (items.isEmpty) {
              return SectionCard(
                child: Text(
                  'mechanic.no_reviews'.tr(),
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final r in items) ...[
                  _ReviewCard(review: r),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CupertinoActivityIndicator(),
          ),
          error: (_, _) => SectionCard(
            child: Text(
              'common.error'.tr(),
              style: AppTypography.subhead.copyWith(
                color: AppColors.labelTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName.isEmpty
                      ? 'Foydalanuvchi'
                      : review.authorName,
                  style: AppTypography.subhead,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? CupertinoIcons.star_fill
                        : CupertinoIcons.star,
                    size: 13,
                    color: AppColors.warning,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment, style: AppTypography.body),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat('dd.MM.yyyy').format(review.createdAt!),
              style: AppTypography.caption1.copyWith(
                color: AppColors.labelTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mijoz tamirlash so'rovini yuboradigan modal forma.
class _RequestSheet extends StatefulWidget {
  final String mechanicId;
  final String mechanicName;
  final String defaultPhone;
  const _RequestSheet({
    required this.mechanicId,
    required this.mechanicName,
    required this.defaultPhone,
  });

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  late final TextEditingController _phone =
      TextEditingController(text: widget.defaultPhone);
  final _car = TextEditingController();
  final _desc = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _car.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _desc.text.trim().isEmpty) {
      setState(() => _error = 'Telefon va muammo tavsifini to\'ldiring');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await RepairService().createRequest(
        preferredMechanicId: widget.mechanicId,
        phone: _phone.text.trim(),
        carInfo: _car.text.trim(),
        description: _desc.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('So\'rov yuborildi'),
          content: const Text(
              'Operator so\'rovingizni ko\'rib chiqib, ustaga yo\'naltiradi.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Yuborishda xato. Qaytadan urinib ko\'ring.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: Container(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('So\'rov: ${widget.mechanicName}',
                style: AppTypography.title3),
            const SizedBox(height: 4),
            Text('Tamirlash so\'rovi operatorga yuboriladi',
                style: AppTypography.footnote
                    .copyWith(color: AppColors.labelTertiary)),
            const SizedBox(height: AppSpacing.lg),
            CupertinoTextField(
              controller: _phone,
              placeholder: 'Telefon raqam',
              keyboardType: TextInputType.phone,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: AppSpacing.sm),
            CupertinoTextField(
              controller: _car,
              placeholder: 'Mashina (masalan, Cobalt 2021)',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: AppSpacing.sm),
            CupertinoTextField(
              controller: _desc,
              placeholder: 'Muammo tavsifi',
              maxLines: 3,
              padding: const EdgeInsets.all(12),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: AppTypography.footnote
                      .copyWith(color: AppColors.destructive)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    onPressed:
                        _sending ? null : () => Navigator.of(context).pop(),
                    child: const Text('Bekor'),
                  ),
                ),
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const CupertinoActivityIndicator()
                        : const Text('Yuborish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
