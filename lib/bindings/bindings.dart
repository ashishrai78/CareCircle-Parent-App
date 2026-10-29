
import 'package:get/get.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../utils/helpers/network_manager.dart';

class UBindings extends Bindings{
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.put(UserController(), permanent: true);
  }
}