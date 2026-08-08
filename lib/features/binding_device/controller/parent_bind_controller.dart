import 'package:carecircle_parent1/data/repositories/authentication/authentication_repository.dart';
import 'package:carecircle_parent1/data/repositories/user/user_repository.dart';
import 'package:carecircle_parent1/utils/popups/snackbars.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../../dashboard/screens/parent_dashboard_screen.dart';

class ParentBindController extends GetxController {
  static ParentBindController get instance => Get.find();

  /// Variables
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  RxBool isLoading = false.obs;


  // function to update that's child bind or not bind
  Future<void> updateChildOrParent(String parentUid, String childUid,) async {
    await _db.collection('Users').doc(parentUid).update({'linkedChildren': FieldValue.arrayUnion([childUid]),});

    await _db.collection('Users').doc(childUid).update({'parentUid': parentUid, 'isPaired': true,});
  }


  // function to binding child
  Future<void> bindParentToChild(String code) async{
    try{
      isLoading.value = true;
      final childDoc = await UserRepository.instance.findChildByCode(code);
      GetStorage().write('childUid', childDoc?.id);

      if (childDoc == null) {USnackBarHelpers.errorSnackBar(title: 'Error', message: 'Invalid code');
        return;
      }

      if(childDoc.id.isNotEmpty){
        bool isPaired = childDoc['isPaired'];
        if(isPaired == true) {
          USnackBarHelpers.warningSnackBar(title: 'Child device already Bind!');
          return;
        }
      }

      await updateChildOrParent(AuthenticationRepository.instance.currentUser!.uid, childDoc.id);

      GetStorage().write('isBind', true);

      Get.offAll(() => ParentDashboardScreen(childUid: childDoc.id, childName:'Ashish'));

    } catch(e){
      USnackBarHelpers.errorSnackBar(title: 'Error', message: e.toString());
    }finally{
      isLoading.value = false;
    }
  }
}
