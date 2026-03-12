import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Please enter username and password');
      return;
    }

    // Determine role from username
    UserRole? role;
    if (username == 'employee') {
      role = UserRole.employee;
    } else if (username == 'manager') {
      role = UserRole.manager;
    } else if (username == 'hr') {
      role = UserRole.hr;
    }

    if (role == null) {
      setState(() => _errorText = 'Invalid username. Use: employee, manager, or hr');
      return;
    }

    if (password != '12345') {
      setState(() => _errorText = 'Incorrect password');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final provider = context.read<AppProvider>();
    provider.setRole(role);
    provider.login();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0D0F1A), const Color(0xFF1A1D2E)]
                : [AppColors.lightBg, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'PP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    'PPulse HRMS',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 300.ms),
                  const SizedBox(height: 32),

                  // Login card
                  NeuCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error message
                        if (_errorText != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorText!,
                                    style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Username
                        _buildInput(
                          controller: _usernameController,
                          hint: 'Username or Email',
                          icon: Icons.person_outline,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _buildInput(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          isDark: isDark,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Sign in button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SSO buttons
                        Row(
                          children: [
                            Expanded(
                              child: _SSOButton(
                                label: 'Microsoft',
                                icon: Icons.window,
                                color: const Color(0xFF00A4EF),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SSOButton(
                                label: 'Google',
                                icon: Icons.g_mobiledata,
                                color: const Color(0xFFEA4335),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 400.ms, curve: Curves.easeOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    required bool isDark,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : AppColors.lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: isDark ? Colors.white : AppColors.lightText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _SSOButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SSOButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey[200]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
