import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum MTagVariant { default_, gold, success, danger }

class MTag extends StatelessWidget {
  const MTag({
    super.key,
    required this.label,
    this.variant = MTagVariant.default_,
    this.icon,
  });

  final String label;
  final MTagVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case MTagVariant.gold:
        bg = AppColors.goldDim;
        fg = AppColors.gold;
      case MTagVariant.success:
        bg = AppColors.successDim;
        fg = AppColors.success;
      case MTagVariant.danger:
        bg = AppColors.dangerDim;
        fg = AppColors.danger;
      case MTagVariant.default_:
        bg = AppColors.surface2(context);
        fg = AppColors.text2(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.r_xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.soraSize(11.5, weight: FontWeight.w600)
                .copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
