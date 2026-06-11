import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class MCard extends StatelessWidget {
  const MCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        border: Border.all(color: AppColors.hairline(context), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
