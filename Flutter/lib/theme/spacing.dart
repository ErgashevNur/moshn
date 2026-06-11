import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Generic spacing scale
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // Moshn design system radii (snake_case matches CSS token names intentionally)
  // ignore: constant_identifier_names
  static const double r_xs = 8;
  // ignore: constant_identifier_names
  static const double r_sm = 12;
  // ignore: constant_identifier_names
  static const double r_md = 16;
  // ignore: constant_identifier_names
  static const double r_lg = 22;
  // ignore: constant_identifier_names
  static const double r_xl = 28;
  // ignore: constant_identifier_names
  static const double r_2xl = 34;
  // ignore: constant_identifier_names
  static const double r_full = 999;

  // Legacy aliases (keep for backward compat)
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  // Component heights
  static const double buttonHeight = 54;
  static const double buttonHeightSm = 42;
  static const double inputHeight = 54;
  static const double tabBarHeight = 50;
  static const double navBarHeight = 44;

  // Shadows
  static List<BoxShadow> get shadow1 => const [
        BoxShadow(
          color: Color(0x2E000000), // rgba(0,0,0,0.18)
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ];

  static List<BoxShadow> get shadow2 => const [
        BoxShadow(
          color: Color(0x47000000), // rgba(0,0,0,0.28)
          offset: Offset(0, 8),
          blurRadius: 30,
        ),
      ];

  static List<BoxShadow> get shadowPop => const [
        BoxShadow(
          color: Color(0x66000000), // rgba(0,0,0,0.40)
          offset: Offset(0, 18),
          blurRadius: 50,
        ),
      ];
}
