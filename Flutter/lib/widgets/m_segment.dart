import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class MSegment extends StatelessWidget {
  const MSegment({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface2(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_full),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: EdgeInsets.only(right: i < items.length - 1 ? 2 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.bgElevated(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.r_full),
                  boxShadow: isActive ? AppSpacing.shadow1 : null,
                ),
                child: Text(
                  items[i],
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppColors.text(context)
                        : AppColors.text2(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
