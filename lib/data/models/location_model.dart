import 'package:cloud_firestore/cloud_firestore.dart';

/// 📍 LocationModel — represents a single location point
///
/// Used for both:
///  - Live location (from child_live_data/{childUid})
///  - Location history (from location_history/{childUid}/history/{autoId})
///
/// Supports multiple location types:
///  - GPS / Fused (accurate — 5-10m)
///  - Cell Tower Resolved (approximate — 1-5 km, via OpenCellID API)
///  - Cell Tower Basic (operator info only — no lat/lng)
///  - Cached (last known — up to 24h old)
class LocationModel {
  final double lat;
  final double lng;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? bearing;
  final String? address;
  final bool? isMock;
  final String? provider;
  final DateTime timestamp;
  final int? battery;

  // 🔥 New fields for cell tower + location state
  final bool? isApproximate;
  final bool? isCached;
  final bool? locationServiceOn;
  final CellInfo? cellInfo;

  LocationModel({
    required this.lat,
    required this.lng,
    this.accuracy,
    this.altitude,
    this.speed,
    this.bearing,
    this.address,
    this.isMock,
    this.provider,
    required this.timestamp,
    this.battery,
    this.isApproximate,
    this.isCached,
    this.locationServiceOn,
    this.cellInfo,
  });

