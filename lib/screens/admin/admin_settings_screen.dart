import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import 'admin_backup_screen.dart';
import 'admin_csv_employees_screen.dart';
import 'admin_email_templates_screen.dart';
import 'admin_geofences_screen.dart';
import 'admin_holidays_screen.dart';
import 'admin_round3_screens.dart';
import 'admin_round4_screens.dart';

/// Admin "Settings" tab — entry point for org-wide configuration:
/// geofences, holidays, email templates, system stats, backups, etc.
///
/// Each tile navigates to a sub-screen. Sub-screens are added incrementally
/// as the Tier 2 / Tier 3 / Tier 4 features land.
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
              'Org-wide configuration and security controls',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 18),

            _Section(label: 'Data'),
            _Tile(
              icon: Icons.upload_file_rounded,
              color: AppColors.primary,
              title: 'Bulk Employee Import / Export',
              subtitle: 'Download all employees as CSV or upload new ones',
              onTap: () => _open(context, const AdminCsvEmployeesScreen()),
            ),
            _Tile(
              icon: Icons.backup_rounded,
              color: AppColors.success,
              title: 'Database Backup',
              subtitle: 'Trigger a pg_dump snapshot of the live database',
              onTap: () => _open(context, const AdminBackupScreen()),
            ),
            _Tile(
              icon: Icons.delete_sweep_rounded,
              color: AppColors.warning,
              title: 'Trash & Recovery',
              subtitle: 'Restore soft-deleted records — coming in Round 3',
              onTap: () => _comingSoon(context, 'Trash recovery'),
            ),

            const SizedBox(height: 14),
            _Section(label: 'Configuration'),
            _Tile(
              icon: Icons.location_on_outlined,
              color: AppColors.secondary,
              title: 'Office Geofences',
              subtitle: 'Edit allowed punch-in zones (DB-backed)',
              onTap: () => _open(context, const AdminGeofencesScreen()),
            ),
            _Tile(
              icon: Icons.event_outlined,
              color: AppColors.orange,
              title: 'Holiday Calendar',
              subtitle: 'Add / remove company holidays',
              onTap: () => _open(context, const AdminHolidaysScreen()),
            ),
            _Tile(
              icon: Icons.email_outlined,
              color: AppColors.pink,
              title: 'Email Templates',
              subtitle: 'Edit welcome / reset / approval email copy',
              onTap: () => _open(context, const AdminEmailTemplatesScreen()),
            ),

            const SizedBox(height: 14),
            _Section(label: 'Observability'),
            _Tile(
              icon: Icons.storage_rounded,
              color: AppColors.primary,
              title: 'System Stats',
              subtitle: 'Disk / DB / media usage gauges',
              onTap: () => _open(context, const AdminSystemStatsScreen()),
            ),
            _Tile(
              icon: Icons.map_outlined,
              color: AppColors.success,
              title: 'Live Attendance Feed',
              subtitle: "See today's punches with lat/lng",
              onTap: () => _open(context, const AdminLiveActivityScreen()),
            ),
            _Tile(
              icon: Icons.campaign_outlined,
              color: AppColors.warning,
              title: 'Push Announcements',
              subtitle: 'Send a notification to a filtered audience',
              onTap: () => _open(context, const AdminPushCampaignScreen()),
            ),
            _Tile(
              icon: Icons.face_retouching_natural_rounded,
              color: AppColors.secondary,
              title: 'Face Enrollment',
              subtitle: 'Manage enrolled face embeddings',
              onTap: () => _open(context, const AdminFaceEnrollmentsScreen()),
            ),
            _Tile(
              icon: Icons.webhook_rounded,
              color: AppColors.orange,
              title: 'Webhooks',
              subtitle: 'Fire HTTP POSTs on approve/reject/punch events',
              onTap: () => _open(context, const AdminWebhooksScreen()),
            ),

            const SizedBox(height: 14),
            _Section(label: 'Security'),
            _Tile(
              icon: Icons.lan_rounded,
              color: AppColors.danger,
              title: 'IP Allowlist',
              subtitle: 'Restrict logins to specific networks (CIDR)',
              onTap: () => _open(context, const AdminAllowedIpsScreen()),
            ),
            _Tile(
              icon: Icons.history_rounded,
              color: AppColors.primary,
              title: 'Login Records',
              subtitle: 'Per-login lat/lng + place + device + IP feed',
              onTap: () => _open(context, const AdminLoginRecordsScreen()),
            ),

            const SizedBox(height: 14),
            _Section(label: 'Compliance'),
            _Tile(
              icon: Icons.shield_outlined,
              color: AppColors.primary,
              title: 'GDPR Tools',
              subtitle: 'Per-user export + right-to-be-forgotten',
              onTap: () => _open(context, const AdminGdprToolsScreen()),
            ),
            _Tile(
              icon: Icons.policy_outlined,
              color: AppColors.warning,
              title: 'Retention Policies',
              subtitle: 'Auto-purge old attendance / audit data',
              onTap: () => _open(context, const AdminRetentionPoliciesScreen()),
            ),
            _Tile(
              icon: Icons.gavel_outlined,
              color: AppColors.success,
              title: 'Consent Ledger',
              subtitle: 'Per-user T&Cs acceptance history',
              onTap: () => _open(context, const AdminConsentLedgerScreen()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — landing in a follow-up round'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
