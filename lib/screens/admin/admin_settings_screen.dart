import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import 'admin_geofences_screen.dart';
import 'admin_round3_screens.dart';
import 'admin_round4_screens.dart';

/// Admin "Settings" tab — streamlined for core operational tools.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text(
              'Admin Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Organization configuration & monitoring',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 18),

            _Section(label: 'Configuration'),
            _Tile(
              icon: Icons.location_on_outlined,
              color: AppColors.secondary,
              title: 'Office Geofences',
              subtitle: 'Edit allowed punch-in zones',
              onTap: () => _open(context, const AdminGeofencesScreen()),
            ),

            const SizedBox(height: 14),
            _Section(label: 'Monitoring'),
            _Tile(
              icon: Icons.storage_rounded,
              color: AppColors.primary,
              title: 'System Stats',
              subtitle: 'Disk / DB / media usage',
              onTap: () => _open(context, const AdminSystemStatsScreen()),
            ),
            _Tile(
              icon: Icons.map_outlined,
              color: AppColors.success,
              title: 'Live Attendance Feed',
              subtitle: "Today's punches with location",
              onTap: () => _open(context, const AdminLiveActivityScreen()),
            ),
            _Tile(
              icon: Icons.campaign_outlined,
              color: AppColors.warning,
              title: 'Push Announcements',
              subtitle: 'Send notification to employees',
              onTap: () => _open(context, const AdminPushCampaignScreen()),
            ),
            _Tile(
              icon: Icons.face_retouching_natural_rounded,
              color: AppColors.secondary,
              title: 'Face Enrollment',
              subtitle: 'Manage enrolled face embeddings',
              onTap: () => _open(context, const AdminFaceEnrollmentsScreen()),
            ),

            const SizedBox(height: 14),
            _Section(label: 'Security'),
            _Tile(
              icon: Icons.lan_rounded,
              color: AppColors.danger,
              title: 'IP Allowlist',
              subtitle: 'Restrict logins to specific networks',
              onTap: () => _open(context, const AdminAllowedIpsScreen()),
            ),
            _Tile(
              icon: Icons.history_rounded,
              color: AppColors.primary,
              title: 'Login Records',
              subtitle: 'Login history with device + location',
              onTap: () => _open(context, const AdminLoginRecordsScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 6, 0, 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
