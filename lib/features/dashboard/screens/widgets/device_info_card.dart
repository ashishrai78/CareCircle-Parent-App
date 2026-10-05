import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/custom_shape/circular_container.dart';
import '../../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../locations/screens/location_map_screen.dart';
import '../../controller/child_deviceinfo_controller.dart';
// 👇 Update these import paths to match your project structure
// import '../../../locations/screens/location_map_screen.dart';

/// 💻 DeviceInfoCard — top card showing battery + location + device info
class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({super.key, required this.childUid});

  final String childUid;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChildDeviceInfoController(childUid: childUid));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.md,
        vertical: USizes.sm,
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoading(context);
        }

        if (controller.error.isNotEmpty && controller.data == null) {
          return _buildError(controller.error.value, controller.refreshData);
        }

        return _buildContent(context, controller);
      }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ChildDeviceInfoController controller,
  ) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.md),
      showShadow: true,
      child: Column(
        children: [
          // Header: device name + last updated
          _buildHeader(context, controller),
          const SizedBox(height: USizes.md),

          // Battery + Location row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Battery Circle
              Expanded(
                flex: 1,
                child: _buildBatteryCircle(controller),
              ),
              const SizedBox(width: USizes.md),

              // Location Info
              Expanded(
                flex: 2,
                child: _buildLocationCard(context, controller),
              ),
            ],
          ),

          const SizedBox(height: USizes.md),

          // 🆕 Quick device status row: Ringer Mode | Screen Status | Network
          _buildQuickStatusRow(controller),

          // Charging indicator
          if (controller.isCharging) ...[
            const SizedBox(height: USizes.xs),
            _buildChargingBadge(),
          ],

          // Battery Saver indicator
          if (controller.isPowerSaveMode) ...[
            const SizedBox(height: USizes.xs),
            _buildPowerSaveBadge(),
          ],

          // Mock location warning
          if (controller.isMockLocation) ...[
            const SizedBox(height: USizes.xs),
            _buildMockLocationWarning(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ChildDeviceInfoController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Device name
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(USizes.sm),
                decoration: BoxDecoration(
                  color: UColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: UColors.primary,
                  size: USizes.iconSm,
                ),
              ),
              const SizedBox(width: USizes.sm),
              Expanded(
                child: Text(
                  controller.deviceName,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: USizes.sm),

        // Online status badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: USizes.sm,
            vertical: USizes.xs,
          ),
          decoration: BoxDecoration(
            color: (controller.isOnline ? UColors.success : UColors.offline)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: controller.isOnline ? UColors.success : UColors.offline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: USizes.xs),
              Text(
                controller.onlineStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: controller.isOnline ? UColors.success : UColors.offline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryCircle(ChildDeviceInfoController controller) {
    return UCircularContainer(
      width: 100,
      height: 100,
      color: controller.batteryStatusColor.withValues(alpha: 0.05),
      borderColor: controller.batteryStatusColor.withValues(alpha: 0.3),
      borderWidth: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.isCharging
                ? Icons.battery_charging_full
                : Icons.battery_full,
            color: controller.batteryStatusColor,
            size: 28,
          ),
          const SizedBox(height: USizes.xs),
          Text(
            controller.batteryPercentage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: controller.batteryStatusColor,
            ),
          ),
          Text(
            controller.batteryStatusText,
            style: TextStyle(
              fontSize: 10,
              color: controller.batteryStatusColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    ChildDeviceInfoController controller,
  ) {
    final hasLocation = controller.hasLocation;

    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.sm),
      color: hasLocation
          ? UColors.success.withValues(alpha: 0.05)
          : UColors.error.withValues(alpha: 0.05),
      borderColor: hasLocation
          ? UColors.success.withValues(alpha: 0.2)
          : UColors.error.withValues(alpha: 0.2),
      border: true,
      borderRadius: USizes.cardRadiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on : Icons.location_off,
                size: USizes.iconSm,
                color: hasLocation ? UColors.success : UColors.error,
              ),
              const SizedBox(width: USizes.xs),
              Expanded(
                child: Text(
                  controller.locationStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasLocation ? UColors.success : UColors.error,
                  ),
                ),
              ),
            ],
          ),

          if (hasLocation) ...[
            const SizedBox(height: USizes.sm),
            // Coordinates
            Text(
              'Lat: ${controller.latitude?.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: USizes.xs),
            Text(
              'Lng: ${controller.longitude?.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Address (if available)
            if (controller.address != null &&
                controller.address!.isNotEmpty) ...[
              const SizedBox(height: USizes.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place,
                    size: 12,
                    color: UColors.textSecondary,
                  ),
                  const SizedBox(width: USizes.xs),
                  Expanded(
                    child: Text(
                      controller.address!,
                      style: TextStyle(
                        fontSize: 11,
                        color: UColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // View Map button
            const SizedBox(height: USizes.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // 👇 Direct navigation — update LocationMapScreen import + constructor as per your code
                   Get.to(() => LocationMapScreen(childUid: childUid,

                  //   deviceName: controller.deviceName,
                  //   lastUpdated: controller.lastUpdated,
                   ));
                },
                icon: const Icon(Icons.map, size: USizes.iconSm),
                label: const Text('View Map'),
                style: TextButton.styleFrom(
                  foregroundColor: UColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: USizes.sm,
                    vertical: USizes.xs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.md,
        vertical: USizes.xs,
      ),
      decoration: BoxDecoration(
        color: UColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 14, color: UColors.success),
          const SizedBox(width: USizes.xs),
          Text(
            'Device is charging',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: UColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockLocationWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.md,
        vertical: USizes.xs,
      ),
      decoration: BoxDecoration(
        color: UColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, size: 14, color: UColors.warning),
          const SizedBox(width: USizes.xs),
          Expanded(
            child: Text(
              'Mock location detected — GPS may be spoofed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: UColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerSaveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.md,
        vertical: USizes.xs,
      ),
      decoration: BoxDecoration(
        color: UColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.energy_savings_leaf, size: 14, color: UColors.warning),
          SizedBox(width: USizes.xs),
          Text(
            'Battery Saver is ON (Updates may delay)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: UColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusRow(ChildDeviceInfoController controller) {
    // Ringer Mode
    final IconData ringerIcon;
    final Color ringerColor;
    final String ringerLabel;
    if (controller.isPhoneSilent) {
      ringerIcon = Icons.notifications_off_rounded;
      ringerColor = UColors.error;
      ringerLabel = 'Silent';
    } else if (controller.isPhoneVibrate) {
      ringerIcon = Icons.vibration_rounded;
      ringerColor = const Color(0xFF8B5CF6);
      ringerLabel = 'Vibrate';
    } else {
      ringerIcon = Icons.notifications_active_rounded;
      ringerColor = UColors.primary;
      ringerLabel = 'Sound On';
    }

    // Network Status
    final String netType = controller.networkType.toUpperCase();
    final IconData netIcon = netType == 'WIFI'
        ? Icons.wifi_rounded
        : (netType == 'CELLULAR'
            ? Icons.network_cell_rounded
            : Icons.signal_cellular_connected_no_internet_4_bar_rounded);
    final String netLabel = netType == 'WIFI'
        ? 'Wi-Fi'
        : (netType == 'CELLULAR' ? 'Mobile' : 'No Net');
    final Color netColor =
        controller.hasInternet ? UColors.primary : UColors.error;

    return Row(
      children: [
        // Ringer mode chip
        Expanded(
          child: _buildStatusChip(
            icon: ringerIcon,
            label: ringerLabel,
            color: ringerColor,
          ),
        ),
        const SizedBox(width: USizes.xs),

        // Screen active chip
        Expanded(
          child: _buildStatusChip(
            icon: controller.isScreenOn
                ? Icons.phone_android_rounded
                : Icons.screen_lock_portrait_rounded,
            label: controller.screenStatusText,
            color:
                controller.isScreenOn ? UColors.success : UColors.textSecondary,
          ),
        ),
        const SizedBox(width: USizes.xs),

        // Network chip
        Expanded(
          child: _buildStatusChip(
            icon: netIcon,
            label: netLabel,
            color: netColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.xs,
        vertical: USizes.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.xl),
      showShadow: true,
      child: const Center(
        child: CircularProgressIndicator(color: UColors.primary),
      ),
    );
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.lg),
      showShadow: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: UColors.error),
          const SizedBox(height: USizes.md),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: UColors.textSecondary,
            ),
          ),
          const SizedBox(height: USizes.md),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
