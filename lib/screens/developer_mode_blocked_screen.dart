import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/device_security_service.dart';

class DeveloperModeBlockedScreen extends StatefulWidget {
  const DeveloperModeBlockedScreen({super.key});

  @override
  State<DeveloperModeBlockedScreen> createState() =>
      _DeveloperModeBlockedScreenState();
}

class _DeveloperModeBlockedScreenState extends State<DeveloperModeBlockedScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckAndDismiss();
    }
  }

  Future<void> _recheckAndDismiss() async {
    final compromised = await DeviceSecurityService.instance
        .isDeviceCompromised();
    if (!compromised && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openSettings() async {
    if (Platform.isAndroid) {
      final uri = Uri.parse(
        'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
      );
      try {
        await launchUrl(uri);
      } catch (_) {
        // Fallback: open general settings
        await launchUrl(Uri.parse('app-settings:'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 44,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Developer Settings Detected',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'For security reasons, this app cannot run while '
                    'Developer Options are enabled on your device.\n\n'
                    'Please turn off Developer Settings and return to '
                    'the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  if (Platform.isAndroid) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _openSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Open Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
