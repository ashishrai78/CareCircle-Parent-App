import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../common/widgets/custom_shape/roundedBorder_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controllers/call_log_controller.dart';
import '../../../data/models/call_log_model.dart';
import 'contacts_screen.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({
    super.key,
    required this.childUid,
    this.childName,
  });

  final String childUid;
  final String? childName;

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  late final CallLogController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(CallLogController(childUid: widget.childUid));
  }

  @override
  void dispose() {
    Get.delete<CallLogController>();
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
                  ? '${widget.childName}\'s Calls'
                  : 'Call Logs',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Obx(() => Text(
                  '${controller.selectedDateLabel} • ${controller.totalCalls} calls • ${controller.missedCount} missed',
                  style: TextStyle(
                    fontSize: 12,
                    color: UColors.textSecondary,
                  ),
                )),
          ],
        ),
        actions: [
          // Manual Sync button
          IconButton(
            onPressed: () => controller.requestCallLogsSync(),
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Call Logs',
          ),
          // Contacts button
          IconButton(
            onPressed: () => Get.to(() => ContactsScreen(
              childUid: widget.childUid,
              childName: widget.childName,
            )),
            icon: const Icon(Icons.contacts),
            tooltip: 'View Contacts',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Horizontal 7-Day Selector
          _build7DaySelector(),

          // 2. Filter Tabs (All / Incoming / Outgoing / Missed)
          _buildFilterTabs(),

          // 3. Daily Stats Bar
          _buildStatsBar(),

          // 4. Calls List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoading();
              }
              if (controller.error.isNotEmpty && !controller.hasLogs) {
                return _buildError();
              }
              if (!controller.hasLogs) {
                return _buildEmpty();
              }
              if (controller.filteredLogs.isEmpty) {
                return _buildNoResultsForDay();
              }
              return _buildCallLogsList();
            }),
          ),
        ],
      ),
    );
  }

  /// 📅 Horizontal 7-Day Date Selector
  Widget _build7DaySelector() {
    final days = controller.last7Days;
    return Container(
      height: 78,
      margin: const EdgeInsets.fromLTRB(USizes.md, USizes.sm, USizes.md, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = days[index];
          return Obx(() {
            final isSelected = controller.isSameDay(controller.selectedDate.value, date);
            final callCount = controller.getCallCountForDate(date);

            final isToday = controller.isSameDay(date, DateTime.now());
            final isYesterday = controller.isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));

            String dayLabel;
            if (isToday) {
              dayLabel = 'Today';
            } else if (isYesterday) {
              dayLabel = 'Y\'day';
            } else {
              dayLabel = DateFormat('EEE').format(date);
            }

            final dayNumber = DateFormat('d').format(date);
            final monthLabel = DateFormat('MMM').format(date);

            return GestureDetector(
              onTap: () => controller.selectDate(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? UColors.primary : UColors.white,
                  borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
                  border: Border.all(
                    color: isSelected ? UColors.primary : UColors.borderPrimary,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: UColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : UColors.textSecondary,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dayNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : UColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (callCount > 0 ? UColors.primary.withValues(alpha: 0.12) : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        callCount > 0 ? '$callCount' : monthLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : (callCount > 0 ? FontWeight.w700 : FontWeight.w500),
                          color: isSelected
                              ? Colors.white
                              : (callCount > 0 ? UColors.primary : UColors.textTertiary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Obx(() => Container(
          margin: const EdgeInsets.all(USizes.md),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: UColors.white,
            borderRadius: BorderRadius.circular(USizes.borderRadiusLg),
            boxShadow: [
              BoxShadow(
                color: UColors.dark.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildFilterChip('All', CallTypeFilter.all),
              _buildFilterChip('Incoming', CallTypeFilter.incoming),
              _buildFilterChip('Outgoing', CallTypeFilter.outgoing),
              _buildFilterChip('Missed', CallTypeFilter.missed),
            ],
          ),
        ));
  }

  Widget _buildFilterChip(String label, CallTypeFilter filter) {
    final isActive = controller.activeFilter.value == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? UColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? UColors.textWhite : UColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: USizes.md),
        child: Row(
          children: [
            _buildStatChip(
              icon: Icons.phone,
              label: 'Total',
              value: '${controller.totalCalls}',
              color: UColors.primary,
            ),
            const SizedBox(width: USizes.sm),
            _buildStatChip(
              icon: Icons.call_received,
              label: 'Incoming',
              value: '${controller.incomingCount}',
              color: UColors.success,
            ),
            const SizedBox(width: USizes.sm),
            _buildStatChip(
              icon: Icons.call_made,
              label: 'Outgoing',
              value: '${controller.outgoingCount}',
              color: UColors.accent,
            ),
            const SizedBox(width: USizes.sm),
            _buildStatChip(
              icon: Icons.access_time,
              label: 'Duration',
              value: controller.totalDuration,
              color: UColors.warning,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: URoundedContainer(
        padding: const EdgeInsets.all(USizes.sm),
        color: color.withValues(alpha: 0.08),
        borderRadius: USizes.borderRadiusMd,
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: UColors.textSecondary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLogsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(USizes.md),
      itemCount: controller.filteredLogs.length,
      itemBuilder: (context, index) {
        final log = controller.filteredLogs[index];
        return _buildCallLogTile(log);
      },
    );
  }

  Widget _buildCallLogTile(CallLogModel log) {
    final hasRealName = log.contactName != null &&
        log.contactName!.trim().isNotEmpty &&
        log.contactName != 'Unknown';

    return URoundedContainer(
      margin: const EdgeInsets.only(bottom: USizes.sm),
      color: UColors.white,
      showShadow: true,
      borderRadius: USizes.cardRadiusMd,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: USizes.md,
          vertical: USizes.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(log.typeColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(USizes.borderRadiusMd),
          ),
          child: Icon(
            _getTypeIcon(log.type),
            color: Color(log.typeColor),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: log.type == CallType.missed
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: log.type == CallType.missed
                      ? UColors.error
                      : UColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: USizes.xs),
            // ⏰ 12-Hour formatted timing (e.g. 10:35 AM)
            Text(
              log.timeOfDay,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: UColors.textTertiary,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            // Display Phone Number if contact has a name
            if (hasRealName && log.phoneNumber != 'Unknown') ...[
              Text(
                log.phoneNumber,
                style: const TextStyle(
                  fontSize: 12,
                  color: UColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
            ],
            // Type & Duration
            Row(
              children: [
                Text(
                  log.typeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(log.typeColor),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' • ${log.durationFormatted}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: UColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: log.phoneNumber != 'Unknown'
            ? IconButton(
                icon: const Icon(Icons.call, size: 20),
                color: UColors.success,
                onPressed: () => controller.callNumber(log.phoneNumber),
                tooltip: 'Call back',
              )
            : const SizedBox(width: 48),
        onTap: () {
          if (log.phoneNumber != 'Unknown') {
            _showCallOptions(log);
          }
        },
      ),
    );
  }

  IconData _getTypeIcon(CallType type) {
    switch (type) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      case CallType.rejected:
        return Icons.phone_missed;
      case CallType.blocked:
        return Icons.block;
      case CallType.unknown:
        return Icons.help_outline;
    }
  }

  void _showCallOptions(CallLogModel log) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(USizes.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(USizes.cardRadiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              log.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: USizes.xs),
            Text(
              log.phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                color: UColors.textSecondary,
              ),
            ),
            const SizedBox(height: USizes.lg),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.callNumber(log.phoneNumber);
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: USizes.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      controller.smsNumber(log.phoneNumber);
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('SMS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: USizes.md),
            Center(
              child: Text(
                '${log.typeLabel} • ${log.timeOfDay} • ${log.durationFormatted}',
                style: const TextStyle(
                  fontSize: 12,
                  color: UColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: UColors.primary),
          SizedBox(height: USizes.md),
          Text(
            'Loading call logs...',
            style: TextStyle(color: UColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(USizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: UColors.error),
            const SizedBox(height: USizes.md),
            const Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: USizes.xs),
            Text(
              controller.error.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: UColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(USizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 64, color: UColors.textTertiary),
            SizedBox(height: USizes.md),
            Text(
              'No Call Logs Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: USizes.xs),
            Text(
              'Call logs will appear here when the child device detects calls.',
              textAlign: TextAlign.center,
              style: TextStyle(color: UColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsForDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_missed_outlined, size: 54, color: UColors.textTertiary),
          const SizedBox(height: USizes.md),
          Text(
            'No Calls on ${controller.selectedDateLabel}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: USizes.xs),
          Text(
            controller.isTodaySelected
                ? 'Calls made or received today will appear here.'
                : 'No call records found for this date.',
            style: const TextStyle(color: UColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
