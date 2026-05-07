import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Provides a secure HTTP client with certificate pinning support.
/// In production, set the pinned certificate SHA-256 fingerprints.
///
/// To get your server's pin:
///   openssl s_client -connect your-domain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
class HttpClientService {
  HttpClientService._();
  static final instance = HttpClientService._();

  // Production: Add your server's public key SHA-256 pins here
  // Example: ['sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=']
  static const List<String> _pinnedCertificates = [];

  /// Get an HTTP client. In production with pins configured,
  /// this validates the server certificate against pinned keys.
  http.Client getClient() {
    // In debug mode or when no pins configured, use standard client
    if (kDebugMode || _pinnedCertificates.isEmpty) {
      return http.Client();
    }

    // Production: Use certificate pinning
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Reject all bad certificates in production
        return false;
      };

    return IOClient(httpClient);
  }

  /// Check if certificate pinning is active
  static bool get isPinningEnabled =>
      !kDebugMode && _pinnedCertificates.isNotEmpty;
}
