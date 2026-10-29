import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controller/parent_drawer_controller.dart';

/// 🎨 ParentDrawer — Ultra-premium slide-out navigation bar
///
/// Features:
///  ✅ Parent profile header (avatar, name, email, badge)
///  ✅ Connected children list with live online & battery status
///  ✅ Instant switching between multiple child devices
///  ✅ Unlink child device option with safety confirmation
///  ✅ Add new child device button (+ 6-digit pairing)
///  ✅ Help & Support feature (with Coming Soon sheet)
///  ✅ Logout with confirmation dialog
class ParentDrawer extends StatelessWidget {
  const ParentDrawer({
    super.key,
    required this.activeChildUid,
  });

  final String activeChildUid;

  @override
  Widget build(BuildContext context) {
    // Put or find ParentDrawerController
    final controller = Get.isRegistered<ParentDrawerController>()
        ? Get.find<ParentDrawerController>()
        : Get.put(ParentDrawerController());

    final drawerWidth = (MediaQuery.of(context).size.width * 0.82).clamp(280.0, 360.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // 1. Premium Header
          _buildDrawerHeader(context, controller),

          // 2. Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: USizes.md, vertical: USizes.sm),
              children: [
                const SizedBox(height: USizes.sm),

                // Section Title: Connected Children
                _buildSectionHeader(
                  context: context,
                  title: 'CONNECTED CHILDREN',
                  icon: Icons.devices_rounded,
                  badgeText: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: UColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${controller.childrenList.length} Connected',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: UColors.primary,
                      ),
                    ),
                  )),
                ),

                const SizedBox(height: USizes.sm),

                // Children List
                _buildChildrenList(context, controller),

                const SizedBox(height: USizes.md),

                // Add Child Button
                _buildAddChildButton(context, controller),

                const SizedBox(height: USizes.spaceBtwSections),

                // Section: App & Support
                _buildSectionHeader(
                  context: context,
                  title: 'HELP & SUPPORT',
                  icon: Icons.support_agent_rounded,
                ),

                const SizedBox(height: USizes.xs),

                _buildHelpTile(context, controller),

                const SizedBox(height: USizes.md),

                const Divider(height: 1, color: UColors.borderPrimary),

                const SizedBox(height: USizes.md),

                // Section: Account Actions
                _buildLogoutTile(context, controller),

                const SizedBox(height: USizes.lg),
              ],
            ),
          ),

          // 3. App Version Footer
          _buildFooter(),
        ],
      ),
    );
  }

  /// 1. Premium Header with Parent info
  Widget _buildDrawerHeader(BuildContext context, ParentDrawerController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: USizes.lg,
        right: USizes.lg,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFBAB57),
            Color(0xFFF7931E),
          ],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
        ),
      ),
      child: Obx(() {
        final parent = controller.parentUser.value;
        final name = parent.name.isNotEmpty ? parent.name : 'Parent Account';
        final email = parent.email.isNotEmpty ? parent.email : '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with Avatar + Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile Avatar with double border ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF7931E),
                      ),
                    ),
                  ),
                ),

                // Close Drawer Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Parent Name
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 3),

            // Parent Email
            if (email.isNotEmpty)
              Text(
                email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 10),

            // Account Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Parent Guardian',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Section Header
  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    Widget? badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: UColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: UColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (badgeText != null) badgeText,
        ],
      ),
    );
  }

  /// Children List with live status and active highlight
  Widget _buildChildrenList(BuildContext context, ParentDrawerController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: UColors.primary, strokeWidth: 2.5),
          ),
        );
      }

      final children = controller.childrenList;

      if (children.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.phonelink_erase_rounded, size: 36, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              const Text(
                'No children devices connected yet',
                style: TextStyle(fontSize: 13, color: UColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, index) {
          final child = children[index];
          final isActive = child.uid == activeChildUid;

          return _buildChildCard(
            context: context,
            child: child,
            isActive: isActive,
            onTap: () => controller.switchActiveChild(child.uid, child.name, activeChildUid),
            onUnlink: () => controller.confirmUnlinkChild(context, child, activeChildUid),
          );
        },
      );
    });
  }

  /// Individual Child Card
  Widget _buildChildCard({
    required BuildContext context,
    required ConnectedChildInfo child,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onUnlink,
  }) {
    final initial = child.name.isNotEmpty ? child.name[0].toUpperCase() : 'C';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFF7ED) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? UColors.primary : Colors.grey.shade200,
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? UColors.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.03),
                blurRadius: isActive ? 10 : 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with Online Indicator Dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isActive
                        ? UColors.primary
                        : UColors.primary.withOpacity(0.15),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : UColors.primary,
                      ),
                    ),
                  ),
                  // Online green dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: child.isOnline ? const Color(0xFF10B981) : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Child Name + Device + Battery
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            child.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isActive ? UColors.textPrimary : const Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: UColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          child.device,
                          style: const TextStyle(
                            fontSize: 12,
                            color: UColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        // Battery icon + text
                        Icon(
                          child.isCharging
                              ? Icons.battery_charging_full_rounded
                              : Icons.battery_std_rounded,
                          size: 13,
                          color: child.battery < 20 ? Colors.red : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${child.battery}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: child.battery < 20 ? Colors.red : UColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More options menu (Unlink)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: UColors.textSecondary, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'unlink') onUnlink();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'unlink',
                    child: Row(
                      children: [
                        Icon(Icons.link_off_rounded, color: Colors.red, size: 18),
                        SizedBox(width: 10),
                        Text('Unlink Device', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Add Child Device Button
  Widget _buildAddChildButton(BuildContext context, ParentDrawerController controller) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.navigateToAddChild,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: UColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UColors.primary.withOpacity(0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: UColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Another Child',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: UColors.primary,
                      ),
                    ),
                    Text(
                      'Link device using 6-digit code',
                      style: TextStyle(
                        fontSize: 11,
                        color: UColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: UColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Help & Support Tile
  Widget _buildHelpTile(BuildContext context, ParentDrawerController controller) {
    return ListTile(
      onTap: () => controller.showHelpSheet(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.help_outline_rounded, color: Colors.blue, size: 22),
      ),
      title: const Text(
        'Help & Support',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: const Text(
        'Device pairing guide & FAQs',
        style: TextStyle(fontSize: 12, color: UColors.textSecondary),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Guide',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade900,
          ),
        ),
      ),
    );
  }

  /// Logout Tile
  Widget _buildLogoutTile(BuildContext context, ParentDrawerController controller) {
    return ListTile(
      onTap: () => controller.confirmLogout(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
      ),
      title: const Text(
        'Log Out',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Colors.red,
        ),
      ),
      subtitle: const Text(
        'Sign out from this account',
        style: TextStyle(fontSize: 12, color: UColors.textSecondary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.red),
    );
  }

  /// Footer with App Version
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            'CareCircle v1.0.0 • Secured & Encrypted',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
