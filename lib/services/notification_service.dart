import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final NotificationService _instance = NotificationService._();
  NotificationService._();
  factory NotificationService() => _instance;

  static Future<void> init() async {
    final service = NotificationService();

    // Request permission & get token
    await service._requestPermissionAndSaveToken();

    // Listen for token refresh
    service._messaging.onTokenRefresh.listen((token) {
      service._saveTokenForCurrentUserWithToken(token);
    });

    // Listen for auth state changes — save token when user logs in
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        service._saveTokenForCurrentUserDelayed();
      }
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated notification
    final initialMessage = await service._messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Public method to save token for the currently signed-in user.
  /// Call this after user login if init() ran before auth was ready.
  static Future<void> saveTokenForCurrentUser() async {
    final service = NotificationService();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await service._messaging.getToken();
      if (token != null) {
        await service._saveToken(user.uid, token);
      }
    } catch (_) {}
  }

  /// Send a push notification to a user via FCM HTTP API (serverless).
  static Future<void> sendNotification({
    required String recipientUid,
    required String title,
    required String body,
    String? chatId,
  }) async {
    final serverKey = const String.fromEnvironment('FCM_SERVER_KEY');
    if (serverKey.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(recipientUid).get();
      if (!doc.exists) return;
      final raw = doc.data()?['fcmTokens'];
      final tokens = raw is List ? List<String>.from(raw) : <String>[];
      if (tokens.isEmpty) return;

      final payload = {
        'registration_ids': tokens,
        'priority': 'high',
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'android_channel_id': 'high_importance_channel',
        },
        'data': {
          'chatId': chatId ?? '',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'high_importance_channel',
            'priority': 'high',
            'default_sound': true,
          },
        },
      };

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );
    } catch (_) {
      // Silently fail — notification may not arrive
    }
  }

  Future<void> _requestPermissionAndSaveToken() async {
    try {
      final notifSettings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (notifSettings.authorizationStatus == AuthorizationStatus.authorized ||
          notifSettings.authorizationStatus == AuthorizationStatus.provisional) {
        await _saveTokenForCurrentUser();
      }
    } catch (_) {
      // Permission denied or error — silently continue
    }
  }

  Future<void> _saveTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(user.uid, token);
      }
    } catch (_) {}
  }

  Future<void> _saveTokenForCurrentUserWithToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _saveToken(user.uid, token);
    } catch (_) {}
  }

  Future<void> _saveTokenForCurrentUserDelayed() async {
    // Wait a moment for the user doc to be created (e.g., after Google Sign-In)
    await Future.delayed(const Duration(seconds: 2));
    await _saveTokenForCurrentUser();
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Notification is displayed system-level; no overlay needed
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final chatId = message.data['chatId'] as String?;
    if (chatId != null) {
      _pendingChatId = chatId;
    }
  }

  static String? _pendingChatId;
  static String? get pendingChatId => _pendingChatId;
  static void clearPendingChat() => _pendingChatId = null;

  Future<void> _saveToken(String uid, String token) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final raw = doc.data()?['fcmTokens'];
      final tokens = raw is List ? List<String>.from(raw) : <String>[];
      if (!tokens.contains(token)) {
        tokens.add(token);
        await _firestore.collection('users').doc(uid).update({'fcmTokens': tokens});
      }
    } catch (_) {
      // Silently fail — token will be retried on refresh
    }
  }
}
