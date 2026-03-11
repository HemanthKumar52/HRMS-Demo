import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme section
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (0 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (0 * 80).ms, curve: Curves.easeOut),
            const SizedBox(height: 12),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your preferred appearance',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _ThemeTile(
                    icon: Icons.light_mode_rounded,
                    label: 'Light Mode',
                    subtitle: 'Clean and bright',
                    color: AppColors.warning,
                    isSelected:
                        themeProvider.themeMode == AppThemeMode.light,
                    onTap: () =>
                        themeProvider.setTheme(AppThemeMode.light),
                  ),
                  const SizedBox(height: 8),
                  _ThemeTile(
                    icon: Icons.dark_mode_rounded,
                    label: 'Dark Mode',
                    subtitle: 'Easy on the eyes',
                    color: AppColors.secondary,
                    isSelected:
                        themeProvider.themeMode == AppThemeMode.dark,
                    onTap: () =>
                        themeProvider.setTheme(AppThemeMode.dark),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (1 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (1 * 80).ms, curve: Curves.easeOut),
            const SizedBox(height: 24),

            // Notifications section
            Text(
              'Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (2 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (2 * 80).ms, curve: Curves.easeOut),
            const SizedBox(height: 12),
            NeuCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Push Notifications',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Receive alerts for approvals, announcements',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (v) =>
                        setState(() => _notificationsEnabled = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (3 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (3 * 80).ms, curve: Curves.easeOut),
            const SizedBox(height: 24),

            // General section
            Text(
              'General',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (4 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (4 * 80).ms, curve: Curves.easeOut),
            const SizedBox(height: 12),
            NeuCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    trailing: Text(
                      'English',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      // TODO: Language selector
                    },
                  ),
                  Divider(
                    height: 24,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    trailing: Text(
                      'v1.0.0',
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'PPulse HRMS',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            '\u00a9 2026 PPulse Technologies',
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (5 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (5 * 80).ms, curve: Curves.easeOut),
            const SizedBox(height: 24),

            // Legal section
            Text(
              'Legal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (6 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (6 * 80).ms, curve: Curves.easeOut),
            const SizedBox(height: 12),
            NeuCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      _showPrivacyPolicy(context);
                    },
                  ),
                  Divider(
                    height: 24,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      _showTermsOfService(context);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (7 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (7 * 80).ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Privacy Policy',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(
                'Last updated: March 1, 2026',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _policySection(theme, 'Data Collection',
                  'We collect personal information necessary for HR management including name, contact details, attendance records, and employment information.'),
              _policySection(theme, 'Data Usage',
                  'Your data is used solely for HR operations including attendance tracking, leave management, payroll processing, and performance management.'),
              _policySection(theme, 'Data Protection',
                  'We implement industry-standard security measures to protect your personal information. All data is encrypted in transit and at rest.'),
              _policySection(theme, 'Data Sharing',
                  'Your personal data is not shared with third parties except as required by law or with your explicit consent.'),
              _policySection(theme, 'Your Rights',
                  'You have the right to access, correct, or request deletion of your personal data. Contact HR for any privacy-related requests.'),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Terms of Service',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(
                'Last updated: March 1, 2026',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _policySection(theme, 'Acceptance',
                  'By using PPulse HRMS, you agree to these terms of service and our privacy policy.'),
              _policySection(theme, 'Usage',
                  'This application is provided for employee self-service and HR management purposes only. Unauthorized use is prohibited.'),
              _policySection(theme, 'Account Security',
                  'You are responsible for maintaining the confidentiality of your login credentials and all activities under your account.'),
              _policySection(theme, 'Modifications',
                  'We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policySection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.1)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing,
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}
