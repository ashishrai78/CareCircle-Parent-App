import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 📱 CareCircle — Production Device Helper
///
/// Utility functions for device-related operations:
///  - Keyboard hide/show
///  - Status bar customization
///  - Orientation detection (FIXED)
///  - Screen dimensions
///  - Full screen mode
///  - Vibration feedback
class UDeviceHelper {
  UDeviceHelper._();

  // ============ KEYBOARD ============

  /// Hide the on-screen keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  /// Check if keyboard is currently visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get keyboard height (0 if not visible)
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // ============ STATUS BAR ============

  /// Set status bar color and icon brightness
  static Future<void> setStatusBarColor(
    Color color, {
    Brightness? iconBrightness,
  }) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness:
            iconBrightness ?? _getIconBrightnessForColor(color),
        statusBarBrightness:
            iconBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// Hide status bar (immersive mode)
  static Future<void> hideStatusBar() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Show status bar
  static Future<void> showStatusBar() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ============ ORIENTATION (FIXED) ============

  /// ✅ FIX: Properly checks orientation using MediaQuery (was using viewInsets)
  static bool isLandscapeOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// ✅ FIX: Properly checks orientation
  static bool isPortraitOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Lock to portrait orientation
  static Future<void> setPortraitOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  /// Lock to landscape orientation
  static Future<void> setLandscapeOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Allow all orientations
  static Future<void> setAllOrientations() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  // ============ SCREEN DIMENSIONS ============

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen aspect ratio (width / height)
  static double getAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  /// Check if device is a tablet (shortest side >= 600dp)
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  // ============ APP BAR ============

  /// Get standard AppBar height (kToolbarHeight = 56.0)
  static double getAppBarHeight() {
    return kToolbarHeight;
  }

  /// Get bottom navigation bar height
  static double getBottomNavigationBarHeight() {
    return kBottomNavigationBarHeight;
  }

  // ============ FULL SCREEN ============

  /// Toggle full screen (immersive) mode
  static Future<void> setFullScreen(bool enable) async {
    await SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  // ============ HAPTIC FEEDBACK ============

  /// Light impact — for button taps
  static void hapticLight() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact — for toggles, switches
  static void hapticMedium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact — for significant actions
  static void hapticHeavy() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click — for picking items
  static void hapticSelection() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate — for errors / warnings
  static void hapticVibrate() {
    HapticFeedback.vibrate();
  }

  // ============ DEVICE INFO ============

  /// Get pixel ratio
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Get platform brightness (light/dark)
  static Brightness getPlatformBrightness(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }

  /// Check if device is in dark mode
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // ============ PRIVATE HELPERS ============

  /// Auto-detect icon brightness based on background color luminance
  static Brightness _getIconBrightnessForColor(Color color) {
    // Using standard luminance formula
    // If color is light → dark icons; if dark → light icons
    return color.computeLuminance() > 0.5
        ? Brightness.dark
        : Brightness.light;
  }
}
