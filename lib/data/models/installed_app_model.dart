import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 📱 InstalledAppModel — represents one app in installed_apps/{childUid}.apps
class InstalledAppModel {
  final String packageName;
  final String name;
  final String versionName;
  final int versionCode;
  final String category;
  final bool systemApp;
  final int installedAt; // Unix ms
  final int updatedAt; // Unix ms
  final bool enabled;
  final int minSdk;
  final int targetSdk;
  final Uint8List? iconBytes; // Decoded from base64 (legacy) or fetched from Storage
  final String? iconUrl; // Firebase Storage URL (new)

  InstalledAppModel({
    required this.packageName,
    required this.name,
    required this.versionName,
    required this.versionCode,
    required this.category,
    required this.systemApp,
    required this.installedAt,
    required this.updatedAt,
    required this.enabled,
    required this.minSdk,
    required this.targetSdk,
    this.iconBytes,
    this.iconUrl,
  });

  factory InstalledAppModel.fromMap(String packageName, Map<String, dynamic> data) {
    return InstalledAppModel(
      packageName: packageName,
      name: data['name'] as String? ?? 'Unknown',
      versionName: data['versionName'] as String? ?? '',
      versionCode: (data['versionCode'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? 'OTHER',
      systemApp: data['systemApp'] as bool? ?? false,
      installedAt: (data['installedAt'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as num?)?.toInt() ?? 0,
      enabled: data['enabled'] as bool? ?? true,
      minSdk: (data['minSdk'] as num?)?.toInt() ?? 0,
      targetSdk: (data['targetSdk'] as num?)?.toInt() ?? 0,
      iconUrl: data['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'versionName': versionName,
      'versionCode': versionCode,
      'category': category,
      'systemApp': systemApp,
      'installedAt': installedAt,
      'updatedAt': updatedAt,
      'enabled': enabled,
      'minSdk': minSdk,
      'targetSdk': targetSdk,
      if (iconUrl != null) 'iconUrl': iconUrl,
    };
  }

  /// Format installed date as "X days/weeks/months ago"
  String get installedDateFormatted {
    if (installedAt == 0) return 'Unknown';

    final date = DateTime.fromMillisecondsSinceEpoch(installedAt);
    final diff = DateTime.now().difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    final years = (diff.inDays / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  }

  /// Whether app is recently installed (< 7 days)
  bool get isRecentlyInstalled {
    if (installedAt == 0) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(installedAt);
    return DateTime.now().difference(date).inDays < 7;
  }
}

/// 📦 InstalledAppsCollectionModel — represents installed_apps/{childUid} doc
class InstalledAppsCollectionModel {
  final int appCount;
  final List<InstalledAppModel> apps;
  final DateTime? updatedAt;

  InstalledAppsCollectionModel({
    required this.appCount,
    required this.apps,
    this.updatedAt,
  });

  factory InstalledAppsCollectionModel.fromFirestore(
    Map<String, dynamic> data,
  ) {
    final appsMap = data['apps'] as Map<String, dynamic>? ?? {};
    final apps = appsMap.entries
        .map((e) => InstalledAppModel.fromMap(
              e.key,
              Map<String, dynamic>.from(e.value as Map),
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return InstalledAppsCollectionModel(
      appCount: (data['appCount'] as num?)?.toInt() ?? apps.length,
      apps: apps,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}


