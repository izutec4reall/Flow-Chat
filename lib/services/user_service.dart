import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'encryption_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _cacheTTL = 300;
  static final Map<String, _CacheEntry> _cache = {};

  Future<void> createUser(UserModel user) async {
    final key = EncryptionService.generateKey();
    final data = user.toMap();
    data['encryptionKey'] = key;
    await _firestore.collection('users').doc(user.uid).set(data);
    _setCache(user.uid, UserModel(
      uid: user.uid, email: user.email, displayName: user.displayName,
      username: user.username, bio: user.bio, photoUrl: user.photoUrl,
      coverUrl: user.coverUrl, lastSeen: user.lastSeen,
      isOnline: user.isOnline, encryptionKey: key,
      role: user.role, fcmTokens: user.fcmTokens,
    ));
  }

  UserModel? _getCached(String uid) {
    final entry = _cache[uid];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt).inSeconds > _cacheTTL) {
      _cache.remove(uid);
      return null;
    }
    return entry.user;
  }

  void _setCache(String uid, UserModel user) {
    _cache[uid] = _CacheEntry(user: user, cachedAt: DateTime.now());
  }

  Future<UserModel?> getUser(String uid) async {
    final cached = _getCached(uid);
    if (cached != null) return cached;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final user = UserModel.fromMap(doc.data()!);
      _setCache(uid, user);
      return user;
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!);
        _setCache(uid, user);
        return user;
      }
      return null;
    });
  }

  Future<Map<String, UserModel?>> getUsersBatch(List<String> uids) async {
    final result = <String, UserModel?>{};
    final uncached = <String>[];

    for (final uid in uids) {
      final cached = _getCached(uid);
      if (cached != null) {
        result[uid] = cached;
      } else {
        uncached.add(uid);
      }
    }

    if (uncached.isEmpty) return result;

    final chunks = _chunks(uncached, 10);
    for (final chunk in chunks) {
      final q = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in q.docs) {
        final user = UserModel.fromMap(doc.data());
        _setCache(doc.id, user);
        result[doc.id] = user;
      }
    }
    return result;
  }

  List<List<String>> _chunks(List<String> list, int size) {
    final chunks = <List<String>>[];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size > list.length) ? list.length : i + size));
    }
    return chunks;
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
      final existing = _getCached(uid);
      if (existing != null) {
        _setCache(uid, UserModel(
          uid: existing.uid, email: existing.email,
          displayName: displayName ?? existing.displayName,
          username: username ?? existing.username,
          bio: bio ?? existing.bio,
          photoUrl: photoUrl ?? existing.photoUrl,
          coverUrl: coverUrl ?? existing.coverUrl,
          isOnline: existing.isOnline, lastSeen: existing.lastSeen,
          encryptionKey: existing.encryptionKey,
          role: existing.role, fcmTokens: existing.fcmTokens,
        ));
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
    final emailQuery = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

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
    _cache.remove(uid);
  }

  Future<List<UserModel>> getInitialUsers({int limit = 50}) async {
    final query = await _firestore.collection('users').limit(limit).get();
    final users = query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    for (final u in users) {
      _setCache(u.uid, u);
    }
    return users;
  }
}

class _CacheEntry {
  final UserModel user;
  final DateTime cachedAt;
  _CacheEntry({required this.user, required this.cachedAt});
}
