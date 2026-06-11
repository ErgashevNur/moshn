import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum MButtonVariant { primary, secondary, outline, danger }

class MButton extends StatefulWidget {
  const MButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = MButtonVariant.primary,
    this.small = false,
    this.leading,
    this.trailing,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final MButtonVariant variant;
  final bool small;
  final Widget? leading;
  final Widget? trailing;
  final bool loading;
  final bool enabled;

  @override
  State<MButton> createState() => _MButtonState();
}

class _MButtonState extends State<MButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double height = widget.small ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeight;
    final double fontSize = widget.small ? 14 : 16;
    final double iconSize = widget.small ? 17 : 19;

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.variant) {
      case MButtonVariant.primary:
        bgColor = AppColors.inverseBg(context);
        fgColor = AppColors.inverseText(context);
      case MButtonVariant.secondary:
        bgColor = AppColors.surface2(context);
        fgColor = AppColors.text(context);
      case MButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.text(context);
        border = Border.all(color: AppColors.hairline2(context), width: 1.5);
      case MButtonVariant.danger:
        bgColor = AppColors.danger;
        fgColor = Colors.white;
    }

    if (!widget.enabled) {
      bgColor = bgColor.withAlpha(115); // ~0.45
      fgColor = fgColor.withAlpha(128); // ~0.5
    }

    final content = Row(
      mainAxisSize: widget.small ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          IconTheme(
            data: IconThemeData(color: fgColor, size: iconSize),
            child: widget.leading!,
          ),
          const SizedBox(width: 8),
        ],
        if (widget.loading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else
          Flexible(
            child: Text(
              widget.label,
              style: AppTypography.labelLarge.copyWith(
                fontSize: fontSize,
                color: fgColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(color: fgColor, size: iconSize),
            child: widget.trailing!,
          ),
        ],
      ],
    );

    return GestureDetector(
      onTapDown: widget.enabled && !widget.loading
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.enabled && !widget.loading
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: height,
          width: widget.small ? null : double.infinity,
          padding: widget.small
              ? const EdgeInsets.symmetric(horizontal: 20)
              : null,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.r_full),
            border: border,
          ),
          child: content,
        ),
      ),
    );
  }
}
