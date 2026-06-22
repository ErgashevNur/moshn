import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.r_full),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (Color, String) _style(String s) {
    switch (s) {
      case 'pending':   return (AppColors.gold, 'Ожидает');
      case 'confirmed': return (AppColors.success, 'Подтверждено');
      case 'in_progress': return (const Color(0xFF0A84FF), 'В процессе');
      case 'completed': return (AppColors.success, 'Выполнено');
      case 'cancelled': return (AppColors.danger, 'Отменено');
      case 'verified':  return (AppColors.success, 'Подтверждён');
      default:          return (const Color(0xFF8E8E93), s);
    }
  }
}
