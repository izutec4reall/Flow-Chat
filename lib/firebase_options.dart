import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
        appId: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        databaseURL: const String.fromEnvironment('FIREBASE_DATABASE_URL'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_IOS_API_KEY'),
        appId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        databaseURL: const String.fromEnvironment('FIREBASE_DATABASE_URL'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        iosClientId: const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
        iosBundleId: 'com.izutec.flow',
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_MACOS_API_KEY'),
        appId: const String.fromEnvironment('FIREBASE_MACOS_APP_ID'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        databaseURL: const String.fromEnvironment('FIREBASE_DATABASE_URL'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        iosClientId: const String.fromEnvironment('FIREBASE_MACOS_CLIENT_ID'),
        iosBundleId: 'com.izutec.flow',
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_WINDOWS_API_KEY'),
        appId: const String.fromEnvironment('FIREBASE_WINDOWS_APP_ID'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        authDomain: const String.fromEnvironment('FIREBASE_WINDOWS_AUTH_DOMAIN'),
        databaseURL: const String.fromEnvironment('FIREBASE_DATABASE_URL'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        measurementId: const String.fromEnvironment('FIREBASE_WINDOWS_MEASUREMENT_ID'),
      );
}
