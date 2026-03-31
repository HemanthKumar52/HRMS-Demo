import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../animations/motion.dart';
import '../../animations/shake_animation.dart';
import '../../providers/app_provider.dart';
import '../shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;
  bool _showLoginFields = false;

  late AnimationController _orbController;
  late AnimationController _pulseController;
  late ShakeController _shakeController;

  String get _apiHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  String get _baseUrl => 'http://$_apiHost:8000';

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _shakeController = ShakeController(vsync: this);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _orbController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please enter username and password');
      _shakeController.shake();
      return;
    }
    setState(() { _errorText = null; _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final userData = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('employee_id', userData['employee_id'] ?? '');
        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setString('user_designation', userData['designation'] ?? '');
        await prefs.setString('user_department', userData['department'] ?? '');
        if (!mounted) return;
        final provider = context.read<AppProvider>();
        provider.setUserName(userData['name'] ?? '');
        provider.setDesignation(userData['designation'] ?? '');
        provider.setDepartment(userData['department'] ?? '');
        provider.setEmployeeId(userData['employee_id'] ?? '');
        provider.login();
        await provider.fetchDashboardData();
        Navigator.pushReplacement(
          context,
          Motion.pageRoute(const ShellScreen()),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() => _errorText = data['detail'] ?? 'Invalid credentials');
        _shakeController.shake();
      }
    } catch (e) {
      setState(() => _errorText = 'Connection error. Please try again.');
      _shakeController.shake();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMicrosoftSSO() async {
    final url = Uri.parse('$_baseUrl/v1/auth/microsoft/login?redirect_uri=ppulse://auth-callback');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Google SSO (hidden for now)
  // ignore: unused_element
  Future<void> _handleGoogleSSO() async {
    final url = Uri.parse('$_baseUrl/v1/auth/google/login?redirect_uri=ppulse://auth-callback');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ═══ DARK BACKGROUND ═══
          Container(width: size.width, height: size.height, color: const Color(0xFF0F0F1A)),

          // ═══ LARGE PURPLE GRADIENT CIRCLES (matching web screenshot exactly) ═══

          // Top-right large purple circle
          AnimatedBuilder(
            animation: _orbController,
            builder: (_, __) {
              final t = _orbController.value;
              final dx = sin(t * 2 * pi) * 30;
              final dy = cos(t * 2 * pi) * 20;
              return Positioned(
                top: -size.height * 0.15 + dy,
                right: -size.width * 0.25 + dx,
                child: Container(
                  width: size.width * 1.1,
                  height: size.width * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      colors: [
                        const Color(0xFF6B3FA0).withValues(alpha: 0.6),
                        const Color(0xFF5B2D8E).withValues(alpha: 0.35),
                        const Color(0xFF3D1F6D).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom-left large purple circle
          AnimatedBuilder(
            animation: _orbController,
            builder: (_, __) {
              final t = _orbController.value;
              final dx = cos(t * 2 * pi + 2) * 25;
              final dy = sin(t * 2 * pi + 2) * 20;
              return Positioned(
                bottom: -size.height * 0.12 + dy,
                left: -size.width * 0.3 + dx,
                child: Container(
                  width: size.width * 1.0,
                  height: size.width * 1.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6B3FA0).withValues(alpha: 0.55),
                        const Color(0xFF5B2D8E).withValues(alpha: 0.3),
                        const Color(0xFF3D1F6D).withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 0.6, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Center-right medium purple circle
          AnimatedBuilder(
            animation: _orbController,
            builder: (_, __) {
              final t = _orbController.value;
              final dx = sin(t * 2 * pi + 4) * 20;
              return Positioned(
                top: size.height * 0.3,
                right: -size.width * 0.15 + dx,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7B4FB5).withValues(alpha: 0.4),
                        const Color(0xFF5B2D8E).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ═══ GLASSMORPHISM LOGIN CARD ═══
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E).withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            children: [
                              // ═══ PURPLE PERSON ICON (matching web) ═══
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (_, __) {
                                  final glow = 12 + _pulseController.value * 16;
                                  return Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFF9B6DFF), Color(0xFF6B3FA0)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF9B6DFF).withValues(alpha: 0.4),
                                          blurRadius: glow,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 36),
                                  );
                                },
                              ).animate()
                                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut)
                                  .fadeIn(duration: 500.ms),
                              const SizedBox(height: 20),

                              // ═══ pPULSE TEXT ═══
                              RichText(
                                text: const TextSpan(children: [
                                  TextSpan(text: 'p', style: TextStyle(color: Color(0xFF9B6DFF), fontSize: 28, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic)),
                                  TextSpan(text: 'PULSE', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2)),
                                ]),
                              ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.15, end: 0, duration: 500.ms, delay: 200.ms),
                              const SizedBox(height: 28),

                              // ═══ TAGLINE ═══
                              const Text(
                                'HRMS, as it should be...',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                              ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                              const SizedBox(height: 14),

                              // ═══ SUBTITLE ═══
                              Text(
                                'Experience intelligent HR management with AI-powered insights and automation',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13, height: 1.6),
                              ).animate().fadeIn(duration: 500.ms, delay: 450.ms),
                              const SizedBox(height: 36),

                              // ═══ ANIMATED CONTENT ═══
                              AnimatedSize(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: _showLoginFields ? _buildLoginForm() : _buildWelcomeActions(),
                                ),
                              ).animate().fadeIn(duration: 500.ms, delay: 550.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // ═══ SKELETON LOADING ═══
          if (_isLoading) _buildSkeletonOverlay(size),
        ],
      ),
    );
  }

  // ─── Welcome (initial lock screen) ───
  Widget _buildWelcomeActions() {
    return Column(
      key: const ValueKey('welcome'),
      children: [
        // Sign In button (cream/white matching web)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _showLoginFields = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0EDE5),
              foregroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ─── Login form (after Sign In tap) ───
  Widget _buildLoginForm() {
    return ShakeAnimation(
      controller: _shakeController,
      child: Column(
      key: const ValueKey('form'),
      children: [
        if (_errorText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_errorText!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        _GlassInput(controller: _usernameController, hint: 'Username or Email', icon: Icons.person_outline),
        const SizedBox(height: 14),
        _GlassInput(controller: _passwordController, hint: 'Password', icon: Icons.lock_outline, obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.white.withValues(alpha: 0.4)),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),

        // Login button (gradient dark→purple)
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFF2D3748), Color(0xFF6B3FA0)]),
              boxShadow: [BoxShadow(color: const Color(0xFF6B3FA0).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.login, size: 20),
              label: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, foregroundColor: Colors.white, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Divider
        Row(children: [
          Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.15), Colors.transparent])))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1))),
          Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.15), Colors.transparent])))),
        ]),
        const SizedBox(height: 16),

        // Microsoft SSO
        _MicrosoftSSOButton(onPressed: _handleMicrosoftSSO),

        // Google SSO (hidden - uncomment to show)
        // const SizedBox(height: 10),
        // _GoogleSSOButton(onPressed: _handleGoogleSSO),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
            child: Text('Forgot Password?', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => setState(() => _showLoginFields = false),
          child: Text('Back', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14))),
      ],
    ),
    );
  }

  Widget _buildSkeletonOverlay(Size size) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F0F1A).withValues(alpha: 0.9),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: size.width * 0.85, constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: const Color(0xFF1A1A2E).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
              child: Column(children: [
                _SkeletonBox(width: 60, height: 60, borderRadius: 30),
                const SizedBox(height: 20),
                _SkeletonBox(width: 140, height: 16),
                const SizedBox(height: 12),
                _SkeletonBox(width: 200, height: 12),
                const SizedBox(height: 30),
                _SkeletonBox(width: double.infinity, height: 48, borderRadius: 12),
                const SizedBox(height: 14),
                _SkeletonBox(width: double.infinity, height: 48, borderRadius: 12),
                const SizedBox(height: 20),
                _SkeletonBox(width: double.infinity, height: 50, borderRadius: 12),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Signing in...', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// GLASS INPUT
// ═══════════════════════════════════════════
class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  const _GlassInput({required this.controller, required this.hint, required this.icon, this.obscure = false, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller, obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 20),
          suffixIcon: suffix, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SKELETON SHIMMER
// ═══════════════════════════════════════════
class _SkeletonBox extends StatelessWidget {
  final double width, height, borderRadius;
  const _SkeletonBox({required this.width, required this.height, this.borderRadius = 8});
  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius), color: Colors.white.withValues(alpha: 0.06)))
        .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.05));
  }
}

