import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../popups/snackbars.dart';
import 'package:flutter/material.dart' show IconData, Icons;


class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();

  /// Current connection status — reactive for UI
  final Rx<ConnectivityResult> connectionStatus =
      ConnectivityResult.none.obs;

  /// Whether currently online (any non-none result)
  final RxBool isOnline = false.obs;

  /// Whether this is first check (skip "Back Online" on launch)
  bool _isFirstCheck = true;

  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    // Initial check
    _checkInitialConnection();
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }

  // ============ PUBLIC API ============

  /// Check if device is currently connected to internet
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final connected =
          results.any((r) => r != ConnectivityResult.none);
      isOnline.value = connected;
      return connected;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Guard an async operation — runs only if online, else shows snackbar
  ///
  /// Usage:
  /// ```dart
  /// final result = await NetworkManager.instance.guard(
  ///   () => api.fetchChildData(),
  ///   onError: 'Cannot fetch data offline',
  /// );
  /// ```
  Future<T?> guard<T>(
    Future<T> Function() action, {
    String onError = 'No internet connection',
    bool showSnackbar = true,
  }) async {
    if (!await isConnected()) {
      if (showSnackbar) {
        USnackBarHelpers.networkOfflineSnackBar();
      }
      return null;
    }

    try {
      return await action();
    } catch (e) {
      rethrow;
    }
  }

  /// Get human-readable connection type
  String getConnectionTypeLabel() {
    switch (connectionStatus.value) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return 'Offline';
      default:
        return 'Unknown';
    }
  }

  /// Get connection icon
  IconData get _connectionIcon {
    switch (connectionStatus.value) {
      case ConnectivityResult.wifi:
        return Icons.wifi;
      case ConnectivityResult.mobile:
        return Icons.signal_cellular_4_bar;
      case ConnectivityResult.ethernet:
        return Icons.lan;
      case ConnectivityResult.none:
        return Icons.wifi_off;
      default:
        return Icons.cloud_off;
    }
  }

  // ============ PRIVATE ============

  Future<void> _checkInitialConnection() async {
    final connected = await isConnected();
    isOnline.value = connected;
    _isFirstCheck = false;
  }

  Future<void> _updateConnectionStatus(
    List<ConnectivityResult> results,
  ) async {
    if (results.isEmpty) {
      connectionStatus.value = ConnectivityResult.none;
      isOnline.value = false;
      return;
    }

    final primary = results.first;
    final wasOnline = isOnline.value;
    final nowOnline = primary != ConnectivityResult.none;

    connectionStatus.value = primary;
    isOnline.value = nowOnline;

    // Skip notifications on first check
    if (_isFirstCheck) {
      _isFirstCheck = false;
      return;
    }

    // Online → offline: show warning
    if (wasOnline && !nowOnline) {
      USnackBarHelpers.networkOfflineSnackBar();
    }
    // Offline → online: show restored
    else if (!wasOnline && nowOnline) {
      USnackBarHelpers.networkRestoredSnackBar();
    }
  }
}


