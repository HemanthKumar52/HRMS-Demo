import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import 'admin_biometric_devices_screen.dart';
import 'admin_geofences_screen.dart';
import 'admin_round3_screens.dart';
import 'admin_round4_screens.dart';

/// iOS-style settings screen for admin panel.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        physics: isApplePlatform ? const BouncingScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Configuration
          _SectionHeader(label: 'CONFIGURATION'),
          _SettingsGroup(
            isDark: isDark,
            bgColor: bgColor,
            children: [
              _SettingsTile(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.secondary,
                title: 'Office Geofences',
                onTap: () => _open(context, const AdminGeofencesScreen()),
              ),
              _SettingsTile(
                icon: Icons.fingerprint,
                iconColor: AppColors.primary,
                title: 'Biometric Devices',
                onTap: () =>
                    _open(context, const AdminBiometricDevicesScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Monitoring
          _SectionHeader(label: 'MONITORING'),
          _SettingsGroup(
            isDark: isDark,
            bgColor: bgColor,
            children: [
              _SettingsTile(
                icon: Icons.storage_rounded,
                iconColor: AppColors.primary,
                title: 'System Stats',
                onTap: () => _open(context, const AdminSystemStatsScreen()),
              ),
              _SettingsTile(
                icon: Icons.map_outlined,
                iconColor: AppColors.success,
                title: 'Live Attendance Feed',
                onTap: () => _open(context, const AdminLiveActivityScreen()),
              ),
              _SettingsTile(
                icon: Icons.campaign_outlined,
                iconColor: AppColors.warning,
                title: 'Push Announcements',
                onTap: () => _open(context, const AdminPushCampaignScreen()),
              ),
              _SettingsTile(
                icon: Icons.face_retouching_natural_rounded,
                iconColor: AppColors.secondary,
                title: 'Face Enrollment',
                onTap: () => _open(context, const AdminFaceEnrollmentsScreen()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security
          _SectionHeader(label: 'SECURITY'),
          _SettingsGroup(
            isDark: isDark,
            bgColor: bgColor,
            children: [
              _SettingsTile(
                icon: Icons.lan_rounded,
                iconColor: AppColors.danger,
                title: 'IP Allowlist',
                onTap: () => _open(context, const AdminAllowedIpsScreen()),
              ),
              _SettingsTile(
                icon: Icons.history_rounded,
                iconColor: AppColors.primary,
                title: 'Login Records',
                onTap: () => _open(context, const AdminLoginRecordsScreen()),
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(adaptivePageRoute(child: screen));
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final bool isDark;
  final Color bgColor;
  final List<Widget> children;
  const _SettingsGroup({
    required this.isDark,
    required this.bgColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: Icon(
            isApplePlatform
                ? CupertinoIcons.chevron_forward
                : Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 62),
            child: Divider(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.15),
            ),
          ),
      ],
    );
  }
}
