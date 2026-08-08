import 'package:carecircle_parent1/features/dashboard/controller/child_deviceinfo_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class CurrentAppActiveCard extends StatelessWidget {
  const CurrentAppActiveCard({super.key, required this.childUid, });

  final String childUid;
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChildDeviceInfoController(childUid: childUid));
    final isUsing = controller.isUsingApp;
    final appName = controller.data?.currentAppName;
    final secondsAgo = controller.data?.currentAppSecondsAgo ?? 0;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Obx(
          ()=> URoundedContainer(
          padding: const EdgeInsets.all(USizes.md),
          color: isUsing
              ? UColors.primary.withValues(alpha: 0.05)
              : UColors.lightGrey,
          border: true,
          borderColor: isUsing
              ? UColors.primary.withValues(alpha: 0.3)
              : UColors.borderSecondary,
          borderRadius: USizes.cardRadiusMd,
          child: Row(
            children: [
              // App emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUsing
                      ? UColors.primary.withValues(alpha: 0.1)
                      : UColors.grey,
                  borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
                ),
                child: Center(
                  child: Text(
                    controller.data?.currentAppEmoji ?? '😴',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: USizes.md),
        
              // Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUsing ? 'Currently Using' : 'Device Status',
                      style: TextStyle(
                        fontSize: 11,
                        color: UColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.data?.currentAppStatus ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isUsing ? UColors.primary : UColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isUsing && secondsAgo > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Active ${secondsAgo}s ago',
                        style: TextStyle(
                          fontSize: 11,
                          color: UColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        
              // Live indicator
              if (isUsing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: USizes.sm,
                    vertical: USizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: UColors.success,
                    borderRadius: BorderRadius.circular(USizes.borderRadiusCircular),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: UColors.textWhite,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: USizes.xs),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: UColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


