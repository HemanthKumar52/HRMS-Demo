import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class EmployeeActivityScreen extends StatefulWidget {
  final int employeeId;
  final String name;
  final String initials;
  final Color color;

  const EmployeeActivityScreen({
    super.key,
    required this.employeeId,
    required this.name,
    required this.initials,
    required this.color,
  });

  @override
  State<EmployeeActivityScreen> createState() => _EmployeeActivityScreenState();
}

class _EmployeeActivityScreenState extends State<EmployeeActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getTeamMemberActivity(widget.employeeId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBg
          : theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: widget.name,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? const Center(child: Text('Failed to load activity'))
          : Column(
              children: [
                _buildHeader(theme, isDark),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Attendance'),
                    Tab(text: 'Requests'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(theme, isDark),
                      _buildAttendanceTab(theme, isDark),
                      _buildRequestsTab(theme, isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final emp = _data!['employee'] ?? {};
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: widget.color.withValues(alpha: 0.15),
            child: Text(
              widget.initials,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: widget.color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emp['name'] ?? widget.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${emp['designation'] ?? ''} · ${emp['department'] ?? ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              emp['badge_id'] ?? '',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Profile Info ──

  Widget _buildProfileTab(ThemeData theme, bool isDark) {
    final emp = _data!['employee'] ?? {};
    final logins = (_data!['login_history'] as List?) ?? [];
    final lastLogin = logins.isNotEmpty
        ? Map<String, dynamic>.from(logins.first)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        children: [
          // Basic Info
          NeuCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _profileRow(
                  Icons.badge_outlined,
                  'Employee ID',
                  emp['badge_id'] ?? '',
                  isDark,
                ),
                _profileRow(
                  Icons.work_outline,
                  'Designation',
                  emp['designation'] ?? '',
                  isDark,
                ),
                _profileRow(
                  Icons.business,
                  'Department',
                  emp['department'] ?? '',
                  isDark,
                ),
                _profileRow(
                  Icons.email_outlined,
                  'Email',
                  emp['email'] ?? '',
                  isDark,
                ),
                _profileRow(
                  Icons.phone_outlined,
                  'Phone',
                  emp['phone'] ?? '',
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value, bool isDark) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    final s = ts.toString();
    final date = s.split('T').first;
    final time = s.contains('T') ? s.split('T').last.substring(0, 5) : '';
    return '$date  $time';
  }

  // ── Tab 2: Attendance ──

  Widget _buildAttendanceTab(ThemeData theme, bool isDark) {
    final records = (_data!['attendance'] as List?) ?? [];
    if (records.isEmpty) {
      return Center(
        child: Text(
          'No attendance records',
          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = Map<String, dynamic>.from(records[index]);

        return NeuCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + source badge
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r['date'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if ((r['worked_hours'] ?? '').toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Worked: ${r['worked_hours']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Check-in / Check-out times
              Row(
                children: [
                  _timeChip('In', r['punch_in'], AppColors.success, isDark),
                  const SizedBox(width: 16),
                  _timeChip('Out', r['punch_out'], AppColors.danger, isDark),
                  const Spacer(),
                  if ((r['source'] ?? '').toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (r['source'] ?? '')
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              // Check-in location
              if ((r['punch_in_location'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _locationRow(
                  Icons.login_rounded,
                  'In',
                  r['punch_in_location'],
                  AppColors.success,
                  isDark,
                ),
              ],
              // Check-out location
              if ((r['punch_out_location'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                _locationRow(
                  Icons.logout_rounded,
                  'Out',
                  r['punch_out_location'],
                  AppColors.danger,
                  isDark,
                ),
              ],
              // Device info
              if ((r['device'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(Icons.phone_android, r['device'], isDark),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
      },
    );
  }

  Widget _timeChip(String label, dynamic time, Color color, bool isDark) {
    final t = time?.toString() ?? '';
    final display = t.isNotEmpty && t != 'null'
        ? t.split('T').last.substring(0, 5)
        : '--:--';
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $display',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Requests ──

  Widget _buildRequestsTab(ThemeData theme, bool isDark) {
    final requests = (_data!['requests'] as List?) ?? [];
    if (requests.isEmpty) {
      return Center(
        child: Text(
          'No requests',
          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = Map<String, dynamic>.from(requests[index]);
        final type = r['type'] ?? '';
        final color = _typeColor(type);

        return NeuCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['title'] ?? type,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r['request_id'] ?? ''} · ${r['created_at']?.toString().split('T').first ?? ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: (r['status'] ?? 'requested')
                    .toString()
                    .replaceFirst('requested', 'Pending')
                    .replaceFirst('approved', 'Approved')
                    .replaceFirst('rejected', 'Rejected'),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Leave':
        return AppColors.primary;
      case 'Ticket':
        return AppColors.orange;
      case 'Shift':
        return AppColors.pink;
      case 'Work Type':
        return AppColors.secondary;
      case 'Attendance':
        return AppColors.warning;
      case 'Asset':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Widget _locationRow(
    IconData icon,
    String label,
    String location,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
