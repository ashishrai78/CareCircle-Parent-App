import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controller/installed_apps_controller.dart';

/// 📱 AllInstalledAppsScreen — full list of all installed apps with search + filter
///
/// Production features:
///  ✅ Search by name or package name
///  ✅ Filter by category (chips)
///  ✅ Sort by name / install date
///  ✅ App details dialog
///  ✅ Pull-to-refresh
///  ✅ Loading / empty / error states
class AllInstalledAppsScreen extends StatefulWidget {
  const AllInstalledAppsScreen({
    super.key,
    required this.childUid,
  });

  final String childUid;

  @override
  State<AllInstalledAppsScreen> createState() => _AllInstalledAppsScreenState();
}

class _AllInstalledAppsScreenState extends State<AllInstalledAppsScreen> {
  @override
  void initState() {
    super.initState();
    // Reuse existing controller from dashboard OR create new one
    if (!Get.isRegistered<InstalledAppsController>(tag: 'dashboard_${widget.childUid}')) {
      Get.put(
        InstalledAppsController(childUid: widget.childUid),
        tag: 'dashboard_${widget.childUid}',
      );
    }
  }

  InstalledAppsController get controller =>
      Get.find<InstalledAppsController>(tag: 'dashboard_${widget.childUid}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UColors.light,
      appBar: AppBar(
        title: const Text('All Installed Apps'),
        actions: [
          IconButton(
            icon: Obx(() => Icon(
                  controller.sortBy.value == 'name'
                      ? Icons.sort_by_alpha
                      : Icons.access_time,
                )),
            tooltip: controller.sortBy.value == 'name'
                ? 'Sort by name (A-Z)'
                : 'Sort by install date (newest)',
            onPressed: controller.toggleSortBy,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: USizes.md,
                  vertical: USizes.xs,
                ),
                child: _buildSearchBar(),
              ),
              // Category chips
              Padding(
                padding: const EdgeInsets.only(bottom: USizes.sm),
                child: _buildCategoryChips(),
              ),
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

        if (controller.error.isNotEmpty && controller.totalApps == 0) {
          return _buildErrorState(controller.error.value);
        }

        if (controller.filteredApps.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          color: UColors.primary,
          onRefresh: controller.refreshData,
          child: ListView.builder(
            padding: const EdgeInsets.all(USizes.md),
            itemCount: controller.filteredApps.length,
            itemBuilder: (context, index) {
              final app = controller.filteredApps[index];
              return _buildAppCard(context, app, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: USizes.searchBarHeight,
      decoration: BoxDecoration(
        color: UColors.white,
        borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
        border: Border.all(color: UColors.borderPrimary),
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.updateSearch,
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: UColors.textTertiary,
          ),
          prefixIcon: const Icon(Icons.search, color: UColors.primary),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: controller.clearSearch,
                )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: USizes.md,
            vertical: USizes.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: USizes.md),
        itemCount: controller.categories.length,
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          return Obx(() {
            final isSelected = controller.selectedCategory.value == category;
            final count = category == 'All'
                ? controller.totalApps
                : controller.appsByCategory[category] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: USizes.sm),
              child: GestureDetector(
                onTap: () => controller.selectCategory(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: USizes.md,
                    vertical: USizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? UColors.primary
                        : UColors.white,
                    borderRadius:
                        BorderRadius.circular(USizes.borderRadiusCircular),
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
                        category,
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
                          borderRadius:
                              BorderRadius.circular(USizes.borderRadiusCircular),
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
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    dynamic app,
    InstalledAppsController controller,
  ) {
    final categoryColor = controller.getCategoryColor(app.category);
    final categoryIcon = controller.getCategoryIcon(app.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: USizes.sm),
      child: URoundedContainer(
        padding: const EdgeInsets.all(USizes.sm),
        color: UColors.white,
        border: true,
        borderColor: UColors.borderSecondary,
        borderRadius: USizes.cardRadiusMd,
        onTap: () => _showAppDetailsDialog(context, app, controller),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
              ),
              child: Icon(categoryIcon, color: categoryColor, size: 26),
            ),
            const SizedBox(width: USizes.sm),

            // App details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: UColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (app.isRecentlyInstalled) ...[
                        const SizedBox(width: USizes.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: USizes.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                UColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                USizes.borderRadiusSm),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: UColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.packageName,
                    style: TextStyle(
                      fontSize: 11,
                      color: UColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: USizes.xs),
                  Row(
                    children: [
                      _buildChip(
                        icon: categoryIcon,
                        label: app.category,
                        color: categoryColor,
                      ),
                      const SizedBox(width: USizes.xs),
                      _buildChip(
                        icon: Icons.access_time,
                        label: app.installedDateFormatted,
                        color: UColors.textSecondary,
                        isNeutral: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Info icon
            const Icon(
              Icons.chevron_right,
              color: UColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isNeutral = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: USizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isNeutral ? UColors.lightGrey : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: USizes.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAppDetailsDialog(
    BuildContext context,
    dynamic app,
    InstalledAppsController controller,
  ) {
    final categoryColor = controller.getCategoryColor(app.category);
    final categoryIcon = controller.getCategoryIcon(app.category);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(USizes.cardRadiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(USizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(USizes.cardRadiusLg),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 40),
              ),
              const SizedBox(height: USizes.md),

              Text(
                app.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: UColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: USizes.xs),
              Text(
                app.packageName,
                style: TextStyle(
                  fontSize: 12,
                  color: UColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: USizes.md),

              // Details
              URoundedContainer(
                padding: const EdgeInsets.all(USizes.md),
                color: UColors.lightGrey,
                borderRadius: USizes.cardRadiusMd,
                child: Column(
                  children: [
                    _buildDetailRow('Category', app.category),
                    const SizedBox(height: USizes.sm),
                    _buildDetailRow('Version', app.versionName),
                    const SizedBox(height: USizes.sm),
                    _buildDetailRow('Installed', app.installedDateFormatted),
                    const SizedBox(height: USizes.sm),
                    _buildDetailRow(
                      'System App',
                      app.systemApp ? 'Yes' : 'No',
                    ),
                    const SizedBox(height: USizes.sm),
                    _buildDetailRow(
                      'Enabled',
                      app.enabled ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: USizes.md),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: UColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: UColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.searchQuery.value.isEmpty
                ? Icons.apps_outage
                : Icons.search_off,
            size: 80,
            color: UColors.textTertiary,
          ),
          const SizedBox(height: USizes.md),
          Text(
            controller.searchQuery.value.isEmpty
                ? 'No apps found'
                : 'No apps match "${controller.searchQuery.value}"',
            style: TextStyle(
              fontSize: 16,
              color: UColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (controller.searchQuery.value.isNotEmpty) ...[
            const SizedBox(height: USizes.md),
            TextButton(
              onPressed: controller.clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              error,
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
