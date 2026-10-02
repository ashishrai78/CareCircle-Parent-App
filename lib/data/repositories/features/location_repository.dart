import 'package:cloud_firestore/cloud_firestore.dart';

// Math extensions for haversine
import 'dart:math' show cos, sqrt, atan2;

import '../../models/location_model.dart';
extension on double{double cos() => cos();}

/// 📍 LocationRepository — Firestore operations for child's location
///
/// Reads from:
///  - child_live_data/{childUid}  → real-time live location
///  - location_history/{childUid}/history/{autoId}  → past locations
class LocationRepository {
  static const _liveDataCollection = 'child_live_data';
  static const _historyCollection = 'location_history';
  static const _historySubCollection = 'history';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ LIVE LOCATION ============

  /// Stream child's live location (real-time)
  Stream<LocationModel?> streamLiveLocation(String childUid) {
    return _firestore
        .collection(_liveDataCollection)
        .doc(childUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = Map<String, dynamic>.from(snapshot.data()!);

      // Check if location data exists (lat/lng may be 0 for cell_tower_basic)
      if (data['lat'] == null && data['lng'] == null) return null;

      return LocationModel.fromLiveData(data);
    });
  }

  /// Get child's live location (one-time fetch)
  Future<LocationModel?> getLiveLocation(String childUid) async {
    final snapshot =
        await _firestore.collection(_liveDataCollection).doc(childUid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final data = Map<String, dynamic>.from(snapshot.data()!);
    if (data['lat'] == null && data['lng'] == null) return null;
    return LocationModel.fromLiveData(data);
  }

  /// 🔥 Request sync from child device (sets sync_request = true)
  Future<void> requestSync(String childUid) async {
    await _firestore.collection('child_control').doc(childUid).set({
      'sync_request': true,
      'sync_requested_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============ LOCATION HISTORY ============

  /// Get location history for today (real-time stream)
  Stream<List<LocationModel>> streamTodayHistory(String childUid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_historyCollection)
        .doc(childUid)
        .collection(_historySubCollection)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromHistory(
                  doc.id,
                  Map<String, dynamic>.from(doc.data()),
                ))
            .toList());
  }

  /// Get location history for specific date
  Future<List<LocationModel>> getHistoryForDate(
    String childUid,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_historyCollection)
        .doc(childUid)
        .collection(_historySubCollection)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(500)
        .get();

    return snapshot.docs
        .map((doc) => LocationModel.fromHistory(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  /// Get last N location points (most recent first)
  Future<List<LocationModel>> getRecentHistory(
    String childUid, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection(_historyCollection)
        .doc(childUid)
        .collection(_historySubCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => LocationModel.fromHistory(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  /// Get last N days of history (for stats)
  Future<List<LocationModel>> getLastNDaysHistory(
    String childUid, {
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection(_historyCollection)
        .doc(childUid)
        .collection(_historySubCollection)
        .where('timestamp', isGreaterThanOrEqualTo: cutoff)
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .get();

    return snapshot.docs
        .map((doc) => LocationModel.fromHistory(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  /// Compute stats from a list of locations (only valid GPS points)
  LocationStats computeStats(List<LocationModel> locations) {
    final validLocations = locations.where((l) => l.isValid).toList();

    if (validLocations.isEmpty) {
      return LocationStats(totalPoints: locations.length);
    }

    // Sort ascending by time
    final sorted = List<LocationModel>.from(validLocations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double distance = 0;
    for (var i = 1; i < sorted.length; i++) {
      distance += _haversineDistance(
        sorted[i - 1].lat,
        sorted[i - 1].lng,
        sorted[i].lat,
        sorted[i].lng,
      );
    }

    return LocationStats(
      totalPoints: locations.length,
      distanceTraveledKm: distance,
      firstLocation: sorted.first,
      lastLocation: sorted.last,
      activeDuration: sorted.last.timestamp.difference(sorted.first.timestamp),
    );
  }

  /// Haversine distance between two lat/lng points (in km)
  double _haversineDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    final a = (dLat / 2) * (dLat / 2) +
        _degreesToRadians(lat1).cos() *
            _degreesToRadians(lat2).cos() *
            (dLng / 2) *
            (dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }
}
