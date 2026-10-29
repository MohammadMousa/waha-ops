import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// What this device tells the backend at login, so the session list can show
/// which device/model/OS each session is on.
class DeviceInfo {
  DeviceInfo._();

  static Map<String, String> _props = {'os': Platform.operatingSystem};

  /// Call once at startup. Falls back to the bare OS name if the platform
  /// lookup fails — login must never depend on this.
  static Future<void> init() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        _props = {
          'os': 'Android',
          'osVersion': a.version.release,
          'model': a.model,
        };
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        _props = {'os': 'iOS', 'osVersion': i.systemVersion, 'model': i.utsname.machine};
      }
    } catch (_) {}
  }

  /// The `sessionProperties` login field.
  static Map<String, String> get properties => _props;
}
