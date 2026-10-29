import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/popups/snackbars.dart';
import '../../authentication/models/user_model.dart';
import '../../binding_device/screens/parent_bind_screen.dart';
import '../../personalization/controllers/user_controller.dart';
import '../screens/parent_dashboard_screen.dart';

/// 📱 Data model for a connected child in the drawer
class ConnectedChildInfo {
  final String uid;
  final String name;
  final String device;
  final int battery;
  final bool isOnline;
  final bool isCharging;
  final String childCode;

  ConnectedChildInfo({
    required this.uid,
    required this.name,
    this.device = 'Mobile Device',
    this.battery = 0,
    this.isOnline = false,
    this.isCharging = false,
    this.childCode = '',
  });
}

/// 🎯 ParentDrawerController — manages connected children list, switching, and unlinking
class ParentDrawerController extends GetxController {
  static ParentDrawerController get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<ConnectedChildInfo> childrenList = <ConnectedChildInfo>[].obs;
  final RxBool isLoading = true.obs;
  final Rx<AppUserModel> parentUser = AppUserModel.empty().obs;

  StreamSubscription<DocumentSnapshot>? _parentDocSubscription;
  final Map<String, StreamSubscription<DocumentSnapshot>> _childSubscriptions = {};

  @override
  void onInit() {
    super.onInit();
    initParentAndChildren();
  }

  @override
  void onClose() {
    _parentDocSubscription?.cancel();
    for (final sub in _childSubscriptions.values) {
      sub.cancel();
    }
    _childSubscriptions.clear();
    super.onClose();
  }

