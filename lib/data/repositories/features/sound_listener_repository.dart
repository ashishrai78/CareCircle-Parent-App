import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/services/webrtc_config.dart';

/// 🎤 SoundListenerRepository — Firestore operations for mic listening commands
///
/// Parent → Child signaling via child_control/{childUid}:
///  - sync_mic: true/false  (start/stop mic)
///  - call_id: WebRTC session ID
///
/// Parent → Child → Parent WebRTC signaling via calls/{callId}:
///  - offer: parent's WebRTC offer
///  - answer: child's WebRTC answer
///  - callerCandidates: parent's ICE candidates
///  - calleeCandidates: child's ICE candidates
class SoundListenerRepository {
  static const _controlCollection = WebRTCConfig.childControlCollection;
  static const _callsCollection = WebRTCConfig.callsCollection;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ PARENT → CHILD COMMANDS ============

  /// Start mic listening — writes sync_mic=true + call_id to child_control
  Future<void> startMicListening({
    required String childUid,
    required String callId,
  }) async {
    await _firestore.collection(_controlCollection).doc(childUid).set({
      'sync_mic': true,
      'call_id': callId,
      'listening_started_at': FieldValue.serverTimestamp(),
      'listening_initiated_by': 'parent',
    }, SetOptions(merge: true));
  }

  /// Stop mic listening — clears sync_mic flag + deletes call_id
  Future<void> stopMicListening(String childUid) async {
    await _firestore.collection(_controlCollection).doc(childUid).set({
      'sync_mic': false,
      'call_id': FieldValue.delete(),
      'listening_stopped_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check if child device is online (heartbeat < 5 min old)
  Future<bool> isChildOnline(String childUid) async {
    try {
      final doc = await _firestore
          .collection('child_live_data')
          .doc(childUid)
          .get();

      if (!doc.exists || doc.data() == null) return false;

      final data = doc.data()!;
      final heartbeat = data['heartbeat'] as Timestamp?;
      if (heartbeat == null) return false;

      final diff = DateTime.now().difference(heartbeat.toDate());
      return diff.inMinutes < 5;
    } catch (_) {
      return false;
    }
  }

  /// Stream child_control document (to monitor sync_mic state)
  Stream<Map<String, dynamic>?> streamChildControl(String childUid) {
    return _firestore
        .collection(_controlCollection)
        .doc(childUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Map<String, dynamic>.from(snapshot.data()!);
    });
  }

  // ============ WEBRTC SIGNALING CLEANUP ============

  /// Clean up WebRTC signaling documents (offer, answer, ICE candidates)
  /// Called when session ends to avoid stale data.
  Future<void> cleanupCallDocument(String callId) async {
    try {
      final batch = _firestore.batch();

      // Delete caller candidates
      final callerCandidates = await _firestore
          .collection(_callsCollection)
          .doc(callId)
          .collection(WebRTCConfig.callerCandidatesSub)
          .get();
      for (final doc in callerCandidates.docs) {
        batch.delete(doc.reference);
      }

      // Delete callee candidates
      final calleeCandidates = await _firestore
          .collection(_callsCollection)
          .doc(callId)
          .collection(WebRTCConfig.calleeCandidatesSub)
          .get();
      for (final doc in calleeCandidates.docs) {
        batch.delete(doc.reference);
      }

      // Delete main call document
      batch.delete(_firestore.collection(_callsCollection).doc(callId));

      await batch.commit();
    } catch (e) {
      print('⚠️ Call document cleanup failed: $e');
    }
  }
}
