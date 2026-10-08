import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/screen_time_model.dart';
import '../../../data/repositories/features/screen_time_repository.dart';
import '../../../utils/popups/snackbars.dart';

/// 📊 ScreenTimeController — manages screen time data for a day
///
/// Production improvements:
///  ✅ Takes childUid via constructor (FIXED: was using GetStorage + hardcoded 'childId')
///  ✅ Uses repository pattern
///  ✅ Real-time stream for today's usage
///  ✅ See more/less functionality
///  ✅ Date picker for past days
///  ✅ App icon/name mapping preserved
class ScreenTimeController extends GetxController {
  ScreenTimeController({required this.childUid});

  final String childUid;

  final ScreenTimeRepository _repository = ScreenTimeRepository();

  // ============ Reactive State ============
  final Rx<ScreenTimeModel> screenTime = ScreenTimeModel.empty('').obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString error = ''.obs;

  // Date selection
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // See more/less
  final RxBool showAllApps = false.obs;
  static const int _maxAppsToShow = 4;

  StreamSubscription<ScreenTimeModel>? _subscription;

  // Known app icons (for popular apps)
  final Map<String, IconData> _appIcons = {
    'com.whatsapp': Icons.chat,
    'com.instagram.android': Icons.photo_camera,
    'com.facebook.katana': Icons.facebook,
    'com.google.android.youtube': Icons.play_circle,
    'com.spotify.music': Icons.music_note,
    'com.microsoft.teams': Icons.video_call,
    'com.google.android.apps.maps': Icons.map,
    'com.android.chrome': Icons.language,
    'com.google.android.gm': Icons.email,
    'com.google.android.apps.photos': Icons.photo,
    'com.zhiliaoapp.musically': Icons.music_video,
    'com.ubercab': Icons.local_taxi,
    'com.amazon.mShop.android.shopping': Icons.shopping_cart,
    'com.netflix.mediaclient': Icons.movie,
    'com.phonepe.app': Icons.payment,
    'com.google.android.apps.messaging': Icons.message,
  };

  final List<Color> _appColors = [
    const Color(0xFF2196F3),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF009688),
    const Color(0xFFE91E63),
    const Color(0xFF3F51B5),
    const Color(0xFF00BCD4),
    const Color(0xFFFFC107),
    const Color(0xFFFF5722),
  ];

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

  /// Initialize real-time stream for today
  void _initStream() {
    final dateKey = _repository.formatDateKey(selectedDate.value);
    screenTime.value = ScreenTimeModel.empty(dateKey);

    _subscription = _repository
        .streamUsageForDate(childUid, selectedDate.value)
        .listen(
      (data) {
        screenTime.value = data;
        error.value = '';
        isLoading.value = false;
        isRefreshing.value = false;
      },
      onError: (err) {
        error.value = 'Failed to load screen time: $err';
        isLoading.value = false;
        isRefreshing.value = false;
      },
    );
  }

  /// Switch to different date
  Future<void> fetchUsageForDate(DateTime date) async {
    selectedDate.value = date;
    isLoading.value = true;
    error.value = '';

    // Cancel old stream, start new one
    await _subscription?.cancel();
    _initStream();
  }

  /// Reset to today
  Future<void> fetchTodayUsage() async {
    await fetchUsageForDate(DateTime.now());
  }

  /// Manual refresh
  Future<void> refreshData() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      final data = await _repository.getUsageForDate(
        childUid,
        selectedDate.value,
      );
      screenTime.value = data;
      error.value = '';
    } catch (e) {
      USnackBarHelpers.errorSnackBar(
        title: 'Refresh Failed',
        message: e.toString(),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  // ============ Computed Getters ============

  int get totalScreenTimeMs => screenTime.value.totalTimeMs;

  String get totalTimeFormatted => screenTime.value.totalTimeFormatted;

  String get statusLabel => screenTime.value.statusLabel;

  Color get statusColor => Color(screenTime.value.statusColorValue);

  int get sessionCount => screenTime.value.sessionCount;

  int get totalOpenCount => screenTime.value.openCount;

  String get selectedDateFormatted =>
      DateFormat('dd-MM-yyyy').format(selectedDate.value);

  String get selectedDateDisplay {
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

  /// Get apps sorted by usage (most used first)
  List<AppUsageModel> get sortedApps => screenTime.value.sortedApps;

  /// Get visible apps (limited by showAllApps flag)
  List<AppUsageModel> get visibleApps {
    final apps = sortedApps;
    if (showAllApps.value || apps.length <= _maxAppsToShow) {
      return apps;
    }
    return apps.take(_maxAppsToShow).toList();
  }

  bool get hasMoreApps => sortedApps.length > _maxAppsToShow;

  int get remainingAppsCount => sortedApps.length - _maxAppsToShow;

  int get totalAppsCount => sortedApps.length;

  bool get hasData => screenTime.value.totalTimeMs > 0;

  int? get peakHour => screenTime.value.peakHour;

  List<DateTime> get last7Days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (index) => today.subtract(Duration(days: index)));
  }

  // ============ Actions ============

  void toggleShowAllApps() => showAllApps.toggle();

  /// Open date picker (Restricted to last 7 days)
  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate7 = today.subtract(const Duration(days: 6));

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value.isBefore(firstDate7) ? today : selectedDate.value,
      firstDate: firstDate7,
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
      await fetchUsageForDate(picked);
    }
  }

  // ============ UI Helpers ============

  String formatTime(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '<1m';
  }

  double getAppPercentage(int appTimeMs) {
    return screenTime.value.appPercentage(appTimeMs);
  }

  IconData getAppIcon(String packageName) {
    for (final entry in _appIcons.entries) {
      if (packageName.contains(entry.key)) return entry.value;
    }
    return Icons.android;
  }

  String getAppName(String packageName) {
    // Clean up package name to show friendly name
    if (packageName.contains('whatsapp')) return 'WhatsApp';
    if (packageName.contains('instagram')) return 'Instagram';
    if (packageName.contains('facebook')) return 'Facebook';
    if (packageName.contains('youtube')) return 'YouTube';
    if (packageName.contains('spotify')) return 'Spotify';
    if (packageName.contains('teams')) return 'Microsoft Teams';
    if (packageName.contains('chrome')) return 'Chrome';
    if (packageName.contains('gmail') || packageName.contains('.gm')) {
      return 'Gmail';
    }
    if (packageName.contains('photos')) return 'Google Photos';
    if (packageName.contains('maps')) return 'Google Maps';
    if (packageName.contains('tiktok') || packageName.contains('musical')) {
      return 'TikTok';
    }
    if (packageName.contains('uber')) return 'Uber';
    if (packageName.contains('amazon')) return 'Amazon';
    if (packageName.contains('netflix')) return 'Netflix';
    if (packageName.contains('phonepe')) return 'PhonePe';

    // Return last part of package name capitalized
    final parts = packageName.split('.');
    final last = parts.last;
    if (last.isEmpty) return packageName;
    return last[0].toUpperCase() + last.substring(1);
  }

  Color getAppColor(int index) {
    return _appColors[index % _appColors.length];
  }
}
