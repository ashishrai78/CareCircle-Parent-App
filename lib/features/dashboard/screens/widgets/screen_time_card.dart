import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controller/screen_time_controller.dart';

/// ⏱️ ScreenTimeCard — card showing screen time summary + apps breakdown
class ScreenTimeCard extends StatelessWidget {
  const ScreenTimeCard({super.key, required this.childUid});
  final String childUid;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScreenTimeController(childUid: childUid));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.md,
        vertical: USizes.sm,
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoading();
        }

        if (controller.error.isNotEmpty && !controller.hasData) {
          return _buildError(controller.error.value, controller.refreshData);
        }

        return _buildContent(context, controller);
      }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScreenTimeController controller,
  ) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.md),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, controller),
          const SizedBox(height: USizes.md),

          // Total time circle
          _buildTotalTimeCircle(controller),
          const SizedBox(height: USizes.md),

          // Apps usage list header
          _buildAppsListHeader(controller),
          const SizedBox(height: USizes.sm),

          // Apps list
          if (!controller.hasData)
            _buildEmptyState()
          else ...[
            _buildAppsList(controller),
            if (controller.hasMoreApps) ...[
              const SizedBox(height: USizes.sm),
              _buildSeeMoreButton(controller),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ScreenTimeController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Screen Time',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            // Date picker
            GestureDetector(
              onTap: () => controller.pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: USizes.sm,
                  vertical: USizes.xs,
                ),
                decoration: BoxDecoration(
                  color: UColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: UColors.primary,
                    ),
                    const SizedBox(width: USizes.xs),
                    Text(
                      controller.selectedDateDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: UColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: USizes.sm),

        // Status badge + sessions
        Row(
          children: [
            // Status
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: USizes.sm,
                vertical: USizes.xs,
              ),
              decoration: BoxDecoration(
                color: controller.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: controller.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: USizes.xs),
                  Text(
                    controller.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: controller.statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: USizes.sm),

            // Sessions
            if (controller.hasData) ...[
              Icon(
                Icons.touch_app,
                size: 14,
                color: UColors.textSecondary,
              ),
              const SizedBox(width: USizes.xs),
              Text(
                '${controller.sessionCount} sessions',
                style: TextStyle(
                  fontSize: 12,
                  color: UColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTotalTimeCircle(ScreenTimeController controller) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  controller.statusColor.withValues(alpha: 0.3),
                  controller.statusColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: controller.statusColor.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.totalTimeFormatted,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: controller.statusColor,
                    ),
                  ),
                  const SizedBox(height: USizes.xs),
                  Text(
                    'Total Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: UColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsListHeader(ScreenTimeController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Today's App Usage",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: UColors.textPrimary,
          ),
        ),
        if (controller.hasData)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: USizes.sm,
              vertical: USizes.xs,
            ),
            decoration: BoxDecoration(
              color: UColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
            ),
            child: Text(
              '${controller.totalAppsCount} apps',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: UColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppsList(ScreenTimeController controller) {
    final apps = controller.visibleApps;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: USizes.sm),
      itemBuilder: (context, index) {
        final app = apps[index];
        final percentage = controller.getAppPercentage(app.totalTimeMs);
        final color = controller.getAppColor(index);
        final appName = controller.getAppName(app.packageName);
        final icon = controller.getAppIcon(app.packageName);

        return _buildAppTile(
          appName: appName,
          icon: icon,
          color: color,
          timeFormatted: controller.formatTime(app.totalTimeMs),
          percentage: percentage,
          sessions: app.sessions,
          openCount: app.openCount,
        );
      },
    );
  }

  Widget _buildAppTile({
    required String appName,
    required IconData icon,
    required Color color,
    required String timeFormatted,
    required double percentage,
    required int sessions,
    int openCount = 0,
  }) {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.sm),
      color: color.withValues(alpha: 0.03),
      border: true,
      borderColor: color.withValues(alpha: 0.15),
      borderRadius: USizes.cardRadiusMd,
      child: Column(
        children: [
          Row(
            children: [
              // App icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: USizes.sm),

              // Name + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: UColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          timeFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            color: UColors.textSecondary,
                          ),
                        ),
                        if (sessions > 0)
                          Text(
                            '• $sessions sessions',
                            style: TextStyle(
                              fontSize: 10,
                              color: UColors.textTertiary,
                            ),
                          ),
                        if (openCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: UColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Opened $openCount ${openCount == 1 ? "time" : "times"}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: UColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: USizes.sm,
                  vertical: USizes.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(USizes.borderRadiusSm),
                ),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: USizes.xs),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeMoreButton(ScreenTimeController controller) {
    return Center(
      child: TextButton.icon(
        onPressed: controller.toggleShowAllApps,
        icon: Icon(
          controller.showAllApps.value ? Icons.expand_less : Icons.expand_more,
          size: 16,
        ),
        label: Text(
          controller.showAllApps.value
              ? 'See Less'
              : 'See ${controller.remainingAppsCount} More',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: UColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: USizes.md,
            vertical: USizes.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
            side: BorderSide(
              color: UColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return URoundedContainer(
      padding: const EdgeInsets.all(USizes.xl),
      showShadow: true,
      child: const Center(
        child: CircularProgressIndicator(color: UColors.primary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: USizes.lg),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.timer_off,
              size: 48,
              color: UColors.textTertiary,
            ),
            const SizedBox(height: USizes.sm),
            Text(
              'No usage data available',
              style: TextStyle(
                fontSize: 14,
                color: UColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: USizes.xs),
            Text(
              'Check back later',
              style: TextStyle(
                fontSize: 12,
                color: UColors.textTertiary,
              ),
            ),
          ],
        ),
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
            style: TextStyle(fontSize: 13, color: UColors.textSecondary),
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
