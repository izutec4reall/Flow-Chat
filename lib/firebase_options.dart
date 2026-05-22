import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options resolved from --dart-define-from-file=.env
///
/// Local:  ./run.sh (loads .env automatically)
/// CI:     .env is generated from GitHub Secrets
///
/// Both use the same --dart-define-from-file mechanism,
/// so no code changes are needed between local and CI builds.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.macOS: return macos;
      case TargetPlatform.windows: return windows;
      case TargetPlatform.linux: return web;
      case TargetPlatform.fuchsia: throw UnsupportedError('fuchsia');
    }
  }

  // ─── Common keys (shared across platforms) ───
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _dbUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');
  static const _bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  // ─── Web ───
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: const String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN'),
    databaseURL: _dbUrl,
    storageBucket: _bucket,
    measurementId: const String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID'),
  );

  // ─── Android ───
  static FirebaseOptions get android => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    databaseURL: _dbUrl,
    storageBucket: _bucket,
  );

  // ─── iOS ───
  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    databaseURL: _dbUrl,
    storageBucket: _bucket,
    iosClientId: const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
    iosBundleId: 'com.izutec.flow',
  );

  // ─── macOS ───
  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_MACOS_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_MACOS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    databaseURL: _dbUrl,
    storageBucket: _bucket,
    iosClientId: const String.fromEnvironment('FIREBASE_MACOS_CLIENT_ID'),
    iosBundleId: 'com.izutec.flow',
  );

  // ─── Windows ───
  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: const String.fromEnvironment('FIREBASE_WINDOWS_API_KEY'),
    appId: const String.fromEnvironment('FIREBASE_WINDOWS_APP_ID'),
    messagingSenderId: _senderId,
    projectId: _projectId,
    authDomain: const String.fromEnvironment('FIREBASE_WINDOWS_AUTH_DOMAIN'),
    databaseURL: _dbUrl,
    storageBucket: _bucket,
    measurementId: const String.fromEnvironment('FIREBASE_WINDOWS_MEASUREMENT_ID'),
  );
}
