import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Captures location and device info silently for punch in/out.
/// All capture happens in background — never shown in UI.
class PunchMetadataService {
  PunchMetadataService._();
  static final PunchMetadataService instance = PunchMetadataService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Capture location + device info for a punch request.
  /// Returns a map ready to send to the backend.
  /// Never throws — returns empty fields on failure.
  Future<Map<String, dynamic>> capture() async {
    final result = <String, dynamic>{
      'source': _getSource(),
      'device_info': await _getDeviceInfo(),
    };

    try {
      final position = await _getCurrentPosition();
      if (position != null) {
        result['latitude'] = position.latitude;
        result['longitude'] = position.longitude;
      }
    } catch (e) {
      debugPrint('PUNCH_META: Location capture failed - $e');
    }

    return result;
  }

  String _getSource() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'mobile_ios';
    if (Platform.isAndroid) return 'mobile_android';
    if (Platform.isMacOS) return 'mobile_macos';
    return 'mobile';
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (kIsWeb) return 'Web Browser';
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return '${info.name} (${info.model}, iOS ${info.systemVersion})';
      }
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.brand} ${info.model} (Android ${info.version.release})';
      }
      return 'Unknown Device';
    } catch (e) {
      debugPrint('PUNCH_META: Device info failed - $e');
      return 'Unknown Device';
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      // Check service enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('PUNCH_META: Location service disabled');
        return null;
      }

      // Check & request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('PUNCH_META: getCurrentPosition error - $e');
      return null;
    }
  }
}
