import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

/// Super-admin command center.
///
/// Backed by `GET /v1/admin/command-center`. Surfaces:
///   • org-wide headcount + today's split
///   • month-to-date attendance compliance %
///   • all 7 pending approval categories
///   • per-manager backlog (top 10 with the largest pending queues)
///   • alerts: late check-ins, missing checkouts, off-zone WFH punches
class AdminCommandCenterScreen extends StatefulWidget {
  const AdminCommandCenterScreen({super.key});

  @override
  State<AdminCommandCenterScreen> createState() =>
      _AdminCommandCenterScreenState();
}

class _AdminCommandCenterScreenState extends State<AdminCommandCenterScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Live refresh every 30s while the screen is mounted.
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refreshSilently();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Background refresh — never shows the spinner so the UI doesn't flicker.
  Future<void> _refreshSilently() async {
    try {
      final data = await ApiService.getAdminCommandCenter();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (_) {
      /* leave the previous frame */
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getAdminCommandCenter();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: _buildSections(theme, isDark),
              ),
            ),
    );
  }

  List<Widget> _buildSections(ThemeData theme, bool isDark) {
    final headcount = (_data['headcount'] ?? const {}) as Map;
    final pending = (_data['pending_approvals'] ?? const {}) as Map;
    final managerBacklog = List<Map<String, dynamic>>.from(
      (_data['manager_backlog'] ?? const <dynamic>[]) as List,
    );
    final alerts = (_data['alerts'] ?? const {}) as Map;
    final compliance = ((_data['compliance_pct'] ?? 0) as num).toDouble();
    final asOfRaw = _data['as_of']?.toString();
    String asOf = '';
    if (asOfRaw != null && asOfRaw.isNotEmpty) {
      try {
        asOf = DateFormat(
          'dd MMM yyyy · hh:mm a',
        ).format(DateTime.parse(asOfRaw).toLocal());
      } catch (_) {}
    }

    return [
      // Header.
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_moon_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Command Center',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (asOf.isNotEmpty)
                  Text('As of $asOf', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.1, end: 0),
      const SizedBox(height: 18),

      // Headcount snapshot — today.
      _SectionTitle(label: 'Today'),
      const SizedBox(height: 10),
      Row(
        children: [
          _StatTile(
            label: 'Headcount',
            value: '${headcount['total'] ?? 0}',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'Present',
            value: '${headcount['present'] ?? 0}',
            color: AppColors.success,
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _StatTile(
            label: 'On Leave',
            value: '${headcount['on_leave'] ?? 0}',
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'Absent',
            value: '${headcount['absent'] ?? 0}',
            color: AppColors.danger,
          ),
        ],
      ),
      const SizedBox(height: 18),

      // Compliance.
      NeuCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Attendance Compliance',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${compliance.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (compliance / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Month-to-date', style: theme.textTheme.bodySmall),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 420.ms, delay: 80.ms)
          .slideY(begin: 0.1, end: 0),
      const SizedBox(height: 18),

      // Pending approvals — all 7 types.
      _SectionTitle(label: 'Pending Approvals'),
      const SizedBox(height: 10),
      NeuCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _PendingRow(
                  label: 'Leave Requests',
                  count: ((pending['leave_requests'] ?? 0) as num).toInt(),
                  color: AppColors.warning,
                ),
                _PendingRow(
                  label: 'Claims',
                  count: ((pending['claims'] ?? 0) as num).toInt(),
                  color: AppColors.primary,
                ),
                _PendingRow(
                  label: 'Tickets',
                  count: ((pending['tickets'] ?? 0) as num).toInt(),
                  color: AppColors.secondary,
                ),
                _PendingRow(
                  label: 'Shift Requests',
                  count: ((pending['shift_requests'] ?? 0) as num).toInt(),
                  color: AppColors.pink,
                ),
                _PendingRow(
                  label: 'Work Type Requests',
                  count: ((pending['work_type_requests'] ?? 0) as num).toInt(),
                  color: AppColors.success,
                ),
                _PendingRow(
                  label: 'Regularization',
                  count: ((pending['attendance_requests'] ?? 0) as num).toInt(),
                  color: AppColors.orange,
                ),
                _PendingRow(
                  label: 'Asset Requests',
                  count: ((pending['asset_requests'] ?? 0) as num).toInt(),
                  color: AppColors.danger,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pending['total'] ?? 0}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 420.ms, delay: 160.ms)
          .slideY(begin: 0.1, end: 0),
      const SizedBox(height: 18),

      // Alerts.
      _SectionTitle(label: 'Alerts'),
      const SizedBox(height: 10),
      Row(
            children: [
              _AlertTile(
                icon: Icons.schedule_rounded,
                label: 'Late Today',
                value: '${alerts['late_today'] ?? 0}',
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              _AlertTile(
                icon: Icons.logout_rounded,
                label: 'Missing Out',
                value: '${alerts['missing_checkout_yesterday'] ?? 0}',
                color: AppColors.danger,
              ),
              const SizedBox(width: 10),
              _AlertTile(
                icon: Icons.location_off_rounded,
                label: 'Off-Zone',
                value: '${alerts['off_zone_today'] ?? 0}',
                color: AppColors.secondary,
              ),
            ],
          )
          .animate()
          .fadeIn(duration: 420.ms, delay: 240.ms)
          .slideY(begin: 0.1, end: 0),
      const SizedBox(height: 18),

      // Manager backlog.
      _SectionTitle(label: 'Manager Backlog'),
      const SizedBox(height: 10),
      if (managerBacklog.isEmpty)
        NeuCard(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: Text(
              'All managers are caught up — nothing pending.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        )
      else
        NeuCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (var i = 0; i < managerBacklog.length; i++) ...[
                    _ManagerBacklogRow(row: managerBacklog[i]),
                    if (i != managerBacklog.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 420.ms, delay: 320.ms)
            .slideY(begin: 0.1, end: 0),
    ];
  }
}

// ─── small helpers ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: NeuCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 10),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _PendingRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _AlertTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: NeuCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerBacklogRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _ManagerBacklogRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (row['name'] ?? 'Unknown').toString();
    final empId = (row['employee_id'] ?? '').toString();
    final pending = ((row['pending'] ?? 0) as num).toInt();
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(name, style: theme.textTheme.titleSmall),
      subtitle: Text(empId, style: theme.textTheme.bodySmall),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$pending pending',
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load command center',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
