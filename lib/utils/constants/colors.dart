import 'package:flutter/material.dart';

class UColors {
  UColors._();

  // ============ BRAND COLORS ============
  /// Primary brand color — warm orange (main CTAs, active states)
  static const Color primary = Color(0xFFFBAB57);

  /// Secondary brand color — lighter orange (highlights, gradients)
  static const Color secondary = Color(0xFFFEC674);

  /// Accent color — trust blue (links, info icons, secondary buttons)
  static const Color accent = Color(0xFF0857A0);

  // ============ TEXT COLORS ============
  /// Primary text color — for headings and important content
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Secondary text color — for descriptions, captions
  static const Color textSecondary = Color(0xFF6C757D);

  /// Tertiary text color — for hints, placeholders
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// White text — for dark backgrounds
  static const Color textWhite = Color(0xFFFFFFFF);

  // ============ BACKGROUND COLORS ============
  /// Main app background — warm cream (softer than pure white)
  static const Color light = Color(0xFFFFF8F0);

  /// Pure white — for cards, surfaces
  static const Color white = Color(0xFFFFFFFF);

  /// Dark background — for dark mode (future use)
  static const Color dark = Color(0xFF1A1A1A);

  /// Darker surface — for dark mode cards (future use)
  static const Color darkContainer = Color(0xFF2A2A2A);

  // ============ BUTTON COLORS ============
  /// Primary button background
  static const Color buttonPrimary = Color(0xFFFBAB57);

  /// Secondary button background (outlined)
  static const Color buttonSecondary = Color(0xFF0857A0);

  /// Disabled button background
  static const Color buttonDisabled = Color(0xFFE0E0E0);

  // ============ BORDER COLORS ============
  /// Primary border — for inputs, cards
  static const Color borderPrimary = Color(0xFFE5E7EB);

  /// Secondary border — for dividers, subtle separators
  static const Color borderSecondary = Color(0xFFF3F4F6);

  /// Focus border — for active inputs
  static const Color borderFocus = Color(0xFFFBAB57);

  // ============ SEMANTIC COLORS ============
  /// Success — green (positive actions, online status)
  static const Color success = Color(0xFF2E7D32);

  /// Success background — light green
  static const Color successBg = Color(0xFFE8F5E9);

  /// Warning — amber (cautions, pending states)
  static const Color warning = Color(0xFFED6C02);

  /// Warning background — light amber
  static const Color warningBg = Color(0xFFFFF3E0);

  /// Error — red (failures, destructive actions)
  static const Color error = Color(0xFFD32F2F);

  /// Error background — light red
  static const Color errorBg = Color(0xFFFFEBEE);

  /// Info — blue (informational, tips)
  static const Color info = Color(0xFF0288D1);

  /// Info background — light blue
  static const Color infoBg = Color(0xFFE1F5FE);

  // ============ STATUS COLORS ============
  /// Online status — green dot
  static const Color online = Color(0xFF4CAF50);

  /// Offline status — grey dot
  static const Color offline = Color(0xFF9E9E9E);

  /// Recording / listening — red dot
  static const Color recording = Color(0xFFEF4444);

  // ============ NEUTRAL SHADES ============
  static const Color black = Color(0xFF1A1A1A);
  static const Color darkerGrey = Color(0xFF374151);
  static const Color darkGrey = Color(0xFF6B7280);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color transparent = Color(0x00000000);

  // ============ OVERLAY COLORS ============
  /// Scrim for dialogs, bottom sheets — 50% black
  static const Color scrim = Color(0x80000000);

  /// Splash color — for InkWell tap feedback
  static const Color splash = Color(0x1A000000);

  /// Highlight color — for InkWell press feedback
  static const Color highlight = Color(0x0D000000);

  // ============ GRADIENTS ============
  /// Primary gradient — warm orange (for headers, CTAs)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBAB57), Color(0xFFFEC674)],
  );

  /// Accent gradient — trust blue (for info cards)
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0857A0), Color(0xFF1976D2)],
  );

  /// Dark gradient — for onboarding headers
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF374151)],
  );

  /// Yellow — for specific highlights
  static const Color yellow = Color(0xFFFFE24B);
}
