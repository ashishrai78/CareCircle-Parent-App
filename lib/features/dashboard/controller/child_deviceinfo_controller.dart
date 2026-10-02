import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/child_live_data_model.dart';
import '../../../data/repositories/features/child_data_repository.dart';
import '../../../utils/popups/snackbars.dart';

/// 📍 ChildDeviceInfoController — manages child's live data (location, battery, etc.)
///
/// Production improvements:
///  ✅ Takes childUid via constructor (not GetStorage)
///  ✅ Uses repository pattern (no direct Firestore calls)
///  ✅ Real-time stream (auto-cancels on close)
///  ✅ Triggers sync_request on init (fresh data)
///  ✅ Mic listening via repository (clean separation)
class ChildDeviceInfoController extends GetxController {
  ChildDeviceInfoController({required this.childUid});

  final String childUid;

  final ChildDataRepository _repository = ChildDataRepository();

  // ============ Reactive State ============
  final Rx<ChildLiveDataModel?> childData = Rx<ChildLiveDataModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  // ============ Current Active App Getters ============
  bool get isUsingApp => data?.isUsingApp ?? false;
  String get currentAppStatus => data?.currentAppStatus ?? 'Unknown';
  String get currentAppEmoji => data?.currentAppEmoji ?? '📱';
  String get currentAppName => data?.currentAppName ?? 'Idle';

  int get currentAppSecondsAgo => data?.currentAppSecondsAgo ?? 0;
  StreamSubscription<ChildLiveDataModel?>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _initStream();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Initialize real-time stream + request fresh data
  Future<void> _initStream() async {
    try {
      // Request fresh data from child
      await _repository.requestSync(childUid);

      // Listen to live data
      _subscription = _repository.streamChildLiveData(childUid).listen(
        (data) {
          childData.value = data;
          error.value = '';
          isLoading.value = false;
          isRefreshing.value = false;
        },
        onError: (err) {
          error.value = 'Error loading data: $err';
          isLoading.value = false;
          isRefreshing.value = false;
        },
      );
    } catch (e) {
      error.value = 'Failed to connect: $e';
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Manual refresh
  Future<void> refreshData() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      await _repository.requestSync(childUid);
      USnackBarHelpers.infoSnackBar(
        title: 'Sync Requested',
        message: 'Asking child device for fresh data...',
      );
    } catch (e) {
      USnackBarHelpers.errorSnackBar(
        title: 'Sync Failed',
        message: e.toString(),
      );
      isRefreshing.value = false;
    }
  }

  // ============ Computed Properties for UI ============

  ChildLiveDataModel? get data => childData.value;

  bool get isOnline => data?.isOnline ?? false;

  String get onlineStatus => data?.onlineStatus ?? 'Offline';

  String get deviceName => data?.device ?? 'Unknown Device';

  String get lastUpdated => data?.lastUpdatedFormatted ?? 'Never';

  // Battery
  String get batteryPercentage => '${data?.battery ?? 0}%';

  String get batteryStatusText => data?.batteryStatusText ?? 'Unknown';

  Color get batteryStatusColor => Color(data?.batteryColorValue ?? 0xFF9E9E9E);

  bool get isCharging => data?.isCharging ?? false;

  // Location
  bool get hasLocation => data?.hasLocation ?? false;

  double? get latitude => data?.lat;

  double? get longitude => data?.lng;

  String get locationStatus {
    if (!hasLocation) return 'Location unavailable';
    if (data?.locationServiceOn == false) {
      return 'Last Known Location (GPS OFF)';
    }
    if (data?.isCached == true) {
      return 'Last Known Location';
    }
    return 'Location available';
  }

  String? get address => data?.address;

  bool get isMockLocation => data?.isMock ?? false;

  // Network
  String get networkType => data?.networkType ?? 'Unknown';

  String get carrier => data?.carrier ?? '';

  bool get hasInternet => data?.hasInternet ?? false;

  // Device
  String get osVersion => data?.osVersion ?? 'Unknown';

  bool get isRooted => data?.rooted ?? false;
}
