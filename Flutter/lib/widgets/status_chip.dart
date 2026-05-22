import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import '../models/service_record.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class StatusChip extends StatelessWidget {
  final ServiceStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, key) = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        key.tr(),
        style: AppTypography.caption1.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _styleFor(ServiceStatus s) {
    switch (s) {
      case ServiceStatus.confirmed:
        return (AppColors.statusConfirmed, 'owner.service_confirmed');
      case ServiceStatus.rejected:
        return (AppColors.statusRejected, 'owner.service_rejected');
      case ServiceStatus.autoConfirmed:
        return (AppColors.statusAuto, 'owner.service_auto');
      case ServiceStatus.draft:
        return (AppColors.statusAuto, 'common.loading');
      case ServiceStatus.created:
        return (AppColors.statusPending, 'owner.service_pending');
    }
  }
}
