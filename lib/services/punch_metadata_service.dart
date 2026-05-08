import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
        // Resolve a human-readable place name via the device's native
        // geocoder (CLLocation on iOS, Geocoder on Android). No external
        // API key, no network call to a third party — uses the OS service.
        final name = await _reverseGeocode(
          position.latitude,
          position.longitude,
        );
        if (name != null && name.isNotEmpty) {
          result['location_name'] = name;
        }
      }
    } catch (e) {
      debugPrint('PUNCH_META: Location capture failed - $e');
    }

    return result;
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    // Try Nominatim (OpenStreetMap) first — gives precise street-level addresses.
    try {
      final nominatim = await _nominatimReverse(lat, lng);
      if (nominatim != null && nominatim.isNotEmpty) return nominatim;
    } catch (_) {}

    // Fallback to device's native geocoder.
    try {
      final placemarks = await gc
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = <String>[
        if ((p.street ?? '').isNotEmpty && p.street != p.locality) p.street!,
        if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
        if ((p.locality ?? '').isNotEmpty) p.locality!,
        if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
        if ((p.country ?? '').isNotEmpty) p.country!,
      ];
      final label = parts.where((s) => s.trim().isNotEmpty).toSet().join(', ');
      return label.isEmpty ? null : label;
    } catch (e) {
      debugPrint('PUNCH_META: reverse geocode failed - $e');
      return null;
    }
  }

  /// Nominatim reverse geocoding — free, no API key, street-level precision.
  Future<String?> _nominatimReverse(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1&zoom=18',
    );
    final response = await http
        .get(
          url,
          headers: {
            'User-Agent': 'ppulse-hrms/1.0',
            'Accept-Language': 'en',
          },
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    final addr = data['address'] as Map<String, dynamic>?;
    if (addr == null) return null;

    // Build precise address: road, neighbourhood, suburb, city, state, country
    final parts = <String>[
      if (addr['road'] != null) addr['road'],
      if (addr['neighbourhood'] != null)
        addr['neighbourhood']
      else if (addr['suburb'] != null)
        addr['suburb'],
      if (addr['city'] != null)
        addr['city']
      else if (addr['town'] != null)
        addr['town']
      else if (addr['village'] != null)
        addr['village'],
      if (addr['state'] != null) addr['state'],
      if (addr['country'] != null) addr['country'],
    ];
    final label = parts
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(', ');
    return label.isEmpty ? null : label;
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

  /// Why location failed (if it did). Reset on each capture().
  String? lastLocationError;

  Future<Position?> _getCurrentPosition() async {
    lastLocationError = null;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        lastLocationError = 'Location service is turned off';
        debugPrint('PUNCH_META: Location service disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          lastLocationError = 'Location permission denied';
          debugPrint('PUNCH_META: Location permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        lastLocationError =
            'Location permission permanently denied — enable in Settings';
        debugPrint('PUNCH_META: Location permission denied forever');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint(
        'PUNCH_META: Got position ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      lastLocationError = 'GPS timeout — try moving to an open area';
      debugPrint('PUNCH_META: getCurrentPosition error - $e');
      return null;
    }
  }
}
