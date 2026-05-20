import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, voice, file }

class MessageModel {
  final String? id;
  final String senderId;
  final String? senderName; // For group messages
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? folder;
  final bool isRead;
  final bool isPending;
  final String? localFilePath;
  final String? replyToMessageId;
  final String? replyToMessageContent;
  final String? forwardedFrom;
  final List<String> deletedFor;
  final Map<String, String> reactions; // userId -> emoji

  MessageModel({
    this.id,
    required this.senderId,
    this.senderName,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.folder,
    this.isRead = false,
    this.isPending = false,
    this.localFilePath,
    this.replyToMessageId,
    this.replyToMessageContent,
    this.forwardedFrom,
    this.deletedFor = const [],
    this.reactions = const {},
  });

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? folder,
    bool? isRead,
    bool? isPending,
    String? localFilePath,
    String? replyToMessageId,
    String? replyToMessageContent,
    String? forwardedFrom,
    List<String>? deletedFor,
    Map<String, String>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      folder: folder ?? this.folder,
      isRead: isRead ?? this.isRead,
      isPending: isPending ?? this.isPending,
      localFilePath: localFilePath ?? this.localFilePath,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageContent: replyToMessageContent ?? this.replyToMessageContent,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      deletedFor: deletedFor ?? this.deletedFor,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'folder': folder,
      'isRead': isRead,
      'replyToMessageId': replyToMessageId,
      'replyToMessageContent': replyToMessageContent,
      'forwardedFrom': forwardedFrom,
      'deletedFor': deletedFor,
      'reactions': reactions,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MessageModel(
      id: docId ?? map['id'],
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      folder: map['folder'],
      isRead: map['isRead'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      replyToMessageContent: map['replyToMessageContent'],
      forwardedFrom: map['forwardedFrom'],
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
    );
  }
}
