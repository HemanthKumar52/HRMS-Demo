import 'package:flutter/services.dart' show PlatformException;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional app lock using device biometrics (fingerprint/face) or PIN.
/// Users can enable/disable this in Settings.
class AppLockService {
  AppLockService._();
  static final instance = AppLockService._();

  final _auth = LocalAuthentication();
  static const _enabledKey = 'app_lock_enabled';

  /// Check if user has enabled app lock
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Toggle app lock on/off
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Check if device supports biometrics
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate with device biometrics/PIN
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access PPulse HRMS',
      );
    } on PlatformException {
      return false;
    }
  }
}
