import 'package:cloud_firestore/cloud_firestore.dart';

/// 📱 ContactModel — represents a single contact from child's device
class ContactModel {
  final String id;
  final String displayName;
  final String primaryPhone;
  final String? primaryPhoneType;
  final List<String> phoneNumbers;
  final List<String> emails;
  final String? photoBase64;
  final bool isStarred;
  final bool hasPhone;
  final int phoneCount;
  final int emailCount;
  final DateTime? updatedAt;

  ContactModel({
    required this.id,
    required this.displayName,
    required this.primaryPhone,
    this.primaryPhoneType,
    required this.phoneNumbers,
    required this.emails,
    this.photoBase64,
    this.isStarred = false,
    this.hasPhone = true,
    this.phoneCount = 0,
    this.emailCount = 0,
    this.updatedAt,
  });

  factory ContactModel.fromMap(Map<String, dynamic> data) {
    return ContactModel(
      id: data['id']?.toString() ?? '',
      displayName: data['displayName'] as String? ?? 'Unknown',
      primaryPhone: data['primaryPhone'] as String? ?? '',
      primaryPhoneType: data['primaryPhoneType'] as String?,
      phoneNumbers: (data['phoneNumbers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      emails: (data['emails'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      photoBase64: data['photoBase64'] as String?,
      isStarred: data['isStarred'] as bool? ?? false,
      hasPhone: data['hasPhone'] as bool? ?? true,
      phoneCount: (data['phoneCount'] as num?)?.toInt() ?? 0,
      emailCount: (data['emailCount'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'primaryPhone': primaryPhone,
      'primaryPhoneType': primaryPhoneType,
      'phoneNumbers': phoneNumbers,
      'emails': emails,
      'photoBase64': photoBase64,
      'isStarred': isStarred,
      'hasPhone': hasPhone,
      'phoneCount': phoneCount,
      'emailCount': emailCount,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;

  String get initials {
    final parts = displayName.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  int get avatarColor {
    final colors = [
      0xFFE57373, 0xFFBA68C8, 0xFF7986CB, 0xFF4FC3F7,
      0xFF4DB6AC, 0xFF81C784, 0xFFFFB74D, 0xFFA1887F, 0xFF90A4AE,
    ];
    return colors[displayName.hashCode % colors.length];
  }

  String get allPhonesFormatted {
    if (phoneNumbers.isEmpty) return 'No phone numbers';
    return phoneNumbers.join('\n');
  }

  String get allEmailsFormatted {
    if (emails.isEmpty) return 'No email addresses';
    return emails.join('\n');
  }

  String get lastSyncAgo {
    if (updatedAt == null) return 'Unknown';
    final diff = DateTime.now().difference(updatedAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}

class ContactStats {
  final int totalContacts;
  final int contactsWithPhoto;
  final int starredContacts;
  final int contactsWithEmail;
  final DateTime? lastSync;

  ContactStats({
    required this.totalContacts,
    this.contactsWithPhoto = 0,
    this.starredContacts = 0,
    this.contactsWithEmail = 0,
    this.lastSync,
  });

  factory ContactStats.fromSummary(Map<String, dynamic> data) {
    return ContactStats(
      totalContacts: (data['totalContacts'] as num?)?.toInt() ?? 0,
      contactsWithPhoto: (data['contactsWithPhoto'] as num?)?.toInt() ?? 0,
      starredContacts: (data['starredContacts'] as num?)?.toInt() ?? 0,
      contactsWithEmail: (data['contactsWithEmail'] as num?)?.toInt() ?? 0,
      lastSync: (data['lastSync'] as Timestamp?)?.toDate(),
    );
  }
}