  /// From child_live_data document
  factory LocationModel.fromLiveData(Map<String, dynamic> data) {
    final provider = data['locationProvider'] as String? ??
        data['provider'] as String?;

    return LocationModel(
      lat: _toDouble(data['lat']) ?? 0.0,
      lng: _toDouble(data['lng']) ?? 0.0,
      accuracy: _toDouble(data['accuracy']),
      altitude: _toDouble(data['altitude']),
      speed: _toDouble(data['speed']),
      bearing: _toDouble(data['bearing']),
      address: data['address'] as String?,
      isMock: data['isMock'] as bool?,
      provider: provider,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
          (data['heartbeat'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      battery: (data['battery'] as num?)?.toInt(),
      isApproximate: data['isApproximate'] as bool?,
      isCached: data['isCached'] as bool?,
      locationServiceOn: data['locationServiceOn'] as bool?,
      cellInfo: data['cellInfo'] != null
          ? CellInfo.fromMap(Map<String, dynamic>.from(data['cellInfo'] as Map))
          : null,
    );
  }

  /// From location_history/{childUid}/history/{autoId} document
  factory LocationModel.fromHistory(
    String docId,
    Map<String, dynamic> data,
  ) {
    final provider = data['provider'] as String? ??
        data['locationProvider'] as String?;

    return LocationModel(
      lat: _toDouble(data['lat']) ?? 0.0,
      lng: _toDouble(data['lng']) ?? 0.0,
      accuracy: _toDouble(data['accuracy']),
      altitude: _toDouble(data['altitude']),
      speed: _toDouble(data['speed']),
      bearing: _toDouble(data['bearing']),
      address: data['address'] as String?,
      isMock: data['isMock'] as bool?,
      provider: provider,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      battery: (data['battery'] as num?)?.toInt(),
      isApproximate: data['isApproximate'] as bool?,
      isCached: data['isCached'] as bool?,
      locationServiceOn: data['locationServiceOn'] as bool?,
      cellInfo: data['cellInfo'] != null
          ? CellInfo.fromMap(Map<String, dynamic>.from(data['cellInfo'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'bearing': bearing,
      'address': address,
      'isMock': isMock,
      'provider': provider,
      'timestamp': Timestamp.fromDate(timestamp),
      if (battery != null) 'battery': battery,
      if (isApproximate != null) 'isApproximate': isApproximate,
      if (isCached != null) 'isCached': isCached,
      if (locationServiceOn != null) 'locationServiceOn': locationServiceOn,
      if (cellInfo != null) 'cellInfo': cellInfo!.toMap(),
    };
  }

  // ============ Location Type Detection ============

  /// Whether location is valid (has actual lat/lng, not 0,0)
  bool get isValid => lat != 0.0 || lng != 0.0;

  /// Whether location is likely spoofed
  bool get isMocked => isMock ?? false;

  /// Whether location is approximate (cell tower based, not GPS)
  bool get isApproximateLocation => isApproximate ?? false;

  /// Whether location is from cache (old)
  bool get isFromCache => isCached ?? false;

  /// Whether device's location service is currently ON
  bool get isLocationServiceOn => locationServiceOn ?? true;

  /// Whether this location has cell tower info
  bool get hasCellInfo => cellInfo != null;

  /// Location type — used for UI display
  LocationType get locationType {
    if (provider == null) return LocationType.unknown;

    final p = provider!.toLowerCase();

    // Cached locations
    if (p.startsWith('cached_')) {
      return LocationType.cached;
    }

    // Cell tower resolved (got lat/lng from OpenCellID)
    if (p.contains('cell_tower') && p.contains('resolved')) {
      return LocationType.cellTowerResolved;
    }

    // Cell tower basic (only operator info, no lat/lng)
    if (p.contains('cell_tower') && p.contains('unresolved')) {
      return LocationType.cellTowerBasic;
    }

    // Cell tower partial (got cell info but couldn't parse)
    if (p.contains('cell_tower') && p.contains('partial')) {
      return LocationType.cellTowerBasic;
    }

    // GPS / Fused (accurate)
    if (p == 'fused' || p == 'gps' || p == 'network') {
      return LocationType.gps;
    }

    return LocationType.unknown;
  }

  /// Whether this location can be shown on map
  bool get canShowOnMap {
    return isValid && locationType != LocationType.cellTowerBasic;
  }

  // ============ Computed Properties ============

  /// Google Maps URL (opens in browser or Google Maps app)
  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  /// Google Maps directions URL (from current location)
  String get googleMapsDirectionsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

  /// Google Maps geo URI (Android intent)
  String get geoUri => 'geo:$lat,$lng?q=$lat,$lng';

  /// Formatted coordinates
  String get coordinatesFormatted =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  /// Time ago formatted (e.g., "2 min ago", "1 hour ago")
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Time of day formatted (e.g., "14:30")
  String get timeOfDay {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Date + time formatted (e.g., "14 Jul 2026, 14:30")
  String get dateTimeFormatted {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}, ${timeOfDay}';
  }

  /// Accuracy label (e.g., "±12m" for GPS, "~5 km" for cell tower)
  String get accuracyLabel {
    if (accuracy == null || accuracy == 0.0) {
      if (locationType == LocationType.cellTowerBasic) {
        return 'No GPS';
      }
      return 'Unknown';
    }

    // Cell tower resolved — show in km
    if (locationType == LocationType.cellTowerResolved) {
      final km = (accuracy! / 1000).round();
      return '~$km km';
    }

    // GPS — show in meters
    return '±${accuracy!.toStringAsFixed(0)}m';
  }

  /// Speed label (e.g., "5.2 km/h")
  String get speedLabel {
    if (speed == null || speed == 0.0) return 'Stationary';
    final kmh = speed! * 3.6; // m/s to km/h
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  /// Provider label (human-readable)
  String get providerLabel {
    switch (locationType) {
      case LocationType.gps:
        return 'GPS';
      case LocationType.cellTowerResolved:
        return 'Cell Tower';
      case LocationType.cellTowerBasic:
        return cellInfo?.operatorName ?? 'Network Only';
      case LocationType.cached:
        return 'Cached';
      case LocationType.unknown:
        return provider?.toUpperCase() ?? 'Unknown';
    }
  }

  /// Provider icon (for UI)
  String get providerIcon {
    switch (locationType) {
      case LocationType.gps:
        return '📡';
      case LocationType.cellTowerResolved:
        return '📶';
      case LocationType.cellTowerBasic:
        return '📵';
      case LocationType.cached:
        return '💾';
      case LocationType.unknown:
        return '❓';
    }
  }

  /// Status message for UI (e.g., "Location service is OFF")
  String get statusMessage {
    if (!isLocationServiceOn) {
      if (locationType == LocationType.cellTowerBasic) {
        return 'Location is OFF — showing network: ${cellInfo?.operatorName ?? "Unknown"}';
      }
      if (locationType == LocationType.cellTowerResolved) {
        return 'Location is OFF — approximate location via cell tower';
      }
      if (locationType == LocationType.cached) {
        return 'Location is OFF — showing last cached location';
      }
      return 'Location is OFF on child device';
    }
    return '';
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return null;
  }
}

/// 📡 CellInfo — represents cell tower information
class CellInfo {
  final int mcc;
  final int mnc;
  final int cellId;
  final int lac;
  final int signalStrength;
  final String cellType;
  final String networkOperator;
  final String operatorName;
  final String? simOperator;
  final String? simOperatorName;
  final int cellCount;
  final String? note;

  CellInfo({
    required this.mcc,
    required this.mnc,
    required this.cellId,
    required this.lac,
    required this.signalStrength,
    required this.cellType,
    required this.networkOperator,
    required this.operatorName,
    this.simOperator,
    this.simOperatorName,
    required this.cellCount,
    this.note,
  });

  factory CellInfo.fromMap(Map<String, dynamic> map) {
    return CellInfo(
      mcc: (map['mcc'] as num?)?.toInt() ?? 0,
      mnc: (map['mnc'] as num?)?.toInt() ?? 0,
      cellId: (map['cellId'] as num?)?.toInt() ?? 0,
      lac: (map['lac'] as num?)?.toInt() ?? 0,
      signalStrength: (map['signalStrength'] as num?)?.toInt() ?? 0,
      cellType: map['cellType'] as String? ?? 'unknown',
      networkOperator: map['networkOperator'] as String? ?? '000000',
      operatorName: map['operatorName'] as String? ?? 'Unknown',
      simOperator: map['simOperator'] as String?,
      simOperatorName: map['simOperatorName'] as String?,
      cellCount: (map['cellCount'] as num?)?.toInt() ?? 0,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mcc': mcc,
      'mnc': mnc,
      'cellId': cellId,
      'lac': lac,
      'signalStrength': signalStrength,
      'cellType': cellType,
      'networkOperator': networkOperator,
      'operatorName': operatorName,
      if (simOperator != null) 'simOperator': simOperator,
      if (simOperatorName != null) 'simOperatorName': simOperatorName,
      'cellCount': cellCount,
      if (note != null) 'note': note,
    };
  }

  /// Signal strength label (e.g., "Excellent", "Good", "Weak")
  String get signalLabel {
    if (signalStrength == 0) return 'Unknown';
    if (signalStrength >= -70) return 'Excellent';
    if (signalStrength >= -85) return 'Good';
    if (signalStrength >= -100) return 'Fair';
    if (signalStrength >= -110) return 'Poor';
    return 'Very Poor';
  }
}

/// 📍 LocationType — categorizes different location sources
enum LocationType {
  gps,                  // Accurate GPS / FusedLocation (5-10m)
  cellTowerResolved,    // Cell tower + OpenCellID lookup (1-5 km)
  cellTowerBasic,       // Only operator info (no lat/lng)
  cached,               // Old cached location
  unknown,              // Unknown / not yet determined
}

/// 📊 LocationStats — aggregated stats for a date range
class LocationStats {
  final int totalPoints;
  final double? distanceTraveledKm;
  final LocationModel? firstLocation;
  final LocationModel? lastLocation;
  final Duration? activeDuration;

  LocationStats({
    required this.totalPoints,
    this.distanceTraveledKm,
    this.firstLocation,
    this.lastLocation,
    this.activeDuration,
  });

  String get distanceFormatted {
    if (distanceTraveledKm == null) return '0 km';
    if (distanceTraveledKm! < 1) {
      return '${(distanceTraveledKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceTraveledKm!.toStringAsFixed(2)} km';
  }
}
