import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';

/// 📝 CareCircle — Production Text Theme
///
/// Uses Nunito font family (defined in pubspec.yaml).
/// Hierarchical typography scale following Material Design 3.
class UTextTheme {
  UTextTheme._();

  /// Font family — must match pubspec.yaml
  static const String fontFamily = 'Nunito';

  /// ✅ LIGHT TEXT THEME
  static TextTheme lightTextTheme = TextTheme(
    // Display — for large hero numbers (e.g., "12h 30m" screen time)
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.0,
      fontWeight: FontWeight.w800,
      color: UColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      color: UColors.textPrimary,
      letterSpacing: -0.25,
    ),

    // Headline — for screen titles, large headers
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      color: UColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: UColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: UColors.textPrimary,
    ),

    // Title — for card titles, section headers
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.w700,
      color: UColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15.0,
      fontWeight: FontWeight.w600,
      color: UColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: UColors.textPrimary,
    ),

    // Body — for main content text
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      color: UColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: UColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      color: UColors.textSecondary,
    ),

    // Label — for buttons, captions, badges
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.w700,
      color: UColors.textPrimary,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: UColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 10.0,
      fontWeight: FontWeight.w500,
      color: UColors.textTertiary,
      letterSpacing: 0.5,
    ),
  );

  /// ✅ DARK TEXT THEME (for future dark mode support)
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32.0,
      fontWeight: FontWeight.w800,
      color: UColors.textWhite,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28.0,
      fontWeight: FontWeight.w700,
      color: UColors.textWhite,
      letterSpacing: -0.25,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
      color: UColors.textWhite,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: UColors.textWhite,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: UColors.textWhite,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16.0,
      fontWeight: FontWeight.w700,
      color: UColors.textWhite,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15.0,
      fontWeight: FontWeight.w600,
      color: UColors.textWhite,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: UColors.textWhite,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      color: UColors.textWhite,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: UColors.textWhite,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.0,
      fontWeight: FontWeight.w400,
      color: UColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14.0,
      fontWeight: FontWeight.w700,
      color: UColors.textWhite,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: UColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 10.0,
      fontWeight: FontWeight.w500,
      color: UColors.textTertiary,
      letterSpacing: 0.5,
    ),
  );
}
