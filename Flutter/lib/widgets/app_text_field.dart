import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String placeholder;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? errorText;
  final TextCapitalization textCapitalization;
  final int? maxLines;

  const AppTextField({
    super.key,
    this.controller,
    required this.placeholder,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final fillColor = brightness == Brightness.dark
        ? AppColors.surface2(context)
        : AppColors.surface(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textCapitalization: textCapitalization,
          maxLines: obscureText ? 1 : maxLines,
          minLines: 1,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          prefix: icon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  child: Icon(icon, size: 20, color: AppColors.text3(context)),
                )
              : null,
          style: AppTypography.body,
          placeholderStyle: AppTypography.body.copyWith(
            color: AppColors.text3(context),
          ),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
      ],
    );
  }
}