// ═══════════════════════════════════════════
// MICROSOFT SSO BUTTON
// ═══════════════════════════════════════════
class _MicrosoftSSOButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _MicrosoftSSOButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8F9FA), foregroundColor: const Color(0xFF2D2D44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0, side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 20, height: 20, child: CustomPaint(painter: _MicrosoftLogoPainter())),
          const SizedBox(width: 10),
          const Text('Sign in with Microsoft', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// Google SSO Button (hidden, ready for future)
// ignore: unused_element
class _GoogleSSOButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleSSOButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF8F9FA), foregroundColor: const Color(0xFF2D2D44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0, side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleLogoPainter())),
          const SizedBox(width: 10),
          const Text('Sign in with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// Microsoft logo: 4-color squares
class _MicrosoftLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width * 0.08; final half = (size.width - gap) / 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, half, half), Paint()..color = const Color(0xFFF25022));
    canvas.drawRect(Rect.fromLTWH(half + gap, 0, half, half), Paint()..color = const Color(0xFF7FBA00));
    canvas.drawRect(Rect.fromLTWH(0, half + gap, half, half), Paint()..color = const Color(0xFF00A4EF));
    canvas.drawRect(Rect.fromLTWH(half + gap, half + gap, half, half), Paint()..color = const Color(0xFFFFB900));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Google logo: 4-color arcs
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2); final r = size.width / 2; final sw = size.width * 0.18;
    final rect = Rect.fromCircle(center: c, radius: r - sw / 2);
    canvas.drawArc(rect, -pi / 4, -pi / 2, false, Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawArc(rect, pi / 4, pi / 2, false, Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawArc(rect, 3 * pi / 4, pi / 2, false, Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawArc(rect, -3 * pi / 4, -pi / 2, false, Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawRect(Rect.fromLTWH(c.dx - sw * 0.2, c.dy - sw / 2, r, sw), Paint()..color = const Color(0xFF4285F4));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
