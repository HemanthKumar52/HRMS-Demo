import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../auth/login_screen.dart';

/// One-time permissions onboarding screen.
///
/// Asks for camera, location, notifications, and photo library access at first
/// launch so the runtime flows (face check-in, geofencing, push notifications,
/// attachments) all work without permission prompts mid-action.
///
/// We mark a flag in SharedPreferences after the user proceeds so this screen
/// only ever runs once per install.
class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  static const String _flagKey = 'permissions_onboarded_v1';

  /// Returns true if the user has already gone through onboarding.
  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_flagKey) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flagKey, true);
  }

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionItem {
  final IconData icon;
  final String title;
  final String description;
  final Permission permission;
  PermissionStatus? status;

  _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.permission,
  });

  bool get granted =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.limited ||
      status == PermissionStatus.provisional;
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  late final List<_PermissionItem> _items = [
    _PermissionItem(
      icon: Icons.camera_alt_outlined,
      title: 'Camera',
      description: 'Capture your face for secure check-in.',
      permission: Permission.camera,
    ),
    _PermissionItem(
      icon: Icons.location_on_outlined,
      title: 'Location',
      description: 'Verify you are inside the WFH zone or office.',
      permission: Permission.locationWhenInUse,
    ),
    _PermissionItem(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      description: 'Punch reminders, request approvals and announcements.',
      permission: Permission.notification,
    ),
    _PermissionItem(
      icon: Icons.photo_library_outlined,
      title: 'Photos',
      description: 'Attach receipts to claims and tickets.',
      permission: Permission.photos,
    ),
  ];

  bool _isRequesting = false;
  bool _isProceeding = false;

  @override
  void initState() {
    super.initState();
    _refreshStatuses();
  }

  Future<void> _refreshStatuses() async {
    for (final item in _items) {
      item.status = await item.permission.status;
    }
    if (mounted) setState(() {});
  }

  Future<void> _grantAll() async {
    setState(() => _isRequesting = true);
    final results = await [for (final i in _items) i.permission].request();
    for (final item in _items) {
      item.status = results[item.permission];
    }
    if (!mounted) return;
    setState(() => _isRequesting = false);

    // If location is permanently denied, prompt the user to open Settings.
    final loc = _items.firstWhere(
      (i) => i.permission == Permission.locationWhenInUse,
    );
    if (loc.status == PermissionStatus.permanentlyDenied) {
      _showOpenSettings(
        title: 'Location permission needed',
        body:
            'Without location access face check-in cannot verify the WFH zone. '
            'Please enable it in Settings.',
      );
    }
  }

  Future<void> _proceed() async {
    setState(() => _isProceeding = true);
    await PermissionsOnboardingScreen.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      adaptivePageRoute(child: const LoginScreen()),
    );
  }

  void _showOpenSettings({required String title, required String body}) {
    showAdaptiveAlert(
      context: context,
      title: title,
      content: body,
      cancelLabel: 'Not now',
      confirmLabel: 'Open Settings',
      onConfirm: () => openAppSettings(),
    );
  }

  bool get _allGranted => _items.every((i) => i.granted);
  bool get _criticalGranted =>
      _items.firstWhere((i) => i.permission == Permission.camera).granted &&
      _items
          .firstWhere((i) => i.permission == Permission.locationWhenInUse)
          .granted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'A few permissions to get started',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PPULSE needs access to a few things on your device. Camera and '
                'location are required for secure face check-in. The rest are '
                'optional but recommended.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _PermissionTile(
                    item: _items[index],
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isRequesting || _isProceeding ? null : _grantAll,
                  icon: _isRequesting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: isApplePlatform
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white,
                                )
                              : const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    _allGranted ? 'All Permissions Granted' : 'Grant Access',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: _isProceeding ? null : _proceed,
                  child: Text(
                    _criticalGranted ? 'Continue' : 'Skip for now',
                    style: TextStyle(
                      color: _criticalGranted ? AppColors.primary : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final _PermissionItem item;
  final bool isDark;
  const _PermissionTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = item.granted;
    final color = granted ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted
              ? AppColors.success.withValues(alpha: 0.40)
              : Colors.grey.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Icon(item.icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? AppColors.success : Colors.grey.shade400,
            size: 22,
          ),
        ],
      ),
    );
  }
}
