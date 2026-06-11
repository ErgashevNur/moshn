import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class MAppBar extends StatelessWidget {
  const MAppBar({
    super.key,
    this.title,
    this.large = false,
    this.eyebrow,
    this.right,
    this.onBack,
    this.showBack = true,
  });

  final String? title;
  final bool large;
  final String? eyebrow;
  final Widget? right;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBack && canPop)
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.hairline(context),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: AppColors.text(context),
                ),
              ),
            ),
          if (showBack && canPop) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppTypography.eyebrow.copyWith(
                      color: AppColors.text3(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                if (title != null)
                  Text(
                    title!,
                    style: large
                        ? AppTypography.displayMedium.copyWith(
                            color: AppColors.text(context),
                          )
                        : AppTypography.appbarTitle.copyWith(
                            color: AppColors.text(context),
                          ),
                  ),
              ],
            ),
          ),
          if (right != null) ...[
            const SizedBox(width: 12),
            right!,
          ],
        ],
      ),
    );
  }
}
