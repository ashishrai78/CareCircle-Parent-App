import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String uid;
  final String email;
  String name;
  final String role; // dashboard | child
  bool? emailVerified;

  /// CHILD
  String childCode;
  String parentUid;

  /// PARENT
  List<String> linkedChildren;

  /// META (Firestore safe)
  Timestamp? createdAt;
  Timestamp? lastActive;

  AppUserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.emailVerified,
    this.createdAt,
    this.lastActive,
    this.childCode = '',
    this.parentUid = '',
    List<String>? linkedChildren,
  }) : linkedChildren = linkedChildren ?? [];

  /// EMPTY
  static AppUserModel empty() => AppUserModel(
    uid: '',
    email: '',
    name: '',
    role: '',
    emailVerified: false,
    createdAt: Timestamp.now(),
    lastActive: Timestamp.now(),
  );

  /// TO FIRESTORE
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'emailVerified': emailVerified,
      'childCode': childCode,
      'parentUid': parentUid,
      'linkedChildren': linkedChildren,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }

  /// FROM FIRESTORE
  factory AppUserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return AppUserModel.empty();

    return AppUserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      emailVerified: data['emailVerified'] ?? false,
      childCode: data['childCode'] ?? '',
      parentUid: data['parentUid'] ?? '',
      linkedChildren: List<String>.from(data['linkedChildren'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastActive: data['lastActive'] ?? Timestamp.now(),
    );
  }
}
