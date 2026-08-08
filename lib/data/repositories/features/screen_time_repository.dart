import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/screen_time_model.dart';

/// 📊 ScreenTimeRepository — Firestore operations for usage_data/{childUid}/daily/{date}
class ScreenTimeRepository {
  static const _collection = 'usage_data';
  static const _subCollection = 'daily';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Format date as dd-MM-yyyy (used as document ID)
  String formatDateKey(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Get screen time for specific date (one-time fetch)
  Future<ScreenTimeModel> getUsageForDate(
    String childUid,
    DateTime date,
  ) async {
    final dateKey = formatDateKey(date);
    final snapshot = await _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .doc(dateKey)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return ScreenTimeModel.empty(dateKey);
    }

    return ScreenTimeModel.fromFirestore(
      dateKey,
      Map<String, dynamic>.from(snapshot.data()!),
    );
  }

  /// Get today's screen time (one-time fetch)
  Future<ScreenTimeModel> getTodayUsage(String childUid) {
    return getUsageForDate(childUid, DateTime.now());
  }

  /// Stream screen time for specific date (real-time)
  Stream<ScreenTimeModel> streamUsageForDate(
    String childUid,
    DateTime date,
  ) {
    final dateKey = formatDateKey(date);
    return _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .doc(dateKey)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return ScreenTimeModel.empty(dateKey);
      }
      return ScreenTimeModel.fromFirestore(
        dateKey,
        Map<String, dynamic>.from(snapshot.data()!),
      );
    });
  }

  /// Stream today's screen time (real-time)
  Stream<ScreenTimeModel> streamTodayUsage(String childUid) {
    return streamUsageForDate(childUid, DateTime.now());
  }

  /// Get last N days usage (one-time fetch)
  Future<List<ScreenTimeModel>> getLastNDaysUsage(
    String childUid,
    int days,
  ) async {
    final now = DateTime.now();
    final futures = <Future<ScreenTimeModel>>[];

    for (var i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      futures.add(getUsageForDate(childUid, date));
    }

    final results = await Future.wait(futures);
    return results; // Oldest first, today last
  }
}
