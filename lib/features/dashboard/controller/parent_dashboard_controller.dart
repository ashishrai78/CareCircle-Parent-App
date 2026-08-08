import 'package:get/get.dart';
import 'child_deviceinfo_controller.dart';
import 'installed_apps_controller.dart';
import 'screen_time_controller.dart';

/// 🎯 ParentDashboardController — orchestrates all dashboard controllers
///
/// Initializes all child controllers with the same childUid.
/// Used by ParentDashboardBinding for DI.
class ParentDashboardController extends GetxController {
  ParentDashboardController({required this.childUid});

  final String childUid;

  late final ChildDeviceInfoController deviceInfoController;
  late final ScreenTimeController screenTimeController;
  late final InstalledAppsController installedAppsController;

  @override
  void onInit() {
    super.onInit();

    // Initialize all sub-controllers with the same childUid
    deviceInfoController = Get.put(
      ChildDeviceInfoController(childUid: childUid),
      tag: 'dashboard_$childUid',
    );

    screenTimeController = Get.put(
      ScreenTimeController(childUid: childUid),
      tag: 'dashboard_$childUid',
    );

    installedAppsController = Get.put(
      InstalledAppsController(childUid: childUid),
      tag: 'dashboard_$childUid',
    );
  }

  @override
  void onClose() {
    Get.delete<ChildDeviceInfoController>(tag: 'dashboard_$childUid');
    Get.delete<ScreenTimeController>(tag: 'dashboard_$childUid');
    Get.delete<InstalledAppsController>(tag: 'dashboard_$childUid');
    super.onClose();
  }
}
