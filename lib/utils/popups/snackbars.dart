import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

/// 🔔 CareCircle — Production SnackBar Helpers
///
/// Centralized snackbar/notification system with proper semantic colors.
/// All snackbars use Nunito font + consistent styling.
class USnackBarHelpers {
  USnackBarHelpers._();

  // ============ BASIC SNACKBARS ============

  /// Success snackbar — green
  static void successSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: UColors.textWhite,
      backgroundColor: UColors.success,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(USizes.md),
      borderRadius: USizes.borderRadiusMd,
      icon: const Icon(Icons.check_circle_outline, color: UColors.textWhite),
      barBlur: 0,
      overlayBlur: 0,
    );
  }

  /// Warning snackbar — amber
  static void warningSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: UColors.textWhite,
      backgroundColor: UColors.warning,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(USizes.md),
      borderRadius: USizes.borderRadiusMd,
      icon: const Icon(Icons.warning_amber_rounded, color: UColors.textWhite),
      barBlur: 0,
      overlayBlur: 0,
    );
  }

  /// Error snackbar — red
  static void errorSnackBar({
    required String title,
    String message = '',
    int duration = 4,
  }) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: UColors.textWhite,
      backgroundColor: UColors.error,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(USizes.md),
      borderRadius: USizes.borderRadiusMd,
      icon: const Icon(Icons.error_outline, color: UColors.textWhite),
      barBlur: 0,
      overlayBlur: 0,
    );
  }

  /// Info snackbar — blue
  static void infoSnackBar({
    required String title,
    String message = '',
    int duration = 3,
  }) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: UColors.textWhite,
      backgroundColor: UColors.info,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(USizes.md),
      borderRadius: USizes.borderRadiusMd,
      icon: const Icon(Icons.info_outline, color: UColors.textWhite),
      barBlur: 0,
      overlayBlur: 0,
    );
  }

  // ============ SPECIAL SNACKBARS ============

  /// Network offline warning — amber, no auto-dismiss
  static void networkOfflineSnackBar() {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      'No Internet Connection',
      'Please check your network and try again',
      isDismissible: false,
      shouldIconPulse: true,
      colorText: UColors.textWhite,
      backgroundColor: UColors.warning,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(USizes.md),
      borderRadius: USizes.borderRadiusMd,
      icon: const Icon(Icons.wifi_off, color: UColors.textWhite),
      barBlur: 0,
      overlayBlur: 0,
    );
  }

  /// Network restored — green
  static void networkRestoredSnackBar() {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      'Back Online',
      'Your internet connection has been restored',
      isDismissible: true,
      shouldIconPulse: true,
      colorText: UColors.textWhite,
      backgroundColor: UColors.success,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(USizes.md),
      borderRadius: USizes.borderRadiusMd,
      icon: const Icon(Icons.wifi, color: UColors.textWhite),
      barBlur: 0,
      overlayBlur: 0,
    );
  }

  /// Custom toast — neutral grey, centered
  static void customToast({required String message}) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.all(USizes.md),
          margin: const EdgeInsets.symmetric(horizontal: USizes.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
            color: UColors.darkerGrey.withValues(alpha: 0.95),
          ),
          child: Center(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: UColors.textWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ DIALOGS ============

  /// Success dialog with checkmark animation
  static Future<void> successDialog({
    required String title,
    String message = '',
    String buttonText = 'OK',
    VoidCallback? onTap,
  }) async {
    await Get.dialog(
      AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: UColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: UColors.success,
            size: 40,
          ),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                onTap?.call();
              },
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  /// Error dialog with X icon
  static Future<void> errorDialog({
    required String title,
    String message = '',
    String buttonText = 'OK',
    VoidCallback? onTap,
  }) async {
    await Get.dialog(
      AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: UColors.errorBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: UColors.error,
            size: 40,
          ),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                onTap?.call();
              },
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmation dialog (Yes/No)
  static Future<bool> confirmDialog({
    required String title,
    String message = '',
    String confirmText = 'Yes',
    String cancelText = 'No',
    bool isDestructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: isDestructive
                ? ElevatedButton.styleFrom(backgroundColor: UColors.error)
                : null,
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Loading dialog (non-dismissible)
  static void showLoadingDialog({String message = 'Loading...'}) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(color: UColors.primary),
              const SizedBox(width: USizes.md),
              Text(message),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