  /// Initialize real-time listener for parent document and linked children
  void initParentAndChildren() {
    final parentUid = AuthenticationRepository.instance.currentUser?.uid;
    if (parentUid == null) {
      isLoading.value = false;
      return;
    }

    // Listen to parent user document in real time
    _parentDocSubscription = _db
        .collection('Users')
        .doc(parentUid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        parentUser.value = AppUserModel.fromSnapshot(snapshot);
        final List<String> linkedIds = parentUser.value.linkedChildren;
        _listenToChildren(linkedIds);
      } else {
        isLoading.value = false;
      }
    }, onError: (e) {
      debugPrint("🔥 Parent doc listen error: $e");
      isLoading.value = false;
    });
  }

  /// Listen to each child's data in real time
  void _listenToChildren(List<String> childUids) {
    if (childUids.isEmpty) {
      childrenList.clear();
      isLoading.value = false;
      return;
    }

    // Cancel old subscriptions that are no longer linked
    final currentKeys = _childSubscriptions.keys.toList();
    for (final key in currentKeys) {
      if (!childUids.contains(key)) {
        _childSubscriptions[key]?.cancel();
        _childSubscriptions.remove(key);
      }
    }

    // Temporary map to build child list
    final Map<String, ConnectedChildInfo> childMap = {};

    for (final childUid in childUids) {
      if (!_childSubscriptions.containsKey(childUid)) {
        // Stream child user info + live data
        _childSubscriptions[childUid] = _db
            .collection('Users')
            .doc(childUid)
            .snapshots()
            .listen((userDoc) async {
          final userData = userDoc.data() ?? {};
          final name = userData['name'] ?? 'Child Device';
          final childCode = userData['childCode'] ?? '';

          // Fetch or stream live data
          try {
            final liveDoc = await _db.collection('child_live_data').doc(childUid).get();
            final liveData = liveDoc.data() ?? {};
            final device = liveData['device'] as String? ?? 'Android Device';
            final battery = (liveData['battery'] as num?)?.toInt() ?? 0;
            final isCharging = liveData['isCharging'] as bool? ?? false;

            final heartbeat = (liveData['heartbeat'] as Timestamp?)?.toDate();
            bool isOnline = false;
            if (heartbeat != null) {
              isOnline = DateTime.now().difference(heartbeat).inMinutes < 5;
            }

            childMap[childUid] = ConnectedChildInfo(
              uid: childUid,
              name: name,
              device: device,
              battery: battery,
              isOnline: isOnline,
              isCharging: isCharging,
              childCode: childCode,
            );

            // Rebuild reactive children list preserving parent order
            final List<ConnectedChildInfo> ordered = [];
            for (final id in childUids) {
              if (childMap.containsKey(id)) {
                ordered.add(childMap[id]!);
              }
            }
            childrenList.assignAll(ordered);
            isLoading.value = false;
          } catch (e) {
            debugPrint("Child live data fetch error: $e");
          }
        });
      }
    }
  }

  /// Switch active child on Dashboard
  void switchActiveChild(String childUid, String childName, String currentChildUid) {
    if (childUid == currentChildUid) {
      Get.back(); // already active, just close drawer
      return;
    }

    GetStorage().write('childUid', childUid);
    Get.back(); // close drawer

    // Cleanly re-route to dashboard for the selected child
    Get.offAll(() => ParentDashboardScreen(
      childUid: childUid,
      childName: childName,
    ));
  }

  /// Navigate to Add Child screen
  void navigateToAddChild() {
    final parentUid = AuthenticationRepository.instance.currentUser?.uid;
    Get.back(); // close drawer
    if (parentUid != null) {
      Get.to(() => ParentBindScreen(parentUid: parentUid));
    }
  }

  /// Unlink child device with confirmation dialog
  void confirmUnlinkChild(BuildContext context, ConnectedChildInfo child, String currentChildUid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link_off_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Unlink Device?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to disconnect "${child.name}" from your account? You can re-link it anytime using the child device\'s 6-digit code.',
          style: const TextStyle(fontSize: 14, color: UColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: UColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeUnlinkChild(child.uid, child.name, currentChildUid);
            },
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  /// Execute unlinking in Firestore
  Future<void> _executeUnlinkChild(String childUid, String childName, String currentChildUid) async {
    try {
      final parentUid = AuthenticationRepository.instance.currentUser?.uid;
      if (parentUid == null) return;

      // 1. Remove child from parent's linkedChildren
      await _db.collection('Users').doc(parentUid).update({
        'linkedChildren': FieldValue.arrayRemove([childUid]),
      });

      // 2. Set child device as unlinked
      await _db.collection('Users').doc(childUid).update({
        'parentUid': '',
        'isPaired': false,
      });

      // Refresh UserController
      if (Get.isRegistered<UserController>()) {
        await UserController.instance.fetchUserDetails();
      }

      USnackBarHelpers.successSnackBar(
        title: 'Device Unlinked',
        message: '"$childName" was successfully disconnected.',
      );

      // 3. If the unlinked child was currently active on dashboard
      if (childUid == currentChildUid) {
        final remaining = childrenList.where((c) => c.uid != childUid).toList();
        if (remaining.isNotEmpty) {
          // Switch to first remaining child
          final nextChild = remaining.first;
          GetStorage().write('childUid', nextChild.uid);
          Get.offAll(() => ParentDashboardScreen(
            childUid: nextChild.uid,
            childName: nextChild.name,
          ));
        } else {
          // No children left, go to Bind Screen
          GetStorage().write('isBind', false);
          GetStorage().remove('childUid');
          Get.offAll(() => ParentBindScreen(parentUid: parentUid));
        }
      }
    } catch (e) {
      USnackBarHelpers.errorSnackBar(title: 'Error', message: 'Failed to unlink device: $e');
    }
  }

  /// Show Help & Support sheet (placeholder for future implementation)
  void showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: UColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help & Support Center',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Comprehensive guides & priority support',
                        style: TextStyle(color: UColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Multi-Device Pairing Guide:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildGuideStep('1', 'Open CareCircle Child App on your child\'s phone.'),
            _buildGuideStep('2', 'Complete setup permissions to receive the 6-digit code.'),
            _buildGuideStep('3', 'Tap "+ Add Child" in this menu and enter that code.'),
            _buildGuideStep('4', 'If a child device is inactive for 7 days, it auto-resets.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildGuideStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: UColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: UColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: UColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm logout dialog
  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of CareCircle? You will need to sign in again to monitor your children.',
          style: TextStyle(fontSize: 14, color: UColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: UColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              Get.back(); // close drawer
              await AuthenticationRepository.instance.logOut();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
