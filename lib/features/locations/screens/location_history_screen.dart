import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/location_controller.dart';

/// 📜 LocationHistoryScreen — list of today's location points
///
/// Shows a timeline of locations the child has been to today.
/// Tap on any item to see more details.
class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({
    super.key,
    required this.childUid,
    this.childName,
  });

  final String childUid;
  final String? childName;

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  late final LocationController controller;

  @override
  void initState() {
    super.initState();
    // Reuse controller if already registered (from map screen)
    if (Get.isRegistered<LocationController>()) {
      controller = Get.find<LocationController>();
    } else {
      controller = Get.put(LocationController(childUid: widget.childUid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UColors.light,
      appBar: AppBar(
        title: const Text('Location History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pick Date',
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats summary
          _buildStatsHeader(),

          // History list
          Expanded(
            child: Obx(() {
              if (controller.isLoadingHistory.value) {
                return const Center(
                  child: CircularProgressIndicator(color: UColors.primary),
                );
              }

              if (controller.history.isEmpty) {
                return _buildEmptyState();
              }

              return _buildHistoryList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.all(USizes.md),
        padding: const EdgeInsets.all(USizes.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [UColors.primary, UColors.secondary],
          ),
          borderRadius: BorderRadius.circular(USizes.cardRadiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: UColors.textWhite.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: USizes.sm),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    label: 'Locations',
                    value: '${controller.historyCount}',
                    icon: Icons.place,
                  ),
                ),
                const SizedBox(width: USizes.sm),
                Expanded(
                  child: _buildStatBox(
                    label: 'Distance',
                    value: controller.distanceTraveled,
                    icon: Icons.route,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(USizes.sm),
      decoration: BoxDecoration(
        color: UColors.textWhite.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(USizes.cardRadiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: UColors.textWhite, size: 20),
          const SizedBox(width: USizes.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: UColors.textWhite.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: UColors.textWhite,
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

  Widget _buildHistoryList() {
    return Obx(() {
      final locations = controller.history;

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: USizes.md),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          final isLast = index == locations.length - 1;
          final isFirst = index == 0;

          return _buildHistoryItem(
            location: location,
            isFirst: isFirst,
            isLast: isLast,
          );
        },
      );
    });
  }

  Widget _buildHistoryItem({
    required dynamic location,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        SizedBox(
          width: 32,
          child: Column(
            children: [
              // Top line
              if (!isFirst)
                Container(width: 2, height: 12, color: UColors.borderPrimary)
              else
                const SizedBox(height: 12),

              // Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst ? UColors.primary : UColors.textSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: UColors.white,
                    width: 2,
                  ),
                ),
              ),

              // Bottom line
              if (!isLast)
                Container(width: 2, height: 48, color: UColors.borderPrimary)
              else
                const SizedBox(height: 48),
            ],
          ),
        ),

        // Card
        Expanded(
          child: URoundedContainer(
            margin: const EdgeInsets.only(bottom: USizes.sm),
            padding: const EdgeInsets.all(USizes.md),
            color: UColors.white,
            showShadow: true,
            borderRadius: USizes.cardRadiusMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      location.timeOfDay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: UColors.textPrimary,
                      ),
                    ),
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: USizes.sm,
                          vertical: USizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: UColors.success.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(USizes.borderRadiusCircular),
                        ),
                        child: const Text(
                          'LATEST',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: UColors.success,
                          ),
                        ),
                      )
                    else if (location.isMocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: USizes.sm,
                          vertical: USizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: UColors.warning.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(USizes.borderRadiusCircular),
                        ),
                        child: const Text(
                          'MOCK',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: UColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: USizes.xs),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: UColors.textSecondary,
                    ),
                    const SizedBox(width: USizes.xs),
                    Expanded(
                      child: Text(
                        location.address ?? 'Address unavailable',
                        style: const TextStyle(
                          fontSize: 13,
                          color: UColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: USizes.xs),

                // Coordinates + accuracy
                Row(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      size: 12,
                      color: UColors.textTertiary,
                    ),
                    const SizedBox(width: USizes.xs),
                    Text(
                      location.coordinatesFormatted,
                      style: TextStyle(
                        fontSize: 11,
                        color: UColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: USizes.sm),
                    const Icon(
                      Icons.straighten,
                      size: 12,
                      color: UColors.textTertiary,
                    ),
                    const SizedBox(width: USizes.xs),
                    Text(
                      location.accuracyLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: UColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: UColors.textTertiary,
            ),
            const SizedBox(height: USizes.md),
            const Text(
              'No Location History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: UColors.textPrimary,
              ),
            ),
            const SizedBox(height: USizes.xs),
            const Text(
              'Location history will appear here once the child device starts sharing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: UColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate7 = today.subtract(const Duration(days: 6));

    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: firstDate7,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: UColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // TODO: Fetch history for specific date
      // For now, just show snackbar
      final dateKey = DateFormat('dd-MM-yyyy').format(picked);
      Get.snackbar(
        'Date Selected',
        'Viewing history for $dateKey (feature coming soon)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: UColors.info,
        colorText: UColors.textWhite,
      );
    }
  }
}
