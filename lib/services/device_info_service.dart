import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceInfoService {
  static final _deviceInfo = DeviceInfoPlugin();

  /// Returns the device CPU architecture label for APK matching.
  /// One of: 'arm64-v8a', 'armeabi-v7a', 'x86_64', or null on non-Android.
  static Future<String?> getDeviceArch() async {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        final abis = android.supportedAbis;
        if (abis.contains('arm64-v8a')) return 'arm64-v8a';
        if (abis.contains('armeabi-v7a')) return 'armeabi-v7a';
        if (abis.contains('x86_64')) return 'x86_64';
        if (abis.contains('x86')) return 'x86_64';
        return abis.isNotEmpty ? abis.first : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Human-readable architecture name for display.
  static String archLabel(String? arch) {
    switch (arch) {
      case 'arm64-v8a': return 'ARM64 (64-bit)';
      case 'armeabi-v7a': return 'ARM (32-bit)';
      case 'x86_64': return 'x86_64';
      default: return arch ?? 'Unknown';
    }
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final info = <String, dynamic>{};
    info['locale'] = Platform.localeName;

    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        info['os'] = 'Android';
        info['osVersion'] = android.version.release;
        info['sdkInt'] = android.version.sdkInt;
        info['brand'] = android.brand;
        info['model'] = android.model;
        info['device'] = android.device;
        info['manufacturer'] = android.manufacturer;
        info['hardware'] = android.hardware;
        info['product'] = android.product;
        info['fingerprint'] = android.fingerprint;
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        info['os'] = 'iOS';
        info['osVersion'] = ios.systemVersion;
        info['model'] = ios.model;
        info['name'] = ios.name;
        info['identifierForVendor'] = ios.identifierForVendor;
      } else if (Platform.isMacOS) {
        final macos = await _deviceInfo.macOsInfo;
        info['os'] = 'macOS';
        info['osVersion'] = macos.osRelease;
        info['model'] = macos.model;
      } else if (Platform.isWindows) {
        final windows = await _deviceInfo.windowsInfo;
        info['os'] = 'Windows';
        info['osVersion'] = windows.computerName;
        info['productName'] = windows.productName;
      } else if (Platform.isLinux) {
        final linux = await _deviceInfo.linuxInfo;
        info['os'] = 'Linux';
        info['name'] = linux.name;
        info['version'] = linux.version;
      }
    } catch (_) {}

    return info;
  }
}
