import 'package:flutter/cupertino.dart';

/// Cupertino-style minimalist colour palette for Moshn.
/// Derived from the black-on-white logo: monochrome brand with iOS-system
/// accents for status states.
class AppColors {
  AppColors._();

  // Brand — pulled from the Moshn logo (pure black on white).
  // [primary] resolves automatically inside Cupertino widgets via
  // CupertinoDynamicColor: black in light mode, white in dark mode. For sites
  // that do not auto-resolve (Container.color, Icon, Text), use
  // [primaryOf(context)] / [onPrimaryOf(context)].
  static const CupertinoDynamicColor primary = CupertinoDynamicColor.withBrightness(
    color: Color(0xFF111111),
    darkColor: Color(0xFFFFFFFF),
  );
  static const Color primaryDark = Color(0xFF000000);

  /// Brightness-aware primary brand color. Use whenever the dynamic [primary]
  /// would not auto-resolve (e.g. `Container(color: ...)`, `Icon(color: ...)`).
  static Color primaryOf(BuildContext context) =>
      CupertinoDynamicColor.resolve(primary, context);

  /// Foreground that sits on top of [primaryOf] — white on black, black on white.
  static Color onPrimaryOf(BuildContext context) =>
      CupertinoTheme.brightnessOf(context) == Brightness.dark
          ? const Color(0xFF111111)
          : const Color(0xFFFFFFFF);

  // Backgrounds (light)
  static const Color background = Color(0xFFF2F2F7); // iOS systemGroupedBackground
  static const Color surface = CupertinoColors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Backgrounds (dark)
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceElevatedDark = Color(0xFF2C2C2E);

  // Text
  static const Color label = Color(0xFF000000);
  static const Color labelSecondary = Color(0xFF3C3C43);
  static const Color labelTertiary = Color(0xFF8E8E93);
  static const Color labelDark = Color(0xFFFFFFFF);
  static const Color labelSecondaryDark = Color(0xFFEBEBF5);

  // Separators
  static const Color separator = Color(0x33545458);
  static const Color separatorDark = Color(0x59545458);

  // Status
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color destructive = Color(0xFFFF3B30);
  static const Color info = Color(0xFF5AC8FA);

  // Service status colors
  static const Color statusPending = Color(0xFFFF9500);
  static const Color statusConfirmed = Color(0xFF34C759);
  static const Color statusRejected = Color(0xFFFF3B30);
  static const Color statusAuto = Color(0xFF8E8E93);

  // Fill (for cards, chips)
  static const Color fillPrimary = Color(0x14787880);
  static const Color fillSecondary = Color(0x0F787880);
}
