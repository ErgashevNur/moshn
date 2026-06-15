import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'm_moshn_icon.dart';

class MServiceTile extends StatelessWidget {
  const MServiceTile({
    super.key,
    required this.label,
    required this.iconName,
    required this.active,
    required this.onTap,
    // Legacy support — ignored when iconName is set
    this.icon,
  });

  final String label;
  final String iconName;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon; // kept for API compat, not used

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.inverseBg(context) : AppColors.surface(context);
    final fg = active ? AppColors.inverseText(context) : AppColors.text(context);
    final border = active ? null : Border.all(color: AppColors.hairline(context), width: 1);

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final iconSize = (w * 0.30).clamp(20.0, 32.0);
        final fontSize = (w * 0.135).clamp(10.5, 13.5);
        final vPad = (w * 0.17).clamp(12.0, 20.0);
        final hPad = (w * 0.07).clamp(5.0, 10.0);
        final gap  = (w * 0.085).clamp(6.0, 10.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad * 0.85),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.r_lg),
            border: border,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoshnIcon(name: iconName, size: iconSize, color: fg),
              SizedBox(height: gap),
              SizedBox(
                width: w - 2 * hPad,
                child: label.contains(' ')
                  ? Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.soraSize(fontSize, weight: FontWeight.w500).copyWith(
                        color: fg,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTypography.soraSize(fontSize, weight: FontWeight.w500).copyWith(
                          color: fg,
                          height: 1.2,
                        ),
                        maxLines: 1,
                      ),
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
