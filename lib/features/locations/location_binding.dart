import 'package:get/get.dart';

import 'controllers/location_controller.dart';


/// 🔗 LocationBinding — DI setup for LocationMapScreen
///
/// Usage:
/// ```dart
/// Get.to(() => LocationMapScreen(childUid: childUid), binding: LocationBinding(childUid: childUid));
/// ```
class LocationBinding extends Bindings {
  LocationBinding({required this.childUid});

  final String childUid;

  @override
  void dependencies() {
    if (!Get.isRegistered<LocationController>()) {
      Get.put(LocationController(childUid: childUid));
    }
  }
}
