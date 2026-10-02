import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/contact_model.dart';

class ContactsRepository {
  static const _collection = 'contacts';
  static const _subCollection = 'items';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ContactModel>> streamContacts(String childUid) {
    return _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContactModel.fromMap(
                  Map<String, dynamic>.from(doc.data()),
                ))
            .toList());
  }

  Stream<ContactStats> streamContactStats(String childUid) {
    return _firestore
        .collection(_collection)
        .doc(childUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return ContactStats(totalContacts: 0);
      }
      final data = Map<String, dynamic>.from(snapshot.data()!);
      return ContactStats(
        totalContacts: (data['totalContacts'] as num?)?.toInt() ?? 0,
        lastSync: (data['lastSync'] as Timestamp?)?.toDate(),
      );
    });
  }

  Future<List<ContactModel>> getContacts(String childUid) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .orderBy('displayName')
        .get();

    return snapshot.docs
        .map((doc) => ContactModel.fromMap(
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }

  Future<ContactModel?> getContact(String childUid, String contactId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .doc(contactId)
        .get();

    if (!snapshot.exists || snapshot.data() == null) return null;
    return ContactModel.fromMap(Map<String, dynamic>.from(snapshot.data()!));
  }

  Future<ContactStats> getContactStats(String childUid) async {
    final snapshot =
        await _firestore.collection(_collection).doc(childUid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return ContactStats(totalContacts: 0);
    }

    return ContactStats.fromSummary(Map<String, dynamic>.from(snapshot.data()!));
  }

  Future<void> requestContactsSync(String childUid) async {
    await _firestore.collection('child_control').doc(childUid).set({
      'contacts_sync_request': true,
      'contacts_sync_requested_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<ContactModel>> searchContacts(
    String childUid,
    String query,
  ) async {
    final allContacts = await getContacts(childUid);
    final lowerQuery = query.toLowerCase();

    return allContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(lowerQuery) ||
          contact.primaryPhone.toLowerCase().contains(lowerQuery) ||
          contact.phoneNumbers.any(
            (p) => p.toLowerCase().contains(lowerQuery),
          ) ||
          contact.emails.any(
            (e) => e.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  }

  Future<List<ContactModel>> getStarredContacts(String childUid) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(childUid)
        .collection(_subCollection)
        .where('isStarred', isEqualTo: true)
        .orderBy('displayName')
        .get();

    return snapshot.docs
        .map((doc) => ContactModel.fromMap(
              Map<String, dynamic>.from(doc.data()),
            ))
        .toList();
  }
}
