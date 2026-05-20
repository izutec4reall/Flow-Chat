import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cache of encryption keys per user to avoid repeated Firestore reads.
  static final Map<String, String> _keyCache = {};

  Future<String?> _getUserKey(String uid) async {
    if (_keyCache.containsKey(uid)) return _keyCache[uid];
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final key = doc.data()?['encryptionKey'] as String?;
      if (key != null) _keyCache[uid] = key;
      return key;
    } catch (_) {
      return null;
    }
  }

  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 20}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), docId: doc.id))
          .toList();

      for (int i = 0; i < messages.length; i++) {
        if (messages[i].type == MessageType.text) {
          try {
            final key = await _getUserKey(messages[i].senderId);
            if (key != null) {
              messages[i] = messages[i].copyWith(
                content: EncryptionService.decryptText(messages[i].content, key),
              );
            }
          } catch (_) {}
        }
      }
      return messages;
    });
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    List<String>? participantIds;
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        participantIds = List<String>.from(data['participants'] ?? []);
      }
    } catch (_) {}

    String? senderKey;
    final originalContent = message.content;
    if (message.type == MessageType.text) {
      senderKey = await _getUserKey(message.senderId);
      if (senderKey != null) {
        message = message.copyWith(
          content: EncryptionService.encryptText(message.content, senderKey),
        );
      }
    }

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    final Map<String, dynamic> updates = {
      'lastMessage': (message.type == MessageType.text ? originalContent : null),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': message.senderId,
    };

    if (participantIds != null) {
      for (final pid in participantIds) {
        if (pid != message.senderId) {
          updates['unreadCounts.$pid'] = FieldValue.increment(1);
        }
      }
    }

    if (updates['lastMessage'] == null) {
      updates['lastMessage'] = '[Media]';
    }

    await _firestore.collection('chats').doc(chatId).set(
      updates,
      SetOptions(merge: true),
    );
  }

  Future<void> markAsRead(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  Future<void> toggleReaction(String chatId, String messageId, String userId, String emoji) async {
    final docRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    Map<String, dynamic> reactions = Map<String, dynamic>.from(doc.data()?['reactions'] ?? {});

    if (reactions[userId] == emoji) {
      reactions.remove(userId);
    } else {
      reactions[userId] = emoji;
    }

    await docRef.update({'reactions': reactions});
  }

  Future<void> resetUnreadCount(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 0,
    });
  }

  Future<void> markAsUnread(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 1,
    });
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> hideMessage(String chatId, String messageId, String userId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([userId]),
    });
  }
}
