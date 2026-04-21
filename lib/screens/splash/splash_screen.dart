import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../animations/motion.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
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
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF9B6DFF), Color(0xFF6B3FA0)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF9B6DFF,
                              ).withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 28),
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
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                          letterSpacing: 0.5,
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
