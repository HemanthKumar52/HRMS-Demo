import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../animations/motion.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../services/device_security_service.dart';
import '../auth/login_screen.dart';
import '../developer_mode_blocked_screen.dart';
import '../shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Request all permissions upfront during splash — no separate onboarding page.
    unawaited(_requestPermissions());

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final name = prefs.getString('user_name');

    if (!mounted) return;

    bool isValidSession = false;
    if (token != null && name != null && name.isNotEmpty) {
      try {
        final userData = await ApiService.getCurrentUser().timeout(
          const Duration(seconds: 5),
        );
        isValidSession = true;
        if (mounted) {
          final provider = context.read<AppProvider>();
          final roleStr = userData['role'] ?? 'employee';
          if (roleStr == 'admin') {
            provider.setRole(UserRole.admin);
          } else if (roleStr == 'hr') {
            provider.setRole(UserRole.hr);
          } else if (roleStr == 'manager') {
            provider.setRole(UserRole.manager);
          } else {
            provider.setRole(UserRole.employee);
          }
        }
      } catch (e) {
        await prefs.remove('auth_token');
        isValidSession = false;
      }
    }

    if (!mounted) return;

    // Check device security (developer mode, root, jailbreak) in release builds.
    if (!kDebugMode) {
      final compromised = await DeviceSecurityService.instance
          .isDeviceCompromised();
      if (compromised && mounted) {
        final safe = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const DeveloperModeBlockedScreen(),
            fullscreenDialog: true,
          ),
        );
        if (safe != true || !mounted) return;
      }
    }

    if (!mounted) return;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final next = isValidSession ? const ShellScreen() : const LoginScreen();
      Navigator.pushReplacement(context, Motion.pageRoute(next));
    });
  }

  /// Request camera, location, notifications, and photos all at once.
  /// The OS shows its own native dialogs — we just fire and forget.
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.notification,
      Permission.photos,
    ].request();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF0F0F1A),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6B3FA0).withValues(alpha: 0.5),
                      const Color(0xFF3D1F6D).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -100,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6B3FA0).withValues(alpha: 0.45),
                      const Color(0xFF3D1F6D).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // pPULSE brand mark (head + shoulders), exact official logo.
                      SizedBox(
                        width: 112,
                        height: 104,
                        child: CustomPaint(painter: _PpulseLogoPainter()),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'p',
                              style: TextStyle(
                                color: Color(0xFF9B6DFF),
                                fontSize: 36,
                                fontWeight: FontWeight.w300,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextSpan(
                              text: 'PULSE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'HRMS, as it should be...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 44),
                        child: Text(
                          'Experience intelligent HR management with '
                          'AI-powered insights and automation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// pPULSE logo — exact official mark from pPULSE_logo.svg (645×600 viewBox):
/// a head circle + a wide rounded "shoulders" body, brand gradient
/// (#6C3BAA → #C8B1E4).
class _PpulseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 644.488; // uniform scale from the 644.488-wide art
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6C3BAA), Color(0xFFC8B1E4)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 600 * s));

    // Head (circle, from the rotated rect: center 319.374,162.953 r 162.953)
    canvas.drawCircle(Offset(319.374 * s, 162.953 * s), 162.953 * s, paint);

    // Shoulders / body (exact path from the SVG)
    final body = Path()
      ..moveTo(644.488 * s, 329.585 * s)
      ..cubicTo(
          644.488 * s, 478.931 * s, 523.419 * s, 600 * s, 374.074 * s, 600 * s)
      ..lineTo(270.415 * s, 600 * s)
      ..cubicTo(121.069 * s, 600 * s, 0, 478.931 * s, 0, 329.585 * s)
      ..cubicTo(0, 284.781 * s, 36.3205 * s, 248.461 * s, 81.1243 * s,
          248.461 * s)
      ..lineTo(563.364 * s, 248.461 * s)
      ..cubicTo(608.168 * s, 248.461 * s, 644.488 * s, 284.781 * s, 644.488 * s,
          329.585 * s)
      ..close();
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
