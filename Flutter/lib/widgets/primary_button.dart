import 'package:flutter/cupertino.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool destructive;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.destructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = destructive ? AppColors.destructive : AppColors.primaryOf(context);
    final fg = destructive ? CupertinoColors.white : AppColors.onPrimaryOf(context);
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onPressed: loading ? null : onPressed,
        child: loading
            ? CupertinoActivityIndicator(color: fg)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTypography.headline.copyWith(color: fg),
                  ),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final bg = brightness == Brightness.dark
        ? AppColors.surfaceElevatedDark
        : AppColors.fillPrimary;
    final fg =
        brightness == Brightness.dark ? AppColors.labelDark : AppColors.label;
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTypography.headline.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
