import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../theme/adaptive_colors.dart';
import '../../widgets/ios_screen_wrapper.dart';
import '../../widgets/native_ios_views.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/adaptive_list.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../services/app_lock_service.dart';
import '../../utils/platform_adaptive.dart';
import '../../utils/responsive.dart';
import '../dashboard/org_chart_screen.dart';
import 'face_enrollment_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isSyncing = false;
  String _appVersion = '1.0.0';
  bool _isFaceEnrolled = false;
  bool _appLockEnabled = false;
  bool _deviceSupportsLock = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkFaceEnrollment();
    _checkAppLock();
  }

  Future<void> _checkFaceEnrollment() async {
    final enrolled = await ApiService.isFaceEnrolled();
    if (mounted) setState(() => _isFaceEnrolled = enrolled);
  }

  Future<void> _checkAppLock() async {
    final supported = await AppLockService.instance.isDeviceSupported();
    final enabled = await AppLockService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _deviceSupportsLock = supported;
        _appLockEnabled = enabled;
      });
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      // Verify biometrics before enabling
      final authenticated = await AppLockService.instance.authenticate();
      if (!authenticated) return;
    }
    await AppLockService.instance.setEnabled(value);
    if (mounted) setState(() => _appLockEnabled = value);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _setNotificationsEnabled(bool v) async {
    setState(() => _notificationsEnabled = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', v);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final appProvider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (shouldUseNativeIOS) {
      return IOSScreenWrapper(
        iosViewType: NativeViewTypes.settings,
        iosParams: {
          'themeMode': themeProvider.themeMode.name,
          'notificationsEnabled': _notificationsEnabled,
          'isFaceEnrolled': _isFaceEnrolled,
          'appLockEnabled': _appLockEnabled,
          'deviceSupportsLock': _deviceSupportsLock,
          'appVersion': _appVersion,
          'userName': appProvider.userName,
          'role': appProvider.role.name,
        },
        onNavigate: (screen, args) {
          switch (screen) {
            case 'faceEnrollment':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaceEnrollmentScreen()),
              );
              break;
            case 'orgChart':
              Navigator.push(
                context,
                adaptivePageRoute(child: const OrgChartScreen()),
              );
              break;
            case 'setThemeLight':
              themeProvider.setTheme(AppThemeMode.light);
              break;
            case 'setThemeDark':
              themeProvider.setTheme(AppThemeMode.dark);
              break;
            case 'toggleNotifications':
              _setNotificationsEnabled(!_notificationsEnabled);
              break;
            case 'toggleAppLock':
              _toggleAppLock(!_appLockEnabled);
              break;
            case 'syncData':
              context.read<AppProvider>().fetchDashboardData();
              break;
            case 'about':
              _showAboutPopup(context);
              break;
            case 'privacyPolicy':
              _showPrivacyPolicy(context);
              break;
            case 'termsOfService':
              _showTermsOfService(context);
              break;
          }
        },
        dartChild: _buildDartScaffold(
          context,
          themeProvider,
          appProvider,
          theme,
          isDark,
        ),
      );
    }

    return _buildDartScaffold(
      context,
      themeProvider,
      appProvider,
      theme,
      isDark,
    );
  }

  Widget _buildDartScaffold(
    BuildContext context,
    ThemeProvider themeProvider,
    AppProvider appProvider,
    ThemeData theme,
    bool isDark,
  ) {
    return Scaffold(
      appBar: adaptiveAppBar(
        context: context,
        title: 'Settings',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        physics: isApplePlatform ? const BouncingScrollPhysics() : null,
        child: ResponsiveCenter(
          maxWidth: 600,
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
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (0 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (0 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
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
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (1 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (1 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),

              // Notifications section
              Text(
                    'Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (2 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (2 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
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
                          onChanged: _setNotificationsEnabled,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (3 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (3 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),

              // Face Enrollment — only show if not enrolled, or if admin
              if (!_isFaceEnrolled || appProvider.role == UserRole.admin)
                NeuCard(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FaceEnrollmentScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural,
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
                                'Face Enrollment',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Set up face check-in',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),

              // App Lock (optional biometric/PIN)
              if (_deviceSupportsLock)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: NeuCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
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
                                'App Lock',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Use device biometrics or PIN to lock app',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _appLockEnabled,
                          onChanged: _toggleAppLock,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Sync section
              Text(
                    'Data',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (4 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (4 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 12),
              NeuCard(
                    onTap: _isSyncing
                        ? null
                        : () async {
                            setState(() => _isSyncing = true);
                            try {
                              await context
                                  .read<AppProvider>()
                                  .fetchDashboardData();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'All data synced successfully',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Sync failed. Check your connection.',
                                  ),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isSyncing = false);
                            }
                          },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _isSyncing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: isApplePlatform
                                      ? const CupertinoActivityIndicator()
                                      : CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.success,
                                        ),
                                )
                              : const Icon(
                                  Icons.sync_rounded,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sync Data',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Refresh all data from the server',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.25),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (5 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (5 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),

              // General section
              Text(
                    'General',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (6 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (6 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 12),
              NeuCard(
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.account_tree_rounded,
                          label: 'Organisation Chart',
                          trailing: const SizedBox.shrink(),
                          onTap: () => Navigator.push(
                            context,
                            adaptivePageRoute(child: const OrgChartScreen()),
                          ),
                        ),
                        Divider(
                          height: 24,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        // Language selector — commented out for now, ready to activate later.
                        // Translations are in lib/l10n/ for 9 languages.
                        // _SettingsRow(
                        //   icon: Icons.language_rounded,
                        //   label: 'Language',
                        //   trailing: Text(
                        //     _currentLanguageName(),
                        //     style: theme.textTheme.bodyMedium?.copyWith(
                        //       color: AppColors.primary,
                        //       fontWeight: FontWeight.w500,
                        //     ),
                        //   ),
                        //   onTap: () => _showLanguagePicker(context),
                        // ),
                        // Divider(
                        //   height: 24,
                        //   color: isDark
                        //       ? Colors.white.withValues(alpha: 0.06)
                        //       : Colors.black.withValues(alpha: 0.08),
                        // ),
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          label: 'About',
                          trailing: Text(
                            'v$_appVersion',
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => _showAboutPopup(context),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (5 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (5 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),

              // Legal section
              Text(
                    'Legal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (6 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (6 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
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
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: (7 * 80).ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: (7 * 80).ms,
                    curve: Curves.easeOutCubic,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language support ────────────────────────────────────────
  // Infrastructure is ready. To activate, uncomment the locale
  // switching in MaterialApp and replace hardcoded strings with
  // AppLocalizations.of(context)!.key calls.
  static const _supportedLanguages = <String, String>{
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'kn': 'ಕನ್ನಡ (Kannada)',
    'ml': 'മലയാളം (Malayalam)',
    'ar': 'العربية (Arabic)',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
  };

  String _currentLanguageName() {
    // For now always English — when locale switching is enabled,
    // read from SharedPreferences('app_locale').
    return 'English';
  }

  void _showLanguagePicker(BuildContext context) {
    final theme = Theme.of(context);
    if (isApplePlatform) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Select Language'),
          message: const Text(
            'Language support is configured and ready to activate.',
          ),
          actions: _supportedLanguages.entries.map((e) {
            final isSelected = e.key == 'en';
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                if (e.key != 'en') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${e.value} translation ready — activate when needed',
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                '${_flagForLocale(e.key)}  ${e.value}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle + header (fixed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Language',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Language support is configured and ready to activate.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Scrollable language list
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: _supportedLanguages.entries.map((e) {
                  final isSelected = e.key == 'en';
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    leading: Text(
                      _flagForLocale(e.key),
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      e.value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 22,
                          )
                        : const Icon(
                            Icons.circle_outlined,
                            color: Colors.grey,
                            size: 22,
                          ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (e.key != 'en') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${e.value} translation ready — activate when needed',
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _flagForLocale(String code) {
    switch (code) {
      case 'en':
        return '🇬🇧';
      case 'hi':
        return '🇮🇳';
      case 'ta':
        return '🇮🇳';
      case 'te':
        return '🇮🇳';
      case 'kn':
        return '🇮🇳';
      case 'ml':
        return '🇮🇳';
      case 'ar':
        return '🇸🇦';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      default:
        return '🌐';
    }
  }

  void _showAboutPopup(BuildContext context) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (isApplePlatform) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('pPULSE'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text('HRMS, as it should be...'),
              const SizedBox(height: 12),
              Text('Version: $_appVersion'),
              Text(
                'Platform: ${Theme.of(context).platform.name.toUpperCase()}',
              ),
              const Text('Developer: PPULSE Technologies'),
              const Text('Support: support@ppulse.com'),
              const SizedBox(height: 8),
              const Text(
                '\u00a9 2026 PPULSE Technologies. All rights reserved.',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon
              Container(
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
                      color: const Color(0xFF9B6DFF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              // App name
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'p',
                      style: TextStyle(
                        color: Color(0xFF9B6DFF),
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text: 'PULSE',
                      style: TextStyle(
                        color: Color(0xFF6B3FA0),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'HRMS, as it should be...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              // Details
              _aboutRow(theme, 'Version', _appVersion),
              _aboutRow(
                theme,
                'Platform',
                Theme.of(context).platform.name.toUpperCase(),
              ),
              _aboutRow(theme, 'Developer', 'PPULSE Technologies'),
              _aboutRow(theme, 'Support', 'support@ppulse.com'),
              const SizedBox(height: 16),
              Text(
                '\u00a9 2026 PPULSE Technologies. All rights reserved.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isApplePlatform
                    ? CupertinoButton.filled(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      )
                    : ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final theme = Theme.of(context);
    Widget sheetContent(ScrollController? scrollController) => Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
          Text('Privacy Policy', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            'Last updated: March 1, 2026',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _policySection(
            theme,
            'Data Collection',
            'We collect personal information necessary for HR management including name, contact details, attendance records, and employment information.',
          ),
          _policySection(
            theme,
            'Data Usage',
            'Your data is used solely for HR operations including attendance tracking, leave management, payroll processing, and performance management.',
          ),
          _policySection(
            theme,
            'Data Protection',
            'We implement industry-standard security measures to protect your personal information. All data is encrypted in transit and at rest.',
          ),
          _policySection(
            theme,
            'Data Sharing',
            'Your personal data is not shared with third parties except as required by law or with your explicit consent.',
          ),
          _policySection(
            theme,
            'Your Rights',
            'You have the right to access, correct, or request deletion of your personal data. Contact HR for any privacy-related requests.',
          ),
        ],
      ),
    );

    if (isApplePlatform) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: sheetContent(null),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) =>
              sheetContent(scrollController),
        ),
      );
    }
  }

  void _showTermsOfService(BuildContext context) {
    final theme = Theme.of(context);
    Widget sheetContent(ScrollController? scrollController) => Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
          Text('Terms of Service', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            'Last updated: March 1, 2026',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _policySection(
            theme,
            'Acceptance',
            'By using PPULSE, you agree to these terms of service and our privacy policy.',
          ),
          _policySection(
            theme,
            'Usage',
            'This application is provided for employee self-service and HR management purposes only. Unauthorized use is prohibited.',
          ),
          _policySection(
            theme,
            'Account Security',
            'You are responsible for maintaining the confidentiality of your login credentials and all activities under your account.',
          ),
          _policySection(
            theme,
            'Modifications',
            'We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.',
          ),
        ],
      ),
    );

    if (isApplePlatform) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: sheetContent(null),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) =>
              sheetContent(scrollController),
        ),
      );
    }
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
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
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
