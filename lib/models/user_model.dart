import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? username;
  final String? bio;
  final String? photoUrl;
  final String? coverUrl;
  final DateTime? lastSeen;
  final bool isOnline;
  final String? encryptionKey;
  final String role;
  final List<String> fcmTokens;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username,
    this.bio,
    this.photoUrl,
    this.coverUrl,
    this.lastSeen,
    this.isOnline = false,
    this.encryptionKey,
    this.role = 'user',
    this.fcmTokens = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isOnline': isOnline,
      'encryptionKey': encryptionKey,
      'role': role,
      'fcmTokens': fcmTokens,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'],
      bio: map['bio'],
      photoUrl: map['photoUrl'],
      coverUrl: map['coverUrl'],
      lastSeen: map['lastSeen'] != null ? (map['lastSeen'] as Timestamp).toDate() : null,
      isOnline: map['isOnline'] ?? false,
      encryptionKey: map['encryptionKey'],
      role: map['role'] ?? 'user',
      fcmTokens: (map['fcmTokens'] as List?)?.cast<String>() ?? [],
    );
  }
}
