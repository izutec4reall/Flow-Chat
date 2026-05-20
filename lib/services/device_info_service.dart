import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final _deviceInfo = DeviceInfoPlugin();

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
