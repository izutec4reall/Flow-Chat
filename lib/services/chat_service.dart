import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/group_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Sort to ensure the same ID for the same pair
    return ids.join('_');
  }



  Stream<List<ChatModel>> getUserChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return ChatModel.fromMap(doc.data());
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing chat ${doc.id}: $e');
          return null;
        }
      }).whereType<ChatModel>().toList();
    });
  }

  Future<List<ChatModel>> getUserChatsOnce(String uid) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();
    return snapshot.docs.map((doc) => ChatModel.fromMap(doc.data())).toList();
  }

  Future<Map<String, dynamic>> getChatOnce(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.data() ?? {};
  }

  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async {
    // Deterministic ID to avoid duplicates
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatId = ids.join('_');

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'participants': ids,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });
    }

    return chatId;
  }

  Future<String> createChat(String userId1, String userId2) async {
    final chatId = getChatId(userId1, userId2);
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      final chat = ChatModel(
        chatId: chatId,
        participants: [userId1, userId2],
        lastMessage: 'Start a new conversation',
        lastMessageTime: DateTime.now(),
      );
      await _firestore.collection('chats').doc(chatId).set(chat.toMap());
    }
    return chatId;
  }

  Stream<ChatModel> getChatStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => ChatModel.fromMap(doc.data()!));
  }

  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typingStatus.$userId': isTyping,
    });
  }

  Future<void> setNickname(String chatId, String userId, String nickname) async {
    await _firestore.collection('chats').doc(chatId).update({
      'nicknames.$userId': nickname,
    });
  }

  Future<String> createGroup(String groupName, List<String> participantIds, String adminId) async {
    final docRef = _firestore.collection('chats').doc();
    final chatId = docRef.id;
    
    final chat = ChatModel(
      chatId: chatId,
      participants: [...participantIds, adminId],
      lastMessage: 'Group created',
      lastMessageTime: DateTime.now(),
      isGroup: true,
      groupName: groupName,
      adminId: adminId,
    );
    
    await docRef.set(chat.toMap());
    return chatId;
  }

  Future<void> deleteChat(String chatId) async {
    // Delete all messages subcollection first
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('chats').doc(chatId));
    await batch.commit();
  }

  // --- Group Management Methods ---

  Future<void> updateGroupPermissions(String chatId, Map<String, bool> permissions) async {
    await _firestore.collection('chats').doc(chatId).update({
      'permissions': permissions,
    });
  }

  Future<void> setAdminTitle(String chatId, String userId, String title) async {
    await _firestore.collection('chats').doc(chatId).update({
      'adminTitles.$userId': title,
    });
  }

  Future<void> toggleAdmin(String chatId, String userId, bool isAdmin) async {
    final doc = _firestore.collection('chats').doc(chatId);
    if (isAdmin) {
      await doc.update({
        'admins': FieldValue.arrayUnion([userId]),
      });
    } else {
      await doc.update({
        'admins': FieldValue.arrayRemove([userId]),
        'adminTitles.$userId': FieldValue.delete(),
      });
    }
  }

  Future<void> setSlowMode(String chatId, int seconds) async {
    await _firestore.collection('chats').doc(chatId).update({
      'slowModeSeconds': seconds,
    });
  }

  Future<void> banUser(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'bannedUsers': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> unbanUser(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'bannedUsers': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> muteUser(String chatId, String userId, DateTime? until) async {
    if (until == null) {
      await _firestore.collection('chats').doc(chatId).update({
        'mutedUsers.$userId': FieldValue.delete(),
      });
    } else {
      await _firestore.collection('chats').doc(chatId).update({
        'mutedUsers.$userId': Timestamp.fromDate(until),
      });
    }
  }

  // --- Invite Links ---
  // Stored in top-level `invite_links` collection — no composite indexes needed.

  Future<String> createInviteLink(String chatId, String creatorId, String label, {DateTime? expiresAt}) async {
    final docRef = _firestore.collection('invite_links').doc();
    final link = InviteLink(
      id: docRef.id,
      chatId: chatId,
      creatorId: creatorId,
      label: label,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );
    await docRef.set(link.toMap());
    return docRef.id;
  }

  Future<void> deleteInviteLink(String chatId, String linkId) async {
    await _firestore.collection('invite_links').doc(linkId).delete();
  }

  Stream<List<InviteLink>> getInviteLinks(String chatId) {
    return _firestore
        .collection('invite_links')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => InviteLink.fromMap(d.data(), d.id))
            .where((link) => link.isActive && !link.isExpired)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<ChatModel> joinGroupByInviteLink(String inviteLinkId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final inviteLinkDoc = await _firestore.collection('invite_links').doc(inviteLinkId).get();

    if (!inviteLinkDoc.exists) {
      throw Exception('Invite link not found or invalid');
    }

    final inviteLinkData = inviteLinkDoc.data()!;
    final chatId = inviteLinkData['chatId'] as String;
    final isActive = inviteLinkData['isActive'] as bool? ?? true;
    final expiresAt = (inviteLinkData['expiresAt'] as Timestamp?)?.toDate();
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);

    if (!isActive || isExpired) {
      throw Exception('This invite link is no longer active');
    }

    final chatDocRef = _firestore.collection('chats').doc(chatId);
    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatDocRef);
      if (!chatSnapshot.exists) {
        throw Exception('Group chat not found');
      }

      final participants = List<String>.from(chatSnapshot.data()?['participants'] ?? []);
      if (!participants.contains(user.uid)) {
        participants.add(user.uid);
        transaction.update(chatDocRef, {'participants': participants});

        transaction.update(inviteLinkDoc.reference, {
          'joinCount': FieldValue.increment(1),
        });
      }
    });

    final updatedDoc = await chatDocRef.get();
    return ChatModel.fromMap(updatedDoc.data()!);
  }

  Future<void> _logAction({
    required String chatId,
    required String type,
    required String targetUserId,
    String? targetUserName,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final action = AdminAction(
      id: '', // Firestore will generate
      adminId: user.uid,
      adminName: user.displayName ?? user.email ?? 'Admin',
      actionType: type,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      description: description,
      timestamp: DateTime.now(),
    );

    await logAdminAction(chatId, action);
  }

  // --- Join Requests ---

  Future<void> requestToJoin(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'joinRequests': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> handleJoinRequest(String chatId, String userId, bool approve) async {
    if (approve) {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'joinRequests': FieldValue.arrayRemove([userId]),
        'unreadCounts.$userId': 0,
      });
      await _logAction(
        chatId: chatId,
        type: 'approve_join',
        targetUserId: userId,
        description: 'Approved join request',
      );
    } else {
      await _firestore.collection('chats').doc(chatId).update({
        'joinRequests': FieldValue.arrayRemove([userId]),
      });
      await _logAction(
        chatId: chatId,
        type: 'reject_join',
        targetUserId: userId,
        description: 'Rejected join request',
      );
    }
  }

  Future<void> leaveGroup(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([user.uid]),
      'admins': FieldValue.arrayRemove([user.uid]),
    });
  }

  Future<void> addMember(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'joinRequests': FieldValue.arrayRemove([userId]),
      'unreadCounts.$userId': 0,
    });
    await _logAction(
      chatId: chatId,
      type: 'add_member',
      targetUserId: userId,
      description: 'Added a new member manually',
    );
  }

  Future<void> toggleRestrictSaving(String chatId, bool value) async {
    await _firestore.collection('chats').doc(chatId).update({
      'restrictSaving': value,
    });
  }

  Future<void> toggleGroupPrivacy(String chatId, bool isPrivate) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isPrivate': isPrivate,
    });
    await _logAction(
      chatId: chatId,
      type: 'change_privacy',
      targetUserId: '',
      description: 'Changed group to ${isPrivate ? 'Private' : 'Public'}',
    );
  }

  // --- Admin Logs ---

  Future<void> logAdminAction(String chatId, AdminAction action) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('adminActions')
        .add(action.toMap());
  }

  Stream<List<AdminAction>> getAdminActions(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('adminActions')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => AdminAction.fromMap(d.data(), d.id)).toList());
  }

  // --- Group Info ---

  Future<void> updateGroupInfo(String chatId, {String? name, String? description, String? username}) async {
    final update = <String, dynamic>{};
    if (name != null) update['groupName'] = name;
    if (description != null) update['groupDescription'] = description;
    if (username != null) update['groupUsername'] = username;
    if (update.isNotEmpty) {
      await _firestore.collection('chats').doc(chatId).update(update);
      await _logAction(
        chatId: chatId,
        type: 'change_info',
        targetUserId: '',
        description: 'Updated group info',
      );
    }
  }

  Future<void> updateGroupIcon(String chatId, String url) async {
    await _firestore.collection('chats').doc(chatId).update({'groupIcon': url});
    await _logAction(
      chatId: chatId,
      type: 'change_info',
      targetUserId: '',
      description: 'Changed group photo',
    );
  }

  // --- Wallpaper ---

  Future<void> setChatWallpaper(String chatId, String url) async {
    await _firestore.collection('chats').doc(chatId).update({'wallpaper': url});
  }

  Future<void> removeChatWallpaper(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({'wallpaper': FieldValue.delete()});
  }

  // --- Pin / Archive ---

  Future<void> togglePin(String chatId, String userId, bool pin) async {
    if (pin) {
      await _firestore.collection('chats').doc(chatId).update({
        'pinnedBy.$userId': Timestamp.now(),
      });
    } else {
      await _firestore.collection('chats').doc(chatId).update({
        'pinnedBy.$userId': FieldValue.delete(),
      });
    }
  }

  Future<void> toggleArchive(String chatId, String userId, bool archive) async {
    if (archive) {
      await _firestore.collection('chats').doc(chatId).update({
        'archivedBy.$userId': Timestamp.now(),
      });
    } else {
      await _firestore.collection('chats').doc(chatId).update({
        'archivedBy.$userId': FieldValue.delete(),
      });
    }
  }

  // --- User Restrictions ---

  Future<void> setUserRestriction(
    String chatId,
    String userId, {
    bool? sendMessages,
    bool? sendMedia,
    DateTime? until,
  }) async {
    final update = <String, dynamic>{};
    if (sendMessages != null) {
      update['restrictions.$userId.sendMessages'] = sendMessages;
    }
    if (sendMedia != null) {
      update['restrictions.$userId.sendMedia'] = sendMedia;
    }
    if (until != null) {
      update['restrictions.$userId.until'] = Timestamp.fromDate(until);
    }
    if (update.isNotEmpty) {
      await _firestore.collection('chats').doc(chatId).update(update);
    }
  }

  Future<void> removeUserRestriction(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'restrictions.$userId': FieldValue.delete(),
    });
  }

  Future<void> clearAdminActions(String chatId) async {
    final snap = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('adminActions')
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> pinMessage(String chatId, String? messageId, String? content) async {
    await _firestore.collection('chats').doc(chatId).update({
      'pinnedMessageId': messageId,
      'pinnedMessageContent': content,
    });
    
    if (messageId != null) {
      await _logAction(
        chatId: chatId,
        type: 'pin_message',
        targetUserId: '',
        description: 'Pinned a message: ${content != null && content.length > 20 ? '${content.substring(0, 20)}...' : content}',
      );
    }
  }

}
