import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/notification_model.dart';

/// 🔔 NotificationRepository — Firestore operations for child notifications
///
/// Collection: child_notifications/{childUid}/items/{autoId}
///
/// Reads:
///  - Stream today's notifications (real-time)
///  - Get by date
///  - Get recent (limit)
///  - Get by package
class NotificationRepository {
  static const _rootCollection = 'child_notifications';
  static const _subCollection = 'items';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatDateKey(DateTime date) =>
      DateFormat('dd-MM-yyyy').format(date);

  // ============ REAL-TIME STREAM ============

  /// Stream today's notifications (real-time, ordered by time desc)
  Stream<List<NotificationModel>> streamTodayNotifications(String childUid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_rootCollection)
        .doc(childUid)
        .collection(_subCollection)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(
                  doc.id,
                  Map<String, dynamic>.from(doc.data()),
                ))
            .toList());
  }

  /// Stream last N notifications (real-time)
  Stream<List<NotificationModel>> streamRecentNotifications(
    String childUid, {
    int limit = 100,
  }) {
    return _firestore
        .collection(_rootCollection)
        .doc(childUid)
        .collection(_subCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(
                  doc.id,
                  Map<String, dynamic>.from(doc.data()),
                ))
            .toList());
  }

  // ============ ONE-TIME FETCH ============

  /// Get notifications for specific date
  Future<List<NotificationModel>> getNotificationsForDate(
    String childUid,
    DateTime date,
  ) async {
    final dateKey = _formatDateKey(date);

    final snapshot = await _firestore
        .collection(_rootCollection)
        .doc(childUid)
        .collection(_subCollection)
        .where('dateKey', isEqualTo: dateKey)
        .limit(500)
        .get();

    final notifs = snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();

    notifs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return notifs;
  }

  /// Get notifications by package (for app-wise filter)
  Future<List<NotificationModel>> getByPackage(
    String childUid,
    String packageName, {
    int limit = 100,
  }) async {
    final snapshot = await _firestore
        .collection(_rootCollection)
        .doc(childUid)
        .collection(_subCollection)
        .where('packageName', isEqualTo: packageName)
        .limit(limit)
        .get();

    final notifs = snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();

    notifs.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return notifs;
  }

  /// Get notifications for last N days
  Future<List<NotificationModel>> getLastNDaysNotifications(
    String childUid, {
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection(_rootCollection)
        .doc(childUid)
        .collection(_subCollection)
        .where('timestamp', isGreaterThanOrEqualTo: cutoff)
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  // ============ STATS ============

  /// Get count of notifications grouped by app
  Future<Map<String, int>> getAppWiseCounts(String childUid) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection(_rootCollection)
        .doc(childUid)
        .collection(_subCollection)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .get();

    final counts = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final appName = data['appName'] as String? ?? 'Unknown';
      counts[appName] = (counts[appName] ?? 0) + 1;
    }

    // Sort by count descending
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted);
  }
}
