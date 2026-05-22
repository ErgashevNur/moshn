import 'package:flutter/cupertino.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  AppTheme._();

  static CupertinoThemeData light = const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.surface,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.label,
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        color: AppColors.label,
        letterSpacing: -0.41,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.label,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.label,
      ),
      navActionTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        color: AppColors.primary,
      ),
      tabLabelTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 10,
        letterSpacing: -0.24,
      ),
      actionTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        color: AppColors.primary,
      ),
    ),
  );

  static CupertinoThemeData dark = const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    barBackgroundColor: AppColors.surfaceDark,
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.labelDark,
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        color: AppColors.labelDark,
        letterSpacing: -0.41,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.labelDark,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: AppColors.labelDark,
      ),
      navActionTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        color: AppColors.primary,
      ),
      tabLabelTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 10,
        letterSpacing: -0.24,
      ),
      actionTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 17,
        color: AppColors.primary,
      ),
    ),
  );
}
