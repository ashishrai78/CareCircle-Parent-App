import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carecircle_parent1/features/dashboard/screens/widgets/current_app_active_card.dart';
import 'package:carecircle_parent1/features/dashboard/screens/widgets/device_info_card.dart';
import 'package:carecircle_parent1/features/dashboard/screens/widgets/installed_apps_section.dart';
import 'package:carecircle_parent1/features/dashboard/screens/widgets/screen_time_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../contact/screens/call_logs_screen.dart';
import '../../liveaudio/sound_listener_screen.dart';
import '../../notification/screens/notifications_screen.dart';
import '../../personalization/controllers/user_controller.dart';
import '../controller/parent_dashboard_controller.dart';
import 'widgets/parent_drawer.dart';

/// 🏠 ParentDashboardScreen — main dashboard showing child's device info,
/// screen time, and installed apps.
///
/// Production features:
///  ✅ Takes childUid via constructor (passed from previous screen)
///  ✅ Uses ParentDashboardController for DI orchestration
///  ✅ CircleAvatar in AppBar leading opens premium sliding drawer
///  ✅ Multi-child device switching & connection
///  ✅ Pull-to-refresh
///  ✅ AppBar with refresh + mic buttons
///  ✅ Loading / error / empty states
class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({
    super.key,
    required this.childUid,
    this.childName,
  });

  final String childUid;
  final String? childName;

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  String _childDisplayName = '';

  @override
  void initState() {
    super.initState();
    _childDisplayName = widget.childName ?? 'Child Device';
    _fetchChildName();

    // Ensure UserController is initialized for drawer & avatar
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }

    // Initialize controllers if not already
    if (!Get.isRegistered<ParentDashboardController>()) {
      Get.put(
        ParentDashboardController(childUid: widget.childUid),
        permanent: false,
      );
    }
  }

  Future<void> _fetchChildName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(widget.childUid).get();
      if (doc.exists && mounted) {
        final name = doc.data()?['name'];
        if (name != null && name.toString().isNotEmpty) {
          setState(() {
            _childDisplayName = name.toString();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    // Clean up when leaving screen
    if (Get.isRegistered<ParentDashboardController>()) {
      Get.delete<ParentDashboardController>();
    }
    super.dispose();
  }
  
  void _refreshAll() {
    if (Get.isRegistered<ParentDashboardController>()) {
      final controller = Get.find<ParentDashboardController>();
      controller.deviceInfoController.refreshData();
      controller.screenTimeController.refreshData();
    }
  }

  void _navigateToSoundListener() {
    Get.to(() => SoundListenerScreen(childUid: widget.childUid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UColors.light,
      drawer: ParentDrawer(activeChildUid: widget.childUid),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0, right: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: UColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: UColors.primary.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: UColors.primary.withOpacity(0.12),
                  child: Obx(() {
                    final parentUser = Get.isRegistered<UserController>()
                        ? UserController.instance.user.value
                        : null;
                    final name = parentUser?.name ?? '';
                    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
                    return Text(
                      initial,
                      style: const TextStyle(
                        color: UColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        title: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _childDisplayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: UColors.textSecondary,
                    ),
                  ],
                ),
                Text(
                  'Monitor your child\'s device',
                  style: TextStyle(
                    fontSize: 12,
                    color: UColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'View Notifications',
            onPressed: () {
              Get.to(() => NotificationsScreen(
                childUid: widget.childUid,
                childName: widget.childName,
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic_none_rounded),
            tooltip: 'Listen to surroundings',
            onPressed: _navigateToSoundListener,
          ),

          // Call Logs button
          IconButton(
            onPressed: () => Get.to(() => CallLogsScreen(
              childUid: widget.childUid,
              childName: widget.childName,
            )),
            icon: Icon(Icons.phone),
          ),
          const SizedBox(width: USizes.xs),
        ],
      ),
      body:  RefreshIndicator(
        color: UColors.primary,
        onRefresh: () async {
          _refreshAll();
          // Wait a bit for visual feedback
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: USizes.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Device info (battery + location)
              DeviceInfoCard(childUid: widget.childUid),

              // Current App Active Card
              CurrentAppActiveCard(childUid: widget.childUid,),

              // Screen time breakdown
              ScreenTimeCard(childUid: widget.childUid),

              // Installed apps preview
              InstalledAppsSection(childUid: widget.childUid,),
            ],
          ),
        ),
      ),
    );
  }
}
