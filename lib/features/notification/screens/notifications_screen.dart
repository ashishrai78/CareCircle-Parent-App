import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/notifications_controller.dart';

/// 📢 NotificationsScreen — list of all notifications from child device
///
/// Features:
///  ✅ Real-time list (updates as notifications arrive)
///  ✅ App-wise filter chips (All / WhatsApp / Instagram / etc.)
///  ✅ Search by title / text / app name
///  ✅ Date picker (view past days)
///  ✅ Stats summary (total count)
///  ✅ Tap for full details
///  ✅ Loading / error / empty states
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.childUid,
    this.childName,
  });

  final String childUid;
  final String? childName;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotificationsController(childUid: widget.childUid));
  }

  @override
  void dispose() {
    Get.delete<NotificationsController>();
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
              widget.childName != null
                  ? '${widget.childName}\'s Notifications'
                  : 'Notifications',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Obx(() => Text(
                  '${controller.totalCount.value} ${controller.isToday ? 'today' : controller.selectedDateLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    color: UColors.textSecondary,
                  ),
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pick Date',
            onPressed: controller.pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              _buildSearchBar(),
              _buildAppChips(),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: UColors.primary),
          );
        }

        if (controller.error.isNotEmpty) {
          return _buildErrorState();
        }

        if (!controller.hasNotifications) {
          return _buildEmptyState();
        }

        if (!controller.hasFilteredResults) {
          return _buildNoResultsState();
        }

        return _buildNotificationsList();
      }),
    );
  }

  // ============ SEARCH BAR ============

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.md,
        vertical: USizes.xs,
      ),
      child: Container(
        height: USizes.searchBarHeight,
        decoration: BoxDecoration(
          color: UColors.white,
          borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
          border: Border.all(color: UColors.borderPrimary),
        ),
        child: Obx(() => TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: UColors.textTertiary,
                ),
                prefixIcon: const Icon(Icons.search, color: UColors.primary),
                suffixIcon: controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: USizes.md,
                  vertical: USizes.sm,
                ),
              ),
            )),
      ),
    );
  }

  // ============ APP FILTER CHIPS ============

  Widget _buildAppChips() {
    return SizedBox(
      height: 44,
      child: Obx(() {
        final apps = controller.appList;
        if (apps.length <= 1) return const SizedBox.shrink();

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: USizes.md,
            vertical: USizes.xs,
          ),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            final count = app == 'All'
                ? controller.totalCount.value
                : controller.appCounts[app] ?? 0;

            return Obx(() {
              final isSelected = controller.selectedApp.value == app;
              return Padding(
                padding: const EdgeInsets.only(right: USizes.sm),
                child: GestureDetector(
                  onTap: () => controller.selectApp(app),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: USizes.md,
                      vertical: USizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? UColors.primary : UColors.white,
                      borderRadius: BorderRadius.circular(
                        USizes.borderRadiusCircular,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? UColors.primary
                            : UColors.borderPrimary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          app,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? UColors.textWhite
                                : UColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: USizes.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: USizes.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? UColors.textWhite.withValues(alpha: 0.2)
                                : UColors.lightGrey,
                            borderRadius: BorderRadius.circular(
                              USizes.borderRadiusCircular,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? UColors.textWhite
                                  : UColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        );
      }),
    );
  }

  // ============ NOTIFICATIONS LIST ============

  Widget _buildNotificationsList() {
    return Obx(() {
      final notifs = controller.filteredNotifications;

      return ListView.builder(
        padding: const EdgeInsets.all(USizes.md),
        itemCount: notifs.length,
        itemBuilder: (context, index) {
          final notif = notifs[index];
          return _buildNotificationCard(notif);
        },
      );
    });
  }

  Widget _buildNotificationCard(dynamic notif) {
    return Padding(
      padding: const EdgeInsets.only(bottom: USizes.sm),
      child: URoundedContainer(
        padding: const EdgeInsets.all(USizes.md),
        color: UColors.white,
        showShadow: true,
        borderRadius: USizes.cardRadiusMd,
        onTap: () => controller.openDetails(notif),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App emoji
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: UColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
              ),
              child: Center(
                child: Text(
                  notif.appEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: USizes.sm),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.appName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: UColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        notif.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: UColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Title
                  if (notif.title.isNotEmpty)
                    Text(
                      notif.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: UColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Text
                  if (notif.displayText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notif.displayText,
                      style: TextStyle(
                        fontSize: 13,
                        color: UColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Priority indicator
            if (notif.isHighPriority) ...[
              const SizedBox(width: USizes.xs),
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: UColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ EMPTY STATES ============

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: UColors.textTertiary,
            ),
            const SizedBox(height: USizes.md),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: UColors.textPrimary,
              ),
            ),
            const SizedBox(height: USizes.xs),
            Text(
              controller.isToday
                  ? 'When your child receives notifications,\nthey will appear here in real-time.'
                  : 'No notifications on ${controller.selectedDateLabel}.',
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

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: UColors.textTertiary,
            ),
            const SizedBox(height: USizes.md),
            Text(
              'No results for "${controller.searchQuery.value}"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: UColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: USizes.sm),
            OutlinedButton.icon(
              onPressed: controller.clearSearch,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: UColors.error,
            ),
            const SizedBox(height: USizes.md),
            Text(
              controller.error.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: UColors.textSecondary,
              ),
            ),
            const SizedBox(height: USizes.md),
            ElevatedButton.icon(
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
