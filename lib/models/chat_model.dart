import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final String? lastMessageSenderId;
  final String? lastMessageType;
  final Map<String, String>? nicknames;

  // Group specific fields
  final bool isGroup;
  final String? groupName;
  final String? groupIcon;
  final String? groupDescription;
  final String? groupUsername;
  final String? adminId; // Primary owner/creator
  final List<String> admins;
  final Map<String, String> adminTitles; // UID -> Title
  final int slowModeSeconds;
  final List<String> bannedUsers;
  final Map<String, DateTime> mutedUsers; // UID -> Mute until
  final bool restrictSaving;
  final Map<String, bool> permissions; // e.g., 'sendMessages': true
  final bool isPrivate;
  final List<String> joinRequests;
  final String? pinnedMessageId;
  final String? pinnedMessageContent;
  final Map<String, Map<String, dynamic>> restrictions;
  final String? wallpaper; // userId -> {sendMessages, sendMedia, until}
  final Map<String, DateTime> pinnedBy; // userId -> pinnedAt
  final Map<String, DateTime> archivedBy; // userId -> archivedAt

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.lastMessageSenderId,
    this.lastMessageType,
    this.nicknames,
    this.isGroup = false,
    this.groupName,
    this.groupIcon,
    this.groupDescription,
    this.groupUsername,
    this.adminId,
    this.admins = const [],
    this.adminTitles = const {},
    this.slowModeSeconds = 0,
    this.bannedUsers = const [],
    this.mutedUsers = const {},
    this.restrictSaving = false,
    this.permissions = const {
      'sendMessages': true,
      'sendMedia': true,
      'addUsers': true,
      'pinMessages': true,
      'changeInfo': true,
    },
    this.isPrivate = false,
    this.joinRequests = const [],
    this.pinnedMessageId,
    this.pinnedMessageContent,
    this.restrictions = const {},
    this.pinnedBy = const {},
    this.archivedBy = const {},
    this.wallpaper,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageType: map['lastMessageType'],
      nicknames: map['nicknames'] != null ? Map<String, String>.from(map['nicknames']) : null,
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupIcon: map['groupIcon'],
      groupDescription: map['groupDescription'],
      groupUsername: map['groupUsername'],
      adminId: map['adminId'],
      admins: List<String>.from(map['admins'] ?? []),
      adminTitles: Map<String, String>.from(map['adminTitles'] ?? {}),
      slowModeSeconds: map['slowModeSeconds'] ?? 0,
      bannedUsers: List<String>.from(map['bannedUsers'] ?? []),
      mutedUsers: (map['mutedUsers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as Timestamp).toDate()),
          ) ?? {},
      restrictSaving: map['restrictSaving'] ?? false,
      permissions: Map<String, bool>.from(map['permissions'] ?? {
        'sendMessages': true,
        'sendMedia': true,
        'addUsers': true,
        'pinMessages': true,
        'changeInfo': true,
      }),
      isPrivate: map['isPrivate'] ?? false,
      joinRequests: List<String>.from(map['joinRequests'] ?? []),
      pinnedMessageId: map['pinnedMessageId'],
      pinnedMessageContent: map['pinnedMessageContent'],
      restrictions: map['restrictions'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (map['restrictions'] as Map).map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map))),
            )
          : const {},
      pinnedBy: (map['pinnedBy'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as Timestamp).toDate()),
          ) ?? {},
      archivedBy: (map['archivedBy'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as Timestamp).toDate()),
          ) ?? {},
      wallpaper: map['wallpaper'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageType': lastMessageType,
      'nicknames': nicknames,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupIcon': groupIcon,
      'groupDescription': groupDescription,
      'groupUsername': groupUsername,
      'adminId': adminId,
      'admins': admins,
      'adminTitles': adminTitles,
      'slowModeSeconds': slowModeSeconds,
      'bannedUsers': bannedUsers,
      'mutedUsers': mutedUsers.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      'restrictSaving': restrictSaving,
      'permissions': permissions,
      'isPrivate': isPrivate,
      'joinRequests': joinRequests,
      'pinnedMessageId': pinnedMessageId,
      'pinnedMessageContent': pinnedMessageContent,
      'restrictions': restrictions,
      'pinnedBy': pinnedBy.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      'archivedBy': archivedBy.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      'wallpaper': wallpaper,
    };
  }
}
