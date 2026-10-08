import 'package:cloud_firestore/cloud_firestore.dart';

/// 📊 ScreenTimeModel — represents usage_data/{childUid}/daily/{date} document
class ScreenTimeModel {
  final String dateKey;
  final int totalTimeMs;
  final int sessionCount;
  final int openCount; // 🔥 Total times apps were opened today
  final Map<String, AppUsageModel> apps;
  final Map<int, int> hourlyBreakdown; // 0-23 → ms
  final DateTime? updatedAt;

  ScreenTimeModel({
    required this.dateKey,
    required this.totalTimeMs,
    required this.sessionCount,
    this.openCount = 0,
    required this.apps,
    required this.hourlyBreakdown,
    this.updatedAt,
  });

  factory ScreenTimeModel.fromFirestore(
    String dateKey,
    Map<String, dynamic> data,
  ) {
    final appsMap = data['apps'] as Map<String, dynamic>? ?? {};
    final apps = <String, AppUsageModel>{};

    for (final entry in appsMap.entries) {
      final pkg = entry.key;
      final value = entry.value;

      if (value is Map) {
        apps[pkg] = AppUsageModel.fromMap(Map<String, dynamic>.from(value));
      } else if (value is num) {
        // Legacy format: direct int ms
        apps[pkg] = AppUsageModel(totalTimeMs: value.toInt());
      }
    }

    final hourlyMap = data['hourlyBreakdown'] as Map<String, dynamic>? ?? {};
    final hourly = <int, int>{};
    for (var i = 0; i < 24; i++) {
      hourly[i] = (hourlyMap[i.toString()] as num?)?.toInt() ?? 0;
    }

    return ScreenTimeModel(
      dateKey: dateKey,
      totalTimeMs: (data['totalTime'] as num?)?.toInt() ?? 0,
      sessionCount: (data['sessionCount'] as num?)?.toInt() ?? 0,
      openCount: (data['openCount'] as num?)?.toInt() ??
          (data['totalOpenCount'] as num?)?.toInt() ??
          0,
      apps: apps,
      hourlyBreakdown: hourly,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Empty model (when no data)
  factory ScreenTimeModel.empty(String dateKey) {
    return ScreenTimeModel(
      dateKey: dateKey,
      totalTimeMs: 0,
      sessionCount: 0,
      openCount: 0,
      apps: {},
      hourlyBreakdown: {for (var i = 0; i < 24; i++) i: 0},
    );
  }

  /// Get apps sorted by usage (descending)
  List<AppUsageModel> get sortedApps {
    final list = apps.entries.toList();
    list.sort((a, b) => b.value.totalTimeMs.compareTo(a.value.totalTimeMs));
    return list.map((e) => e.value..packageName = e.key).toList();
  }

  /// Format total time as "Xh Ym" or "Ym"
  String get totalTimeFormatted {
    final hours = totalTimeMs ~/ 3600000;
    final minutes = (totalTimeMs % 3600000) ~/ 60000;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '0m';
  }

  /// Usage status: Healthy / Moderate / High
  String get statusLabel {
    final hours = totalTimeMs / 3600000;
    if (hours > 6) return 'High Usage';
    if (hours > 3) return 'Moderate Usage';
    return 'Healthy Usage';
  }

  /// Status color value (green/orange/red)
  int get statusColorValue {
    final hours = totalTimeMs / 3600000;
    if (hours > 6) return 0xFFEF4444; // red
    if (hours > 3) return 0xFFFFA726; // orange
    return 0xFF4CAF50; // green
  }

  /// Get percentage of an app's usage
  double appPercentage(int appTimeMs) {
    if (totalTimeMs == 0) return 0;
    return appTimeMs / totalTimeMs;
  }

  /// Peak usage hour (0-23)
  int? get peakHour {
    int maxHour = -1;
    int maxValue = 0;
    for (var i = 0; i < 24; i++) {
      final v = hourlyBreakdown[i] ?? 0;
      if (v > maxValue) {
        maxValue = v;
        maxHour = i;
      }
    }
    return maxHour >= 0 ? maxHour : null;
  }
}

/// 📱 AppUsageModel — represents usage of a single app on a day
class AppUsageModel {
  final int totalTimeMs;
  final int sessions;
  final int openCount; // 🔥 Number of times this app was opened
  final int? firstUsed; // Unix ms
  final int? lastUsed; // Unix ms
  String packageName; // Set by parent

  AppUsageModel({
    required this.totalTimeMs,
    this.sessions = 0,
    this.openCount = 0,
    this.firstUsed,
    this.lastUsed,
    this.packageName = '',
  });

  factory AppUsageModel.fromMap(Map<String, dynamic> data) {
    return AppUsageModel(
      totalTimeMs: (data['totalTime'] as num?)?.toInt() ?? 0,
      sessions: (data['sessions'] as num?)?.toInt() ?? 0,
      openCount: (data['openCount'] as num?)?.toInt() ??
          (data['launchCount'] as num?)?.toInt() ??
          (data['timesOpened'] as num?)?.toInt() ??
          0,
      firstUsed: (data['firstUsed'] as num?)?.toInt(),
      lastUsed: (data['lastUsed'] as num?)?.toInt(),
    );
  }

  /// Format time as "Xh Ym" or "Ym"
  String get timeFormatted {
    final hours = totalTimeMs ~/ 3600000;
    final minutes = (totalTimeMs % 3600000) ~/ 60000;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '<1m';
  }

  /// Format open count as "X open" or "X opens"
  String get openCountFormatted =>
      '$openCount ${openCount == 1 ? "open" : "opens"}';
}
