import 'package:cloud_firestore/cloud_firestore.dart';

/// 📍 ChildLiveDataModel — represents child_live_data/{childUid} document
///
/// Contains real-time device data: location, battery, network, device info.
/// Updated by child app every 60s (heartbeat) + on sync_request.
class ChildLiveDataModel {
  final double? lat;
  final double? lng;
  final double? accuracy;
  final double? speed;
  final String? address;
  final String? locationProvider;
  final bool? isCached;
  final bool? locationServiceOn;

  final int battery;
  final bool isCharging;

  final String? networkType;
  final bool hasInternet;

  final String? device;
  final String? osVersion;

  // 🆕 Essential status indicators for parents
  final String ringerMode; // 'Normal', 'Vibrate', 'Silent'
  final bool isScreenOn;
  final bool isPowerSaveMode;

  final DateTime? heartbeat;
  final DateTime? timestamp;
  final bool serviceAlive;

  final String? currentAppPackage;
  final String? currentAppName;
  final bool currentAppIsSystem;
  final int? currentAppSecondsAgo;

  ChildLiveDataModel({
    this.lat,
    this.lng,
    this.accuracy,
    this.speed,
    this.address,
    this.locationProvider,
    this.isCached,
    this.locationServiceOn,
    required this.battery,
    required this.isCharging,
    this.networkType,
    required this.hasInternet,
    this.device,
    this.osVersion,
    this.ringerMode = 'Normal',
    this.isScreenOn = false,
    this.isPowerSaveMode = false,
    this.heartbeat,
    this.timestamp,
    required this.serviceAlive,
    this.currentAppPackage,
    this.currentAppName,
    this.currentAppIsSystem = false,
    this.currentAppSecondsAgo,
  });

  factory ChildLiveDataModel.fromFirestore(Map<String, dynamic> data) {
    return ChildLiveDataModel(
      // Location
      lat: _toDouble(data['lat']),
      lng: _toDouble(data['lng']),
      accuracy: _toDouble(data['accuracy']),
      speed: _toDouble(data['speed']),
      address: data['address'] as String?,
      locationProvider: (data['locationProvider'] ?? data['provider']) as String?,
      isCached: data['isCached'] as bool?,
      locationServiceOn: data['locationServiceOn'] as bool?,

      // Battery
      battery: (data['battery'] as num?)?.toInt() ?? 0,
      isCharging: data['isCharging'] as bool? ?? false,

      // Network
      networkType: data['networkType'] as String?,
      hasInternet: data['hasInternet'] as bool? ?? false,

      // Device
      device: data['device'] as String?,
      osVersion: data['osVersion'] as String?,

      // 🆕 Status indicators
      ringerMode: data['ringerMode'] as String? ?? 'Normal',
      isScreenOn: data['isScreenOn'] as bool? ?? false,
      isPowerSaveMode: data['isPowerSaveMode'] as bool? ?? false,

      // Status
      heartbeat: (data['heartbeat'] as Timestamp?)?.toDate(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      serviceAlive: data['serviceAlive'] as bool? ?? false,

      // Current App Active
      currentAppPackage: data['currentAppPackage'] as String?,
      currentAppName: data['currentAppName'] as String?,
      currentAppIsSystem: data['currentAppIsSystem'] as bool? ?? false,
      currentAppSecondsAgo: (data['currentAppSecondsAgo'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
      'speed': speed,
      'address': address,
      'battery': battery,
      'isCharging': isCharging,
      'networkType': networkType,
      'device': device,
      'ringerMode': ringerMode,
      'isScreenOn': isScreenOn,
      'isPowerSaveMode': isPowerSaveMode,
      'heartbeat': heartbeat != null ? Timestamp.fromDate(heartbeat!) : null,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'serviceAlive': serviceAlive,
    };
  }

  /// Check if child is online (heartbeat < 5 min old)
  bool get isOnline {
    if (heartbeat == null) return false;
    final diff = DateTime.now().difference(heartbeat!);
    return diff.inMinutes < 5;
  }

  /// Online status label
  String get onlineStatus => isOnline ? 'Online' : 'Offline';

  /// Check if location is available
  bool get hasLocation => lat != null && lng != null && lat != 0.0 && lng != 0.0;

  /// Battery status text
  String get batteryStatusText {
    if (isCharging) return 'Charging';
    if (battery >= 80) return 'Full';
    if (battery >= 50) return 'Good';
    if (battery >= 20) return 'Low';
    return 'Critical';
  }

  /// Battery color (green/orange/red)
  int get batteryColorValue {
    if (isCharging) return 0xFF4CAF50; // green
    if (battery < 20) return 0xFFEF4444; // red
    if (battery < 50) return 0xFFFFA726; // orange
    return 0xFF4CAF50; // green
  }

  /// Last updated formatted
  String get lastUpdatedFormatted {
    if (timestamp == null) return 'Never';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // 🆕 Sound & Status Helpers
  bool get isPhoneSilent => ringerMode.toLowerCase() == 'silent';
  bool get isPhoneVibrate => ringerMode.toLowerCase() == 'vibrate';
  bool get isPhoneNormal => !isPhoneSilent && !isPhoneVibrate;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return null;
  }

  /// Whether child is using any app right now (within last 30 sec)
  bool get isUsingApp => currentAppName != null && currentAppName != 'Idle' &&
      (currentAppSecondsAgo ?? 999) < 30;

  /// Status label for UI
  String get currentAppStatus {
    if (currentAppName == null || currentAppName == 'Idle') {
      return 'Device idle';
    }
    if ((currentAppSecondsAgo ?? 999) > 60) {
      return 'Last used: $currentAppName';
    }
    return 'Using: $currentAppName';
  }

  /// App emoji (best guess)
  String get currentAppEmoji {
    final pkg = (currentAppPackage ?? '').toLowerCase();
    final name = (currentAppName ?? '').toLowerCase();
    if (pkg.contains('whatsapp') || name.contains('whatsapp')) return '💬';
    if (pkg.contains('instagram')) return '📷';
    if (pkg.contains('facebook')) return '👥';
    if (pkg.contains('youtube')) return '▶️';
    if (pkg.contains('spotify')) return '🎵';
    if (pkg.contains('gmail') || pkg.contains('.gm')) return '📧';
    if (pkg.contains('chrome')) return '🌐';
    if (pkg.contains('maps')) return '🗺️';
    if (pkg.contains('snapchat')) return '👻';
    if (pkg.contains('telegram')) return '✈️';
    if (pkg.contains('tiktok')) return '🎬';
    if (pkg.contains('twitter')) return '🐦';
    if (pkg.contains('linkedin')) return '💼';
    if (pkg.contains('messages') || pkg.contains('messaging')) return '📩';
    if (pkg.contains('phone') || pkg.contains('dialer')) return '📞';
    if (pkg.contains('netflix')) return '🎬';
    if (pkg.contains('amazon')) return '📦';
    if (pkg.contains('games') || pkg.contains('game')) return '🎮';
    return '📱';
  }
}
