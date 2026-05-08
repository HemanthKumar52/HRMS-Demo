import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';

class DeviceSecurityService {
  DeviceSecurityService._();
  static final instance = DeviceSecurityService._();

  /// Returns `true` if root/jailbreak is detected on a real device.
  /// Skips on debug builds and emulators.
  Future<bool> isDeviceCompromised() async {
    if (kDebugMode) return false;

    try {
      final isRealDevice = await SafeDevice.isRealDevice;
      if (!isRealDevice) return false;

      final isJailBroken = await SafeDevice.isJailBroken;
      return isJailBroken;
    } catch (e) {
      debugPrint('DeviceSecurityService: $e');
      return false;
    }
  }

  /// Returns `true` if the current GPS position is from a mock provider.
  /// Call this before accepting any attendance punch.
  Future<bool> isMockLocationEnabled() async {
    if (kDebugMode) return false;

    try {
      final isRealDevice = await SafeDevice.isRealDevice;
      if (!isRealDevice) return false; // skip on emulators

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return position.isMocked;
    } catch (e) {
      debugPrint('DeviceSecurityService: mock location check failed - $e');
      return false;
    }
  }
}
