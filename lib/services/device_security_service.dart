import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';

class DeviceSecurityService {
  DeviceSecurityService._();
  static final instance = DeviceSecurityService._();

  /// Returns `true` if developer mode, root, or jailbreak is detected.
  /// Always returns `false` in debug builds so emulators work normally.
  Future<bool> isDeviceCompromised() async {
    if (kDebugMode) return false;

    try {
      final isDeveloperMode = await SafeDevice.isDevelopmentModeEnable;
      final isJailBroken = await SafeDevice.isJailBroken;
      final isRealDevice = await SafeDevice.isRealDevice;

      return isDeveloperMode || isJailBroken || !isRealDevice;
    } catch (e) {
      debugPrint('DeviceSecurityService: $e');
      return false;
    }
  }
}
