import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Dark theme raw values ---
  static const Color _darkBg = Color(0xFF09090A);
  static const Color _darkBgElevated = Color(0xFF131316);
  static const Color _darkSurface = Color(0xFF1A1A1E);
  static const Color _darkSurface2 = Color(0xFF242429);
  static const Color _darkSurface3 = Color(0xFF2E2E34);
  static const Color _darkHairline = Color(0x16FFFFFF); // rgba(255,255,255,0.085)
  static const Color _darkHairline2 = Color(0x24FFFFFF); // rgba(255,255,255,0.14)
  static const Color _darkText = Color(0xFFF4F4F2);
  static const Color _darkText2 = Color(0x99F4F4F2); // 0.60 opacity
  static const Color _darkText3 = Color(0x5CF4F4F2); // 0.36 opacity
  static const Color _darkInverseBg = Color(0xFFF4F4F2);
  static const Color _darkInverseText = Color(0xFF0A0A0B);

  // --- Light theme raw values ---
  static const Color _lightBg = Color(0xFFF4F3F0);
  static const Color _lightBgElevated = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurface2 = Color(0xFFECEBE7);
  static const Color _lightSurface3 = Color(0xFFE3E2DD);
  static const Color _lightHairline = Color(0x1714140F); // rgba(20,20,16,0.09)
  static const Color _lightHairline2 = Color(0x2614140F); // rgba(20,20,16,0.15)
  static const Color _lightText = Color(0xFF14140F);
  static const Color _lightText2 = Color(0x9414140F); // 0.58 opacity
  static const Color _lightText3 = Color(0x6614140F); // 0.40 opacity
  static const Color _lightInverseBg = Color(0xFF14140F);
  static const Color _lightInverseText = Color(0xFFF6F5F2);

  // --- Semantic / shared ---
  static const Color gold = Color(0xFFD4A843);
  static const Color goldDim = Color(0x29D4A843); // rgba(212,168,67,0.16)
  static const Color danger = Color(0xFFE5382B);
  static const Color dangerDim = Color(0x29E5382B); // rgba(229,56,43,0.16)
  static const Color success = Color(0xFF30D158);
  static const Color successDim = Color(0x2930D158); // rgba(48,209,88,0.16)

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      _isDark(context) ? _darkBg : _lightBg;

  static Color bgElevated(BuildContext context) =>
      _isDark(context) ? _darkBgElevated : _lightBgElevated;

  static Color surface(BuildContext context) =>
      _isDark(context) ? _darkSurface : _lightSurface;

  static Color surface2(BuildContext context) =>
      _isDark(context) ? _darkSurface2 : _lightSurface2;

  static Color surface3(BuildContext context) =>
      _isDark(context) ? _darkSurface3 : _lightSurface3;

  static Color hairline(BuildContext context) =>
      _isDark(context) ? _darkHairline : _lightHairline;

  static Color hairline2(BuildContext context) =>
      _isDark(context) ? _darkHairline2 : _lightHairline2;

  static Color text(BuildContext context) =>
      _isDark(context) ? _darkText : _lightText;

  static Color text2(BuildContext context) =>
      _isDark(context) ? _darkText2 : _lightText2;

  static Color text3(BuildContext context) =>
      _isDark(context) ? _darkText3 : _lightText3;

  static Color inverseBg(BuildContext context) =>
      _isDark(context) ? _darkInverseBg : _lightInverseBg;

  static Color inverseText(BuildContext context) =>
      _isDark(context) ? _darkInverseText : _lightInverseText;

  static Color scrim(BuildContext context) => _isDark(context)
      ? const Color(0x99000000)
      : const Color(0x73140E0E); // rgba(20,18,14,0.45)
}
