import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void initialize() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final statusRef = _db.ref('status/$uid');
    final connectedRef = _db.ref('.info/connected');

    connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        // When connected, set status to online
        statusRef.set({
          'state': 'online',
          'last_changed': ServerValue.timestamp,
        });

        // Sync with Firestore for compatibility with existing UI
        _firestore.collection('users').doc(uid).update({'isOnline': true});

        // When disconnected, set status to offline
        statusRef.onDisconnect().set({
          'state': 'offline',
          'last_changed': ServerValue.timestamp,
        }).then((_) {
          // Note: Firestore update on disconnect is not possible directly from client 
          // but RTDB is our source of truth now.
        });
      }
    });
  }

  // Update typing status in RTDB
  void setTyping(String chatId, bool isTyping) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _db.ref('typing/$chatId/$uid').set(isTyping);
    
    // Automatically remove typing status on disconnect
    if (isTyping) {
      _db.ref('typing/$chatId/$uid').onDisconnect().remove();
    }
  }

  // Stream for a specific user's presence
  Stream<bool> getPresenceStream(String uid) {
    return _db.ref('status/$uid/state').onValue.map((event) {
      return event.snapshot.value == 'online';
    });
  }

  // Stream for typing status in a chat
  Stream<Map<String, bool>> getTypingStream(String chatId) {
    return _db.ref('typing/$chatId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return data.map((key, value) => MapEntry(key.toString(), value as bool));
    });
  }
}
