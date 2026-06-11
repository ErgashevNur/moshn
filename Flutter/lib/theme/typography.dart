import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.sora(
        fontSize: 29,
        fontWeight: FontWeight.w700,
        letterSpacing: 29 * -0.03,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.sora(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        letterSpacing: 27 * -0.03,
        height: 1.1,
      );

  static TextStyle get displaySmall => GoogleFonts.sora(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 26 * -0.03,
        height: 1.1,
      );

  static TextStyle get titleLarge => GoogleFonts.sora(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: 25 * -0.03,
        height: 1.15,
      );

  static TextStyle get titleMedium => GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 24 * -0.03,
        height: 1.15,
      );

  static TextStyle get appbarTitle => GoogleFonts.sora(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: 19 * -0.02,
        height: 1.2,
      );

  static TextStyle get titleSmall => GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 18 * -0.02,
        height: 1.2,
      );

  static TextStyle get bodyLarge => GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 16 * -0.011,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.sora(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 15 * -0.011,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.sora(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get body => GoogleFonts.sora(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 14 * -0.011,
        height: 1.45,
      );

  static TextStyle get labelLarge => GoogleFonts.sora(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 16 * -0.01,
        height: 1.2,
      );

  static TextStyle get labelMedium => GoogleFonts.sora(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  static TextStyle get labelSmall => GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 12 * 0.07,
        height: 1.3,
      );

  // labelSmall text already uppercase — caller must apply TextTransform or toUpperCase()
  static TextStyle get eyebrow => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 11 * 0.12,
        height: 1.3,
      );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // Convenience sizes for inline use
  static TextStyle soraSize(double size,
          {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.sora(fontSize: size, fontWeight: weight);
}
