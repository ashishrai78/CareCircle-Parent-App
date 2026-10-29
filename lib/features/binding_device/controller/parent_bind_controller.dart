import 'package:carecircle_parent1/data/repositories/authentication/authentication_repository.dart';
import 'package:carecircle_parent1/data/repositories/user/user_repository.dart';
import 'package:carecircle_parent1/features/personalization/controllers/user_controller.dart';
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

  // Function to link child to parent in Firestore
  Future<void> updateChildOrParent(String parentUid, String childUid) async {
    await _db.collection('Users').doc(parentUid).update({
      'linkedChildren': FieldValue.arrayUnion([childUid]),
    });

    await _db.collection('Users').doc(childUid).update({
      'parentUid': parentUid,
      'isPaired': true,
      'lastParentSync': FieldValue.serverTimestamp(),
    });
  }

  // Function to bind child device
  Future<void> bindParentToChild(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty || cleanCode.length < 6) {
      USnackBarHelpers.warningSnackBar(
        title: 'Enter Valid Code',
        message: 'Please enter the complete 6-digit code shown on the child device.',
      );
      return;
    }

    try {
      isLoading.value = true;
      final currentParentUid = AuthenticationRepository.instance.currentUser?.uid;
      if (currentParentUid == null) {
        USnackBarHelpers.errorSnackBar(
          title: 'Not Logged In',
          message: 'Please log in to link a child device.',
        );
        return;
      }

      final childDoc = await UserRepository.instance.findChildByCode(cleanCode);

      if (childDoc == null || !childDoc.exists) {
        USnackBarHelpers.errorSnackBar(
          title: 'Invalid Code',
          message: 'No child device found with code "$cleanCode". Please check and try again.',
        );
        return;
      }

      final childData = childDoc.data() as Map<String, dynamic>? ?? {};
      final String childUid = childDoc.id;
      final String childName = childData['name'] ?? 'Child Device';
      final bool isPaired = childData['isPaired'] ?? false;
      final String existingParentUid = childData['parentUid'] ?? '';
      final Timestamp? lastSync = childData['lastParentSync'] as Timestamp?;

      if (isPaired) {
        // Case 1: Re-linking same child to current parent
        if (existingParentUid == currentParentUid) {
          await updateChildOrParent(currentParentUid, childUid);
          GetStorage().write('childUid', childUid);
          GetStorage().write('isBind', true);

          if (Get.isRegistered<UserController>()) {
            await UserController.instance.fetchUserDetails();
          }

          USnackBarHelpers.successSnackBar(
            title: 'Already Linked',
            message: '$childName is already paired with your account.',
          );
          Get.offAll(() => ParentDashboardScreen(childUid: childUid, childName: childName));
          return;
        }

        // Case 2: Check 1-week (7 days) parent inactivity timeout
        bool isInactive7Days = false;
        if (lastSync == null) {
          isInactive7Days = true;
        } else {
          final diff = DateTime.now().difference(lastSync.toDate());
          if (diff.inDays >= 7) {
            isInactive7Days = true;
          }
        }

        if (isInactive7Days) {
          // Device had no sync for 7+ days — auto-unbind old parent and transfer to this parent
          await _db.collection('Users').doc(childUid).update({
            'parentUid': currentParentUid,
            'isPaired': true,
            'lastParentSync': FieldValue.serverTimestamp(),
          });

          await _db.collection('Users').doc(currentParentUid).update({
            'linkedChildren': FieldValue.arrayUnion([childUid]),
          });

          if (existingParentUid.isNotEmpty) {
            await _db.collection('Users').doc(existingParentUid).update({
              'linkedChildren': FieldValue.arrayRemove([childUid]),
            }).catchError((_) {});
          }

          GetStorage().write('childUid', childUid);
          GetStorage().write('isBind', true);

          if (Get.isRegistered<UserController>()) {
            await UserController.instance.fetchUserDetails();
          }

          USnackBarHelpers.successSnackBar(
            title: 'Device Recovered & Linked',
            message: 'Device was inactive for 7+ days and has now been transferred to your account.',
          );
          Get.offAll(() => ParentDashboardScreen(childUid: childUid, childName: childName));
          return;
        } else {
          USnackBarHelpers.warningSnackBar(
            title: 'Device Already Paired',
            message: 'This device is currently linked to another parent. (If inactive for 7 days, it will reset automatically).',
          );
          return;
        }
      }

      // Fresh Pairing
      await updateChildOrParent(currentParentUid, childUid);

      GetStorage().write('childUid', childUid);
      GetStorage().write('isBind', true);

      if (Get.isRegistered<UserController>()) {
        await UserController.instance.fetchUserDetails();
      }

      USnackBarHelpers.successSnackBar(
        title: 'Device Linked Successfully',
        message: '$childName has been connected to your CareCircle account.',
      );

      Get.offAll(() => ParentDashboardScreen(childUid: childUid, childName: childName));

    } catch(e){
      USnackBarHelpers.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
