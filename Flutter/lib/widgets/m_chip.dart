import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class MChip extends StatefulWidget {
  const MChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<MChip> createState() => _MChipState();
}

class _MChipState extends State<MChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? AppColors.inverseBg(context)
        : AppColors.surface(context);
    final fg = widget.active
        ? AppColors.inverseText(context)
        : AppColors.text2(context);
    final border = widget.active
        ? null
        : Border.all(color: AppColors.hairline(context), width: 1);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.r_full),
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
