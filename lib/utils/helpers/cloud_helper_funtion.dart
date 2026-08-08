import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

/// ☁️ CareCircle — Production Cloud Helper Functions
///
/// Provides reusable widgets for handling async snapshot states:
///  - Loading (spinner / custom loader)
///  - Error (default / custom error)
///  - Empty (default / custom empty)
///  - Success (returns null — let caller build content)
///
/// Usage:
/// ```dart
/// StreamBuilder(
///   stream: myStream,
///   builder: (context, snapshot) {
///     final state = UCloudHelperFunctions.checkSingleRecordState<MyData>(snapshot);
///     if (state != null) return state;
///     // Build success UI with snapshot.data!
///     return MyContentWidget(data: snapshot.data!);
///   },
/// )
/// ```
class UCloudHelperFunctions {
  UCloudHelperFunctions._();

  // ============ SINGLE RECORD STATE ============

  /// Check state for single-record snapshots (DocumentSnapshot, Future, etc.)
  ///
  /// Returns a Widget if in loading/error/empty state, null if success.
  static Widget? checkSingleRecordState<T>(
    AsyncSnapshot<T> snapshot, {
    Widget? loader,
    Widget? error,
    Widget? nothingFound,
  }) {
    // ✅ FIX: Check error FIRST (was last before — caused "No Data" misleading)
    if (snapshot.hasError) {
      return error ??
          _defaultErrorWidget(snapshot.error.toString());
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return loader ?? _defaultLoader();
    }

    if (!snapshot.hasData || snapshot.data == null) {
      return nothingFound ?? _defaultEmptyWidget('No Data Found');
    }

    return null;
  }

  // ============ MULTI RECORD STATE ============

  /// Check state for list snapshots (CollectionSnapshot, etc.)
  ///
  /// Returns a Widget if in loading/error/empty state, null if success.
  static Widget? checkMultiRecordState<T>({
    required AsyncSnapshot<List<T>> snapshot,
    Widget? loader,
    Widget? error,
    Widget? nothingFound,
  }) {
    // ✅ FIX: Check error FIRST
    if (snapshot.hasError) {
      return error ??
          _defaultErrorWidget(snapshot.error.toString());
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return loader ?? _defaultLoader();
    }

    if (!snapshot.hasData ||
        snapshot.data == null ||
        snapshot.data!.isEmpty) {
      return nothingFound ?? _defaultEmptyWidget('No Data Found');
    }

    return null;
  }

  // ============ STREAM + SEPARATE LOADING FLAG ============

  /// For cases where loading state is tracked separately (e.g., refresh button)
  static Widget? checkStateWithLoadingFlag<T>({
    required AsyncSnapshot<T> snapshot,
    required bool isLoading,
    Widget? loader,
    Widget? error,
    Widget? nothingFound,
  }) {
    if (snapshot.hasError) {
      return error ?? _defaultErrorWidget(snapshot.error.toString());
    }

    if (isLoading || snapshot.connectionState == ConnectionState.waiting) {
      return loader ?? _defaultLoader();
    }

    if (!snapshot.hasData || snapshot.data == null) {
      return nothingFound ?? _defaultEmptyWidget('No Data Found');
    }

    return null;
  }

  // ============ DEFAULT WIDGETS ============

  static Widget _defaultLoader() {
    return const Center(
      child: CircularProgressIndicator(color: UColors.primary),
    );
  }

  static Widget _defaultErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: UColors.error,
            ),
            const SizedBox(height: USizes.md),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: UColors.textPrimary,
              ),
            ),
            const SizedBox(height: USizes.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: UColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _defaultEmptyWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: UColors.textTertiary,
            ),
            const SizedBox(height: USizes.md),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: UColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔄 Separated LoadingState enum for cleaner code
enum LoadingState { idle, loading, success, error, empty }
