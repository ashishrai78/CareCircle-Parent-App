import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controller/installed_apps_controller.dart';
import '../all_installed_apps_screen.dart';


/// 📱 InstalledAppsSection — preview card showing first 3 installed apps
class InstalledAppsSection extends StatelessWidget {
  const InstalledAppsSection({super.key, required this.childUid});
  final String childUid;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InstalledAppsController(childUid: childUid));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.md,
        vertical: USizes.sm,
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoading();
        }

        if (controller.error.isNotEmpty && controller.totalApps == 0) {
          return _buildError(controller.error.value, controller.refreshData);
        }

        return _buildContent(context, controller);
      }),
    );
  }

  Widget _buildContent(
    BuildContext context,
    InstalledAppsController controller,
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

          // Apps preview
          if (controller.totalApps == 0)
            _buildEmptyState()
          else ...[
            _buildAppsPreview(controller),
            const SizedBox(height: USizes.sm),
            _buildSeeAllButton(controller),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    InstalledAppsController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(USizes.sm),
              decoration: BoxDecoration(
                color: UColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
              ),
              child: const Icon(
                Icons.apps,
                color: UColors.primary,
                size: USizes.iconSm,
              ),
            ),
            const SizedBox(width: USizes.sm),
            Text(
              'Installed Apps',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
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
            '${controller.totalApps} apps',
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

  Widget _buildAppsPreview(InstalledAppsController controller) {
    final previewApps = controller.installedApps.take(3).toList();
    return Column(
      children: previewApps.map((app) {
        final categoryColor = controller.getCategoryColor(app.category);
        final categoryIcon = controller.getCategoryIcon(app.category);

        return Padding(
          padding: const EdgeInsets.only(bottom: USizes.sm),
          child: URoundedContainer(
            padding: const EdgeInsets.all(USizes.sm),
            color: UColors.lightGrey,
            border: true,
            borderColor: UColors.borderSecondary,
            borderRadius: USizes.cardRadiusMd,
            child: Row(
              children: [
                // App icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: USizes.sm),

                // App name + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: UColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        app.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: UColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Recently installed badge
                if (app.isRecentlyInstalled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: USizes.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: UColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(USizes.borderRadiusSm),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: UColors.success,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: UColors.textTertiary,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeeAllButton(InstalledAppsController controller) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Get.to(() => AllInstalledAppsScreen(childUid: controller.childUid));
        },
        icon: const Icon(Icons.visibility, size: 16),
        label: Text(
          'See All ${controller.totalApps} Apps',
          style: const TextStyle(
            fontSize: 13,
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
              Icons.apps_outage,
              size: 48,
              color: UColors.textTertiary,
            ),
            const SizedBox(height: USizes.sm),
            Text(
              'No apps installed',
              style: TextStyle(
                fontSize: 14,
                color: UColors.textSecondary,
                fontWeight: FontWeight.w500,
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
            'Failed to load apps',
            style: TextStyle(
              color: UColors.error,
              fontWeight: FontWeight.w600,
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
