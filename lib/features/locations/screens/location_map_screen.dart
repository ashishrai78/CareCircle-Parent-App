import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/location_controller.dart';
import '../../../data/models/location_model.dart';
import 'location_history_screen.dart';

/// 🗺️ LocationMapScreen — full screen map showing child's live location + history trail
///
/// Features:
///  ✅ Google Maps with live location marker (color-coded by type)
///  ✅ Movement trail polyline (today's history)
///  ✅ Bottom sheet with location details (address, accuracy, speed, etc.)
///  ✅ Follow mode toggle (auto-center on updates)
///  ✅ Open in Google Maps app + Get directions
///  ✅ View history button
///  ✅ Mock location warning
///  ✅ Loading / error / no-location states
///  ✅ 🔥 Location type-aware UI (warnings for OFF / Approximate / Cached)
///  ✅ 🔥 Cell tower info display when GPS unavailable
class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({
    super.key,
    required this.childUid,
    this.childName,
  });

  final String childUid;
  final String? childName;

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  late final LocationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LocationController(childUid: widget.childUid));
  }

  @override
  void dispose() {
    Get.delete<LocationController>();
    super.dispose();
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
              widget.childName ?? 'Live Location',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Obx(() => Text(
                  controller.hasLocation
                      ? 'Updated ${controller.timeAgo}'
                      : 'No location yet',
                  style: TextStyle(
                    fontSize: 12,
                    color: UColors.textSecondary,
                  ),
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
               Get.to(() => LocationHistoryScreen(childUid: widget.childUid));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingMap();
            }
            if (controller.error.isNotEmpty && !controller.hasLocation) {
              return _buildErrorMap();
            }
            return _buildMap();
          }),

          // 🔥 Location status warning banner (OFF / Approximate / Cached / Mocked)
          Obx(() => _buildStatusBanner()),

          // Bottom location details sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(),
          ),

          // Floating action buttons (right)
          Positioned(
            right: USizes.md,
            bottom: 220,
            child: Column(
              children: [
                // Follow mode toggle
                FloatingActionButton.small(
                  heroTag: 'follow',
                  onPressed: controller.toggleFollowLiveLocation,
                  backgroundColor: controller.followLiveLocation.value
                      ? UColors.primary
                      : UColors.white,
                  foregroundColor: controller.followLiveLocation.value
                      ? UColors.textWhite
                      : UColors.textSecondary,
                  child: Icon(
                    controller.followLiveLocation.value
                        ? Icons.my_location
                        : Icons.location_searching,
                  ),
                ),
                const SizedBox(height: USizes.sm),
                // Open in Google Maps
                FloatingActionButton.small(
                  heroTag: 'google_maps',
                  onPressed: controller.openInGoogleMaps,
                  backgroundColor: UColors.white,
                  foregroundColor: UColors.accent,
                  child: const Icon(Icons.map_outlined),
                ),
                const SizedBox(height: USizes.sm),
                // Get directions
                FloatingActionButton.small(
                  heroTag: 'directions',
                  onPressed: controller.getDirections,
                  backgroundColor: UColors.white,
                  foregroundColor: UColors.success,
                  child: const Icon(Icons.directions),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ MAP ============

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: controller.initialCameraPosition,
      onMapCreated: controller.onMapCreated,
      markers: controller.markers.value,
      polylines: controller.polylines.value,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
      mapType: MapType.normal,
      onCameraMove: (_) {
        // Disable follow mode when user manually pans
        if (controller.followLiveLocation.value) {
          controller.followLiveLocation.value = false;
        }
      },
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      color: UColors.lightGrey,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: UColors.primary),
            SizedBox(height: USizes.md),
            Text(
              'Loading location...',
              style: TextStyle(
                fontSize: 14,
                color: UColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMap() {
    return Container(
      color: UColors.lightGrey,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(USizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 64,
                color: UColors.error,
              ),
              const SizedBox(height: USizes.md),
              const Text(
                'Location Unavailable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: UColors.textPrimary,
                ),
              ),
              const SizedBox(height: USizes.xs),
              Text(
                controller.error.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: UColors.textSecondary,
                ),
              ),
              const SizedBox(height: USizes.lg),
              ElevatedButton.icon(
                onPressed: controller.refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ 🔥 STATUS BANNER ============

  /// Show appropriate banner based on location state
  Widget _buildStatusBanner() {
    final loc = controller.liveLocation.value;
    if (loc == null) return const SizedBox.shrink();

    // Mock location warning (highest priority)
    if (loc.isMocked) {
      return _buildBanner(
        icon: Icons.warning,
        message: 'Mock location detected — GPS may be spoofed',
        color: UColors.warning,
      );
    }

    // Location is OFF
    if (controller.isLocationOff) {
      final cellInfo = loc.cellInfo;
      final msg = cellInfo != null
          ? 'Location is OFF — Network: ${cellInfo.operatorName}'
          : 'Location is OFF on child device';
      return _buildBanner(
        icon: Icons.location_off,
        message: msg,
        color: UColors.error,
        action: ElevatedButton(
          onPressed: controller.refreshData,
          style: ElevatedButton.styleFrom(
            backgroundColor: UColors.white,
            foregroundColor: UColors.error,
            padding: const EdgeInsets.symmetric(horizontal: USizes.sm),
            minimumSize: const Size(0, 28),
          ),
          child: const Text('Request', style: TextStyle(fontSize: 11)),
        ),
      );
    }

    // Approximate location (cell tower resolved)
    if (controller.isApproximate) {
      return _buildBanner(
        icon: Icons.cell_tower,
        message: 'Approximate location (±5 km) — GPS unavailable',
        color: UColors.warning,
      );
    }

    // Cached location
    if (controller.isFromCache) {
      return _buildBanner(
        icon: Icons.history,
        message: 'Showing last cached location (${controller.timeAgo})',
        color: UColors.info,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBanner({
    required IconData icon,
    required String message,
    required Color color,
    Widget? action,
  }) {
    return Positioned(
      top: USizes.md,
      left: USizes.md,
      right: USizes.md,
      child: URoundedContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: USizes.md,
          vertical: USizes.sm,
        ),
        color: color,
        borderRadius: USizes.borderRadiusLg,
        showShadow: true,
        child: Row(
          children: [
            Icon(icon, color: UColors.textWhite, size: 20),
            const SizedBox(width: USizes.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: UColors.textWhite,
                ),
              ),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }

  // ============ BOTTOM SHEET ============

  Widget _buildBottomSheet() {
    return Obx(() {
      if (!controller.hasLocation) {
        return _buildNoLocationSheet();
      }
      return _buildLocationDetailsSheet();
    });
  }

  Widget _buildNoLocationSheet() {
    return URoundedContainer(
      margin: const EdgeInsets.all(USizes.md),
      padding: const EdgeInsets.all(USizes.lg),
      color: UColors.white,
      showShadow: true,
      borderRadius: USizes.cardRadiusLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_searching,
            size: 40,
            color: UColors.textTertiary,
          ),
          const SizedBox(height: USizes.sm),
          const Text(
            'Waiting for location...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: UColors.textPrimary,
            ),
          ),
          const SizedBox(height: USizes.xs),
          const Text(
            'The child\'s device will share its location shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: UColors.textSecondary,
            ),
          ),
          const SizedBox(height: USizes.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Request Location Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailsSheet() {
    final loc = controller.liveLocation.value!;
    final showCellInfo = loc.cellInfo != null;

    return URoundedContainer(
      margin: const EdgeInsets.all(USizes.md),
      padding: const EdgeInsets.all(USizes.md),
      color: UColors.white,
      showShadow: true,
      borderRadius: USizes.cardRadiusLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: USizes.md),
              decoration: BoxDecoration(
                color: UColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Address + provider icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(USizes.sm),
                decoration: BoxDecoration(
                  color: _getProviderColor(loc.locationType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
                ),
                child: Icon(
                  _getProviderIcon(loc.locationType),
                  color: _getProviderColor(loc.locationType),
                  size: 20,
                ),
              ),
              const SizedBox(width: USizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: UColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated ${controller.timeAgo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: UColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: USizes.md),

          // Stats grid (4 cells)
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.gps_fixed,
                  label: 'Accuracy',
                  value: controller.accuracyLabel,
                  color: UColors.accent,
                ),
              ),
              const SizedBox(width: USizes.sm),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.speed,
                  label: 'Speed',
                  value: controller.speedLabel,
                  color: UColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: USizes.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.route,
                  label: 'Today\'s Travel',
                  value: controller.distanceTraveled,
                  color: UColors.success,
                ),
              ),
              const SizedBox(width: USizes.sm),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.satellite_alt,
                  label: 'Source',
                  value: controller.providerLabel,
                  color: _getProviderColor(loc.locationType),
                ),
              ),
            ],
          ),

          // 🔥 Cell tower info (if available)
          if (showCellInfo) ...[
            const SizedBox(height: USizes.md),
            _buildCellInfoSection(loc.cellInfo!),
          ],

          const SizedBox(height: USizes.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.canShowOnMap
                      ? controller.openInGoogleMaps
                      : null,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Google Maps'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: USizes.sm),
                  ),
                ),
              ),
              const SizedBox(width: USizes.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.canShowOnMap
                      ? controller.getDirections
                      : null,
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: USizes.sm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔥 Cell tower info section — shown when location source is cell tower
  Widget _buildCellInfoSection(CellInfo cellInfo) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.sm),
      color: UColors.warning.withValues(alpha: 0.05),
      border: true,
      borderColor: UColors.warning.withValues(alpha: 0.2),
      borderRadius: USizes.cardRadiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cell_tower, size: 14, color: UColors.warning),
              const SizedBox(width: USizes.xs),
              const Text(
                'Cell Tower Info',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: UColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: USizes.xs),
          _buildInfoRow('Network', cellInfo.operatorName),
          _buildInfoRow('Type', cellInfo.cellType),
          _buildInfoRow('Signal', '${cellInfo.signalStrength} dBm (${cellInfo.signalLabel})'),
          _buildInfoRow('Tower ID', cellInfo.cellId.toString()),
          if (cellInfo.note != null)
            _buildInfoRow('Note', cellInfo.note!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: UColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: UColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.sm),
      color: color.withValues(alpha: 0.05),
      border: true,
      borderColor: color.withValues(alpha: 0.2),
      borderRadius: USizes.cardRadiusMd,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: USizes.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: UColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ 🔥 HELPERS ============

  /// Get provider color based on location type
  Color _getProviderColor(LocationType type) {
    switch (type) {
      case LocationType.gps:
        return UColors.accent;          // Blue
      case LocationType.cellTowerResolved:
        return UColors.warning;         // Yellow
      case LocationType.cellTowerBasic:
        return UColors.error;           // Red
      case LocationType.cached:
        return UColors.info;            // Purple
      case LocationType.unknown:
        return UColors.textTertiary;
    }
  }

  /// Get provider icon based on location type
  IconData _getProviderIcon(LocationType type) {
    switch (type) {
      case LocationType.gps:
        return Icons.gps_fixed;
      case LocationType.cellTowerResolved:
        return Icons.cell_tower;
      case LocationType.cellTowerBasic:
        return Icons.signal_cellular_4_bar;
      case LocationType.cached:
        return Icons.history;
      case LocationType.unknown:
        return Icons.help_outline;
    }
  }
}
