import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_record.dart';
import '../../services/service_record_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_chip.dart';

final _serviceProvider =
    FutureProvider.autoDispose.family<ServiceRecord, String>((ref, id) {
  return ServiceRecordService().get(id);
});

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;

  /// Owner-only confirm/reject actions. Hidden when a mechanic views their own
  /// record (they have no authority to confirm).
  final bool showActions;
  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.showActions = true,
  });

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ServiceRecordService().confirm(widget.serviceId);
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await ServiceRecordService().reject(widget.serviceId);
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_serviceProvider(widget.serviceId));
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('owner.recent_services'.tr()),
      ),
      child: SafeArea(
        child: state.when(
          data: (s) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.serviceType.isEmpty
                            ? 'mechanic.add_service'.tr()
                            : s.serviceType,
                        style: AppTypography.title2,
                      ),
                    ),
                    StatusChip(status: s.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    if (s.mechanicName.isNotEmpty) s.mechanicName,
                    formatDateTime(s.serviceDate),
                  ].join(' · '),
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mechanic.service_description'.tr(),
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.labelTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(s.description, style: AppTypography.body),
                    ],
                  ),
                ),
                if (s.partsUsed.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mechanic.parts_used'.tr(),
                          style: AppTypography.footnote.copyWith(
                            color: AppColors.labelTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...s.partsUsed.map(
                          (p) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (p['name'] ?? '').toString(),
                                    style: AppTypography.body,
                                  ),
                                ),
                                Text(
                                  formatCurrency((p['price'] as num?) ?? 0),
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.labelSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (s.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'mechanic.notes'.tr(),
                          style: AppTypography.footnote.copyWith(
                            color: AppColors.labelTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(s.notes, style: AppTypography.body),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SectionCard(
                  child: Column(
                    children: [
                      if (s.mileageKm != null) ...[
                        _row('owner.mileage'.tr(),
                            formatMileage(s.mileageKm!)),
                        _divider(),
                      ],
                      _row(
                        'mechanic.total_cost'.tr(),
                        formatCurrency(s.totalCost),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                if (widget.showActions && s.status == ServiceStatus.created) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'common.confirm'.tr(),
                    icon: CupertinoIcons.check_mark,
                    onPressed: _confirm,
                    loading: _busy,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'common.reject'.tr(),
                    destructive: true,
                    onPressed: _busy ? null : _reject,
                  ),
                ],
                const SizedBox(height: AppSpacing.huge),
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

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: AppTypography.subhead.copyWith(
                  color: AppColors.labelTertiary,
                ),
              ),
            ),
            Text(
              v,
              style: bold
                  ? AppTypography.headline
                  : AppTypography.body,
            ),
          ],
        ),
      );

  Widget _divider() => Container(height: 0.5, color: AppColors.separator);
}
