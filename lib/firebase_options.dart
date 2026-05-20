import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'firebase_config.dart';

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

  // Web: must use const String.fromEnvironment (compile-time only)
  static FirebaseOptions get web => FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_WEB_API_KEY'),
        appId: const String.fromEnvironment('FIREBASE_WEB_APP_ID'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        authDomain: const String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN'),
        databaseURL: const String.fromEnvironment('FIREBASE_DATABASE_URL'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        measurementId: const String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID'),
      );

  // Non-web: try --dart-define at runtime, fall back to FirebaseConfig
  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _env('FIREBASE_ANDROID_API_KEY', FirebaseConfig.androidApiKey),
        appId: _env('FIREBASE_ANDROID_APP_ID', FirebaseConfig.androidAppId),
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID', FirebaseConfig.messagingSenderId),
        projectId: _env('FIREBASE_PROJECT_ID', FirebaseConfig.projectId),
        databaseURL: _env('FIREBASE_DATABASE_URL', FirebaseConfig.databaseUrl),
        storageBucket: _env('FIREBASE_STORAGE_BUCKET', FirebaseConfig.storageBucket),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _env('FIREBASE_IOS_API_KEY', FirebaseConfig.iosApiKey),
        appId: _env('FIREBASE_IOS_APP_ID', FirebaseConfig.iosAppId),
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID', FirebaseConfig.messagingSenderId),
        projectId: _env('FIREBASE_PROJECT_ID', FirebaseConfig.projectId),
        databaseURL: _env('FIREBASE_DATABASE_URL', FirebaseConfig.databaseUrl),
        storageBucket: _env('FIREBASE_STORAGE_BUCKET', FirebaseConfig.storageBucket),
        iosClientId: _env('FIREBASE_IOS_CLIENT_ID', FirebaseConfig.iosClientId),
        iosBundleId: 'com.izutec.flow',
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _env('FIREBASE_MACOS_API_KEY', FirebaseConfig.macosApiKey),
        appId: _env('FIREBASE_MACOS_APP_ID', FirebaseConfig.macosAppId),
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID', FirebaseConfig.messagingSenderId),
        projectId: _env('FIREBASE_PROJECT_ID', FirebaseConfig.projectId),
        databaseURL: _env('FIREBASE_DATABASE_URL', FirebaseConfig.databaseUrl),
        storageBucket: _env('FIREBASE_STORAGE_BUCKET', FirebaseConfig.storageBucket),
        iosClientId: _env('FIREBASE_MACOS_CLIENT_ID', FirebaseConfig.macosClientId),
        iosBundleId: 'com.izutec.flow',
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: _env('FIREBASE_WINDOWS_API_KEY', FirebaseConfig.windowsApiKey),
        appId: _env('FIREBASE_WINDOWS_APP_ID', FirebaseConfig.windowsAppId),
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID', FirebaseConfig.messagingSenderId),
        projectId: _env('FIREBASE_PROJECT_ID', FirebaseConfig.projectId),
        authDomain: _env('FIREBASE_WINDOWS_AUTH_DOMAIN', FirebaseConfig.windowsAuthDomain),
        databaseURL: _env('FIREBASE_DATABASE_URL', FirebaseConfig.databaseUrl),
        storageBucket: _env('FIREBASE_STORAGE_BUCKET', FirebaseConfig.storageBucket),
        measurementId: _env('FIREBASE_WINDOWS_MEASUREMENT_ID', FirebaseConfig.windowsMeasurementId),
      );

  static String _env(String key, String localFallback) {
    try {
      final val = String.fromEnvironment(key);
      if (val.isNotEmpty) return val;
    } catch (_) {}
    return localFallback;
  }
}
