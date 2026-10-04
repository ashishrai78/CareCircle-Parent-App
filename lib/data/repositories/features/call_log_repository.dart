import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/call_log_model.dart';

class CallLogRepository {
  static const _collection = 'call_logs';
  static const _subCollection = 'items';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CallLogModel>> streamCallLogs(String childUid, {int limit = 100}) {
    return _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallLogModel.fromMap(
                  doc.id,
                  Map<String, dynamic>.from(doc.data()),
                ))
            .toList());
  }

  Stream<List<CallLogModel>> streamTodayCallLogs(String childUid) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CallLogModel.fromMap(
                  doc.id,
                  Map<String, dynamic>.from(doc.data()),
                ))
            .toList());
  }

  Future<List<CallLogModel>> getCallLogs(
    String childUid, {
    int limit = 100,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => CallLogModel.fromMap(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  Future<List<CallLogModel>> getCallLogsForDate(
    String childUid,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(500)
        .get();

    return snapshot.docs
        .map((doc) => CallLogModel.fromMap(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  Future<List<CallLogModel>> getCallLogsByType(
    String childUid,
    String type, {
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => CallLogModel.fromMap(
              doc.id,
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  CallLogStats computeStats(List<CallLogModel> logs) {
    int incoming = 0;
    int outgoing = 0;
    int missed = 0;
    int totalDuration = 0;

    for (final log in logs) {
      switch (log.type) {
        case CallType.incoming:
          incoming++;
          totalDuration += log.duration;
          break;
        case CallType.outgoing:
          outgoing++;
          totalDuration += log.duration;
          break;
        case CallType.missed:
          missed++;
          break;
        case CallType.rejected:
          missed++;
          break;
        case CallType.blocked:
          break;
        case CallType.unknown:
          break;
      }
    }

    return CallLogStats(
      totalCalls: logs.length,
      incomingCount: incoming,
      outgoingCount: outgoing,
      missedCount: missed,
      totalDurationSeconds: totalDuration,
    );
  }
}
