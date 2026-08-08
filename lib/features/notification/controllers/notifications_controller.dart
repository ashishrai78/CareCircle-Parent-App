import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/features/notification_repository.dart';
import '../../../utils/popups/snackbars.dart';

/// 📢 NotificationsController — manages notifications list with filter + search
///
/// Features:
///  ✅ Real-time stream (today's notifications)
///  ✅ Search by app name / title / text
///  ✅ Filter by app (chips)
///  ✅ Stats (total today, per-app count)
///  ✅ Date picker (past days)
///  ✅ Auto-refresh on data change
class NotificationsController extends GetxController {
  NotificationsController({required this.childUid});

  final String childUid;

  final NotificationRepository _repository = NotificationRepository();

  // ============ Reactive State ============
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  // Search & Filter
  final RxString searchQuery = ''.obs;
  final RxString selectedApp = 'All'.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Stats
  final RxMap<String, int> appCounts = <String, int>{}.obs;
  final RxInt totalCount = 0.obs;

  StreamSubscription<List<NotificationModel>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _initStream();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Initialize real-time stream
  void _initStream() {
    final isToday = _isSameDay(selectedDate.value, DateTime.now());

    if (isToday) {
      // Real-time stream for today
      _subscription = _repository.streamTodayNotifications(childUid).listen(
        (data) {
          notifications.value = data;
          error.value = '';
          isLoading.value = false;
          isRefreshing.value = false;
          _computeStats(data);
        },
        onError: (err) {
          error.value = 'Failed to load notifications: $err';
          isLoading.value = false;
          isRefreshing.value = false;
        },
      );
    } else {
      // One-time fetch for past date
      _fetchForDate(selectedDate.value);
    }
  }

  /// Fetch notifications for specific date (one-time)
  Future<void> _fetchForDate(DateTime date) async {
    try {
      isLoading.value = true;
      error.value = '';

      final data = await _repository.getNotificationsForDate(childUid, date);
      notifications.value = data;
      _computeStats(data);
    } catch (e) {
      error.value = 'Failed to load: $e';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Compute stats from list
  void _computeStats(List<NotificationModel> notifs) {
    totalCount.value = notifs.length;

    final counts = <String, int>{};
    for (final n in notifs) {
      final app = n.appName;
      counts[app] = (counts[app] ?? 0) + 1;
    }

    // Sort by count descending
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    appCounts.value = Map.fromEntries(sorted);
  }

  // ============ ACTIONS ============

  /// Switch date
  Future<void> changeDate(DateTime date) async {
    selectedDate.value = date;
    await _subscription?.cancel();
    _subscription = null;
    isLoading.value = true;
    _initStream();
  }

  /// Reset to today
  Future<void> resetToToday() async {
    await changeDate(DateTime.now());
  }

  /// Manual refresh
  Future<void> refreshData() async {
    isRefreshing.value = true;
    if (_isSameDay(selectedDate.value, DateTime.now())) {
      // Stream auto-refreshes — just clear isRefreshing flag
      await Future.delayed(const Duration(milliseconds: 500));
      isRefreshing.value = false;
    } else {
      await _fetchForDate(selectedDate.value);
    }
  }

  void updateSearch(String query) => searchQuery.value = query;

  void clearSearch() => searchQuery.value = '';

  void selectApp(String app) => selectedApp.value = app;

  // ============ COMPUTED GETTERS ============

  /// Filtered notifications based on search + app filter
  List<NotificationModel> get filteredNotifications {
    var result = notifications.toList();

    // Filter by app
    if (selectedApp.value != 'All') {
      result = result.where((n) => n.appName == selectedApp.value).toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((n) {
        return n.appName.toLowerCase().contains(query) ||
            n.title.toLowerCase().contains(query) ||
            n.text.toLowerCase().contains(query) ||
            n.packageName.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  /// List of unique apps for filter chips
  List<String> get appList {
    final apps = <String>['All'];
    apps.addAll(appCounts.keys);
    return apps;
  }

  /// Top 5 apps by notification count (for stats card)
  Map<String, int> get topApps {
    final entries = appCounts.entries.take(5);
    return Map.fromEntries(entries);
  }

  /// Whether selected date is today
  bool get isToday => _isSameDay(selectedDate.value, DateTime.now());

  /// Selected date display label
  String get selectedDateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final diff = today.difference(selected).inDays;
    if (diff < 7) return '$diff days ago';

    return DateFormat('dd MMM yyyy').format(selectedDate.value);
  }

  /// Has any notifications
  bool get hasNotifications => notifications.isNotEmpty;

  /// Has filtered results
  bool get hasFilteredResults => filteredNotifications.isNotEmpty;

  // ============ HELPERS ============

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Show notification details
  void openDetails(NotificationModel notification) {
    USnackBarHelpers.infoSnackBar(
      title: notification.appName,
      message: notification.displayText,
      duration: 4,
    );
    // Or navigate to detail screen:
    // Get.to(() => NotificationDetailScreen(notification: notification));
  }

  /// Open date picker
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDate.value,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Get.theme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await changeDate(picked);
    }
  }
}

