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
import '../controller/parent_dashboard_controller.dart';
// 👇 Update these import paths to match your project structure
// import '../../soundlistener/sound_listener_screen.dart';

/// 🏠 ParentDashboardScreen — main dashboard showing child's device info,
/// screen time, and installed apps.
///
/// Production features:
///  ✅ Takes childUid via constructor (passed from previous screen)
///  ✅ Uses ParentDashboardController for DI orchestration
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
  @override
  void initState() {
    super.initState();
    // Initialize controllers if not already
    if (!Get.isRegistered<ParentDashboardController>()) {
      Get.put(
        ParentDashboardController(childUid: widget.childUid),
        permanent: false,
      );
    }
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
    // 👇 Direct navigation — uncomment + update class name as per your code
     Get.to(() => SoundListenerScreen(childUid: widget.childUid,));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UColors.light,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.childName ?? 'Child Dashboard',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
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
