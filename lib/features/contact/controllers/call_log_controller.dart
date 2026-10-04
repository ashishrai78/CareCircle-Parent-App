import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/call_log_model.dart';
import '../../../data/repositories/features/call_log_repository.dart';
import '../../../utils/popups/snackbars.dart';

class CallLogController extends GetxController {
  CallLogController({required this.childUid});

  final String childUid;
  final CallLogRepository _repository = CallLogRepository();

  /// All call logs streamed from Firestore (last 7 days retention)
  final RxList<CallLogModel> allLogs = <CallLogModel>[].obs;

  /// Logs filtered by selectedDate and activeFilter
  final RxList<CallLogModel> filteredLogs = <CallLogModel>[].obs;

  /// Currently selected calendar date (defaults to today)
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  /// Daily stats computed for the selectedDate
  final Rx<CallLogStats?> dailyStats = Rx<CallLogStats?>(null);

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final Rx<CallTypeFilter> activeFilter = CallTypeFilter.all.obs;

  StreamSubscription<List<CallLogModel>>? _logsSub;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    _initStream();
  }

  @override
  void onClose() {
    _logsSub?.cancel();
    super.onClose();
  }

  void _initStream() {
    _logsSub = _repository.streamCallLogs(childUid, limit: 300).listen(
      (data) {
        allLogs.value = data;
        _applyFilters();
        error.value = '';
        isLoading.value = false;
      },
      onError: (err) {
        error.value = 'Error loading call logs: $err';
        isLoading.value = false;
      },
    );
  }

  /// List of the last 7 calendar days (Today, Yesterday, ..., 6 days ago)
  List<DateTime> get last7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (index) => today.subtract(Duration(days: index)));
  }

  /// Select a date from the 7-day selector
  void selectDate(DateTime date) {
    selectedDate.value = DateTime(date.year, date.month, date.day);
    _applyFilters();
  }

  /// Check if two timestamps fall on the same calendar day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get call count for a specific date (to display badge count on 7-day pill)
  int getCallCountForDate(DateTime date) {
    return allLogs.where((l) => isSameDay(l.timestamp, date)).length;
  }

  void _applyFilters() {
    // 1. Filter logs for the selected day
    final dayLogs = allLogs.where((l) => isSameDay(l.timestamp, selectedDate.value)).toList();

    // 2. Compute stats for this specific day
    dailyStats.value = _repository.computeStats(dayLogs);

    // 3. Filter by call type (All / Incoming / Outgoing / Missed)
    var result = dayLogs;
    switch (activeFilter.value) {
      case CallTypeFilter.all:
        break;
      case CallTypeFilter.incoming:
        result = result.where((l) => l.type == CallType.incoming).toList();
        break;
      case CallTypeFilter.outgoing:
        result = result.where((l) => l.type == CallType.outgoing).toList();
        break;
      case CallTypeFilter.missed:
        result = result.where((l) =>
            l.type == CallType.missed || l.type == CallType.rejected).toList();
        break;
    }

    filteredLogs.value = result;
  }

  void setFilter(CallTypeFilter filter) {
    activeFilter.value = filter;
    _applyFilters();
  }

  /// Request Child device to sync fresh call logs
  Future<void> requestCallLogsSync() async {
    try {
      await FirebaseFirestore.instance
          .collection('child_control')
          .doc(childUid)
          .set({'call_logs_sync_request': true}, SetOptions(merge: true));

      USnackBarHelpers.successSnackBar(
        title: 'Sync Requested',
        message: 'Child device will sync call logs shortly.',
      );
    } catch (e) {
      USnackBarHelpers.errorSnackBar(
        title: 'Sync Failed',
        message: '$e',
      );
    }
  }

  Future<void> callNumber(String phoneNumber) async {
    if (phoneNumber == 'Unknown' || phoneNumber.isEmpty) {
      USnackBarHelpers.warningSnackBar(
        title: 'Cannot Call',
        message: 'Phone number not available',
      );
      return;
    }

    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not make call',
      );
    }
  }

  Future<void> smsNumber(String phoneNumber) async {
    if (phoneNumber == 'Unknown' || phoneNumber.isEmpty) {
      USnackBarHelpers.warningSnackBar(
        title: 'Cannot SMS',
        message: 'Phone number not available',
      );
      return;
    }

    final url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      USnackBarHelpers.errorSnackBar(
        title: 'Error',
        message: 'Could not open SMS',
      );
    }
  }

  // ============ GETTERS ============

  bool get isTodaySelected {
    final now = DateTime.now();
    return isSameDay(selectedDate.value, now);
  }

  String get selectedDateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(selectedDate.value).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(selectedDate.value);
  }

  int get totalCalls => dailyStats.value?.totalCalls ?? 0;
  int get missedCount => dailyStats.value?.missedCount ?? 0;
  int get incomingCount => dailyStats.value?.incomingCount ?? 0;
  int get outgoingCount => dailyStats.value?.outgoingCount ?? 0;
  String get totalDuration => dailyStats.value?.totalDurationFormatted ?? '0 min';

  bool get hasLogs => allLogs.isNotEmpty;
  bool get hasDailyLogs => filteredLogs.isNotEmpty;
}

enum CallTypeFilter {
  all,
  incoming,
  outgoing,
  missed,
}
