import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAction {
  final String id;
  final String adminId;
  final String adminName;
  final String actionType; // e.g., 'deleted_message', 'changed_info', 'banned_user'
  final String targetUserId;
  final String? targetUserName;
  final String description;
  final DateTime timestamp;

  AdminAction({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.actionType,
    required this.targetUserId,
    this.targetUserName,
    required this.description,
    required this.timestamp,
  });

  factory AdminAction.fromMap(Map<String, dynamic> map, String id) {
    return AdminAction(
      id: id,
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? '',
      actionType: map['actionType'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      targetUserName: map['targetUserName'],
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'actionType': actionType,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class InviteLink {
  final String id;
  final String chatId;
  final String creatorId;
  final String label;
  final int joinCount;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? expiresAt;

  InviteLink({
    required this.id,
    required this.chatId,
    required this.creatorId,
    required this.label,
    this.joinCount = 0,
    required this.createdAt,
    this.isActive = true,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory InviteLink.fromMap(Map<String, dynamic> map, String id) {
    return InviteLink(
      id: id,
      chatId: map['chatId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      label: map['label'] ?? '',
      joinCount: map['joinCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'creatorId': creatorId,
      'label': label,
      'joinCount': joinCount,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}
