import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

/// Manager's team attendance — shows each direct report's check-in time,
/// location, work type, and status for today.
class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  bool _loading = true;
  String? _error;
  int _total = 0, _present = 0, _absent = 0, _onLeave = 0;
  List<Map<String, dynamic>> _members = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiService.getTeamAttendance();
      if (!mounted) return;
      setState(() {
        _total = ((r['total_employees'] ?? 0) as num).toInt();
        _present = ((r['present_today'] ?? 0) as num).toInt();
        _absent = ((r['absent_today'] ?? 0) as num).toInt();
        _onLeave = ((r['on_leave_today'] ?? 0) as num).toInt();
        _members = List<Map<String, dynamic>>.from(
          r['team_members'] ?? const [],
        );
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

  List<Map<String, dynamic>> get _filtered => _filter == 'all'
      ? _members
      : _members.where((m) => m['status'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Team Attendance',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Filter chips
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        value: '$_total',
                        color: AppColors.primary,
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Present',
                        value: '$_present',
                        color: AppColors.success,
                        selected: _filter == 'present',
                        onTap: () => setState(() => _filter = 'present'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Absent',
                        value: '$_absent',
                        color: AppColors.danger,
                        selected: _filter == 'absent',
                        onTap: () => setState(() => _filter = 'absent'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Leave',
                        value: '$_onLeave',
                        color: AppColors.warning,
                        selected: _filter == 'on_leave',
                        onTap: () => setState(() => _filter = 'on_leave'),
                      ),
                    ],
                  ).animate().fadeIn(duration: 250.ms),
                  const SizedBox(height: 16),

                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No employees',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      _filtered.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MemberCard(member: _filtered[i])
                            .animate()
                            .fadeIn(duration: 200.ms, delay: (60 + i * 30).ms)
                            .slideY(begin: 0.03, end: 0),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const _MemberCard({required this.member});

  String _fmtTime(String t) {
    final p = t.split(':');
    if (p.length < 2) return t;
    final h = int.tryParse(p[0]) ?? 0;
    return '${h == 0 ? 12 : (h > 12 ? h - 12 : h)}:${p[1]} ${h >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = member['name']?.toString() ?? '—';
    final status = member['status']?.toString() ?? 'absent';
    final pIn = member['punch_in']?.toString();
    final pOut = member['punch_out']?.toString();
    final loc = member['punch_in_location']?.toString() ?? '';
    final src = member['punch_in_source']?.toString() ?? '';
    final dept = member['department']?.toString() ?? '';
    final wt = member['work_type']?.toString() ?? '';

    final sc = status == 'present'
        ? AppColors.success
        : status == 'on_leave'
        ? AppColors.warning
        : AppColors.danger;
    final sl = status == 'present'
        ? 'Present'
        : status == 'on_leave'
        ? 'On Leave'
        : 'Absent';
    final si = status == 'present'
        ? Icons.check_circle_rounded
        : status == 'on_leave'
        ? Icons.event_busy_rounded
        : Icons.cancel_rounded;

    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: sc.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: sc,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (dept.isNotEmpty)
                      Text(
                        dept,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(si, size: 14, color: sc),
                    const SizedBox(width: 4),
                    Text(
                      sl,
                      style: TextStyle(
                        color: sc,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status == 'present') ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (pIn != null)
                  _Detail(
                    Icons.login_rounded,
                    'Check-in',
                    _fmtTime(pIn),
                    AppColors.success,
                  ),
                if (pOut != null)
                  _Detail(
                    Icons.logout_rounded,
                    'Check-out',
                    _fmtTime(pOut),
                    AppColors.danger,
                  ),
                if (loc.isNotEmpty)
                  _Detail(
                    Icons.location_on_rounded,
                    'Location',
                    loc,
                    AppColors.primary,
                  ),
                if (wt.isNotEmpty)
                  _Detail(
                    Icons.work_rounded,
                    'Work Type',
                    wt,
                    AppColors.secondary,
                  ),
                if (src.isNotEmpty)
                  _Detail(
                    src == 'mobile' ? Icons.phone_android : Icons.fingerprint,
                    'Via',
                    src == 'mobile' ? 'Mobile' : src,
                    AppColors.orange,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _Detail(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
