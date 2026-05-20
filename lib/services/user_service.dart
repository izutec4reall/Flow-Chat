import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'encryption_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // In-memory cache for user profiles
  static final Map<String, UserModel> _userCache = {};

  Future<void> createUser(UserModel user) async {
    final key = EncryptionService.generateKey();
    final data = user.toMap();
    data['encryptionKey'] = key;
    await _firestore.collection('users').doc(user.uid).set(data);
    _userCache[user.uid] = UserModel(
      uid: user.uid, email: user.email, displayName: user.displayName,
      username: user.username, bio: user.bio, photoUrl: user.photoUrl,
      coverUrl: user.coverUrl, lastSeen: user.lastSeen,
      isOnline: user.isOnline, encryptionKey: key,
      role: user.role, fcmTokens: user.fcmTokens,
    );
  }

  Future<UserModel?> getUser(String uid) async {
    // Check cache first
    if (_userCache.containsKey(uid)) {
      return _userCache[uid];
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final user = UserModel.fromMap(doc.data()!);
      _userCache[uid] = user; // Save to cache
      return user;
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Future<void> updateProfile(String uid, {String? displayName, String? photoUrl, String? coverUrl, String? username, String? bio}) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (coverUrl != null) data['coverUrl'] = coverUrl;
    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;
    
    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(data);
      // Invalidate or update cache
      if (_userCache.containsKey(uid)) {
        final existing = _userCache[uid]!;
        _userCache[uid] = UserModel(
          uid: existing.uid,
          email: existing.email,
          displayName: displayName ?? existing.displayName,
          username: username ?? existing.username,
          bio: bio ?? existing.bio,
          photoUrl: photoUrl ?? existing.photoUrl,
          coverUrl: coverUrl ?? existing.coverUrl,
          isOnline: existing.isOnline,
          lastSeen: existing.lastSeen,
          encryptionKey: existing.encryptionKey,
          role: existing.role,
          fcmTokens: existing.fcmTokens,
        );
      }
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<List<UserModel>> searchUsers(String query) async {
    // Search by email
    final emailQuery = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    // Search by username
    final usernameQuery = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    final results = <String, UserModel>{};
    for (var doc in [...emailQuery.docs, ...usernameQuery.docs]) {
      final user = UserModel.fromMap(doc.data());
      results[user.uid] = user;
    }
    return results.values.toList();
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
    _userCache.remove(uid); // Invalidate cache to force reload
  }

  Future<List<UserModel>> getInitialUsers({int limit = 50}) async {
    final query = await _firestore.collection('users').limit(limit).get();
    return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }
}
