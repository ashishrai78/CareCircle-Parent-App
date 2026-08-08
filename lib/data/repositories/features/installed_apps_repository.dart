import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/installed_app_model.dart';

/// 📱 InstalledAppsRepository — Firestore operations for installed_apps/{childUid}
class InstalledAppsRepository {
  static const _collection = 'installed_apps';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get installed apps (one-time fetch)
  Future<InstalledAppsCollectionModel?> getInstalledApps(
    String childUid,
  ) async {
    final snapshot =
        await _firestore.collection(_collection).doc(childUid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return InstalledAppsCollectionModel.fromFirestore(
      Map<String, dynamic>.from(snapshot.data()!),
    );
  }

  /// Stream installed apps (real-time updates)
  Stream<InstalledAppsCollectionModel?> streamInstalledApps(
    String childUid,
  ) {
    return _firestore
        .collection(_collection)
        .doc(childUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return InstalledAppsCollectionModel.fromFirestore(
        Map<String, dynamic>.from(snapshot.data()!),
      );
    });
  }

  /// Decode base64 icon to Uint8List (for legacy format with base64 in Firestore)
  Uint8List? decodeIcon(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }
}
