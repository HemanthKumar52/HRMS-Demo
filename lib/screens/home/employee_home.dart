import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/native_ios_attendance_view.dart';
import '../../animations/motion.dart';
import '../requests/apply_leave_screen.dart';
import '../requests/submit_claim_screen.dart';
import '../requests/raise_ticket_screen.dart';
import '../requests/shift_change_screen.dart';
import '../requests/work_type_request_screen.dart';
import '../requests/attendance_request_screen.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => provider.fetchDashboardData(),
      color: AppColors.primary,
      displacement: 40,
      child: SingleChildScrollView(
        physics: isApplePlatform
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
                  'Good ${_getGreeting()},',
                  style: theme.textTheme.bodyMedium,
                )
                .animate()
                .fadeIn(duration: 420.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 2),
            Text(
                  provider.userName.isNotEmpty
                      ? provider.userName.split(' ').first
                      : 'User',
                  style: theme.textTheme.headlineLarge,
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 80.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 80.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 20),

            // Attendance Timer Card
            _AttendanceTimerCard(provider: provider)
                .animate()
                .fadeIn(duration: 420.ms, delay: 160.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 160.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 16),

            // Statistics Row - Leave Balance & Work Stats
            Row(
                  children: [
                    Expanded(
                      child: NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.pastelBlue,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.2),
                              ),
                              child: const Icon(
                                Icons.event_available,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Leave Balance',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(
                                begin: 0,
                                end: provider.leaveBalance,
                              ),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => Text(
                                '$value',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              'Days remaining',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.pastelGreen,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.45), width: 1.2),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Attendance',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(
                                begin: 0,
                                end: provider.attendancePct > 0
                                    ? provider.attendancePct.toInt()
                                    : provider.attendancePercentage.toInt(),
                              ),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => Text(
                                '$value%',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                            Text(
                              'This month',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 240.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 240.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 14),

            // Leave Breakdown - from real API data
            NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.pastelPurple,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.45), width: 1.2),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Leave Summary',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (provider.leaveBalances.isNotEmpty)
                        Row(
                          children: [
                            for (
                              int i = 0;
                              i < provider.leaveBalances.length && i < 3;
                              i++
                            ) ...[
                              if (i > 0) const SizedBox(width: 10),
                              _LeaveTypeChip(
                                label:
                                    (provider.leaveBalances[i]['label'] ??
                                            'Leave')
                                        .toString(),
                                used:
                                    ((provider.leaveBalances[i]['used'] ?? 0)
                                            as num)
                                        .toInt(),
                                total:
                                    ((provider.leaveBalances[i]['total'] ?? 1)
                                            as num)
                                        .toInt()
                                        .clamp(1, 999),
                                color: [
                                  AppColors.success,
                                  AppColors.orange,
                                  AppColors.primary,
                                ][i % 3],
                                isDark: isDark,
                              ),
                            ],
                          ],
                        )
                      else
                        Row(
                          children: [
                            _LeaveTypeChip(
                              label: 'Total',
                              used: 0,
                              total: provider.leaveBalance > 0
                                  ? provider.leaveBalance
                                  : 1,
                              color: AppColors.primary,
                              isDark: isDark,
                            ),
                          ],
                        ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 320.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 320.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 16),

            // Recent Requests Card - from real data
            if (provider.recentActivity.isNotEmpty)
              NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.pastelOrange,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.orange.withValues(alpha: 0.45), width: 1.2),
                              ),
                              child: const Icon(
                                Icons.history,
                                color: AppColors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Recent Requests',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...provider.recentActivity.map((activity) {
                          final status = activity['status'] ?? '';
                          final statusColor = status == 'approved'
                              ? AppColors.success
                              : status == 'rejected'
                              ? AppColors.danger
                              : AppColors.orange;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  activity['type'] == 'leave'
                                      ? Icons.event_busy
                                      : Icons.description,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        activity['date'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 400.ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
            const SizedBox(height: 16),

            // Org Structure Card - from real data
            NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.pastelBlue,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.2),
                            ),
                            child: const Icon(
                              Icons.account_tree_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Work Info', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (provider.userProfile['reporting_manager'] !=
                          null) ...[
                        _OrgChainItem(
                          name:
                              provider
                                  .userProfile['reporting_manager']['name'] ??
                              'Manager',
                          role: 'Reporting Manager',
                          color: AppColors.primary,
                          isFirst: true,
                        ),
                        _OrgChainConnector(),
                      ],
                      _OrgChainItem(
                        name: provider.userName,
                        role:
                            '${provider.designation}${provider.department.isNotEmpty ? ' • ${provider.department}' : ''}',
                        color: AppColors.success,
                        isYou: true,
                        isLast: true,
                      ),
                      if (provider.employeeId.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ID: ${provider.employeeId}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      if (provider.userProfile['date_of_joining'] != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Joined: ${provider.userProfile['date_of_joining']}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 480.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 480.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 16),

            // Quick Actions
            Text('Quick Actions', style: theme.textTheme.titleMedium)
                .animate()
                .fadeIn(duration: 420.ms, delay: 560.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 560.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 12),
            GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _QuickAction(
                      icon: Icons.event_busy,
                      label: 'Leave',
                      color: AppColors.primary,
                      index: 0,
                      onTap: () => Navigator.push(
                        context,
                        Motion.pageRoute(const ApplyLeaveScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.receipt,
                      label: 'Claims',
                      color: AppColors.success,
                      index: 1,
                      onTap: () => Navigator.push(
                        context,
                        Motion.pageRoute(const SubmitClaimScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.confirmation_num,
                      label: 'Tickets',
                      color: AppColors.orange,
                      index: 2,
                      onTap: () => Navigator.push(
                        context,
                        Motion.pageRoute(const RaiseTicketScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.swap_horiz,
                      label: 'Shift',
                      color: AppColors.secondary,
                      index: 3,
                      onTap: () => Navigator.push(
                        context,
                        Motion.pageRoute(const ShiftChangeScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.work,
                      label: 'Work Type',
                      color: AppColors.pink,
                      index: 4,
                      onTap: () => Navigator.push(
                        context,
                        Motion.pageRoute(const WorkTypeRequestScreen()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.access_time,
                      label: 'Attendance',
                      color: AppColors.primaryDark,
                      index: 5,
                      onTap: () => Navigator.push(
                        context,
                        Motion.pageRoute(const AttendanceRequestScreen()),
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 20),

            // Recent Activity
            // Recent Activity
            Text('Recent Activity', style: theme.textTheme.titleMedium)
                .animate()
                .fadeIn(duration: 420.ms, delay: 720.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 720.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 12),
            NeuCard(
                  child: Column(
                    children: [
                      if (provider.recentAttendance.isNotEmpty)
                        _ActivityItem(
                          icon: Icons.login_rounded,
                          color: AppColors.primary,
                          title: 'Attendance Today',
                          subtitle: provider.isPunchedIn
                              ? 'Checked in at ${provider.punchInTime?.hour ?? 0}:${provider.punchInTime?.minute.toString().padLeft(2, '0') ?? '00'}'
                              : 'Not checked in yet',
                          time: provider.isPunchedIn ? 'Today' : 'N/A',
                        ),
                      if (provider.recentAttendance.isNotEmpty)
                        Divider(
                          height: 20,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      if (provider.pendingLeaves > 0) ...[
                        _ActivityItem(
                          icon: Icons.event_busy,
                          color: AppColors.orange,
                          title: 'Leave Request',
                          subtitle:
                              '${provider.pendingLeaves} leave request(s) pending',
                          time: 'Pending',
                        ),
                        Divider(
                          height: 20,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ],
                      if (provider.openTickets > 0)
                        _ActivityItem(
                          icon: Icons.confirmation_num,
                          color: AppColors.secondary,
                          title: 'Tickets',
                          subtitle: '${provider.openTickets} open ticket(s)',
                          time: 'Active',
                        ),
                      if (provider.recentAttendance.isEmpty &&
                          provider.pendingLeaves == 0 &&
                          provider.openTickets == 0)
                        _ActivityItem(
                          icon: Icons.info_outline,
                          color: AppColors.primary,
                          title: 'Welcome!',
                          subtitle: 'No recent activity to display',
                          time: 'Just now',
                        ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 800.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 800.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _LeaveTypeChip extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final Color color;
  final bool isDark;

  const _LeaveTypeChip({
    required this.label,
    required this.used,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: remaining),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: used / total),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$used/$total used',
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTimerCard extends StatefulWidget {
  final AppProvider provider;
  const _AttendanceTimerCard({required this.provider});

  @override
  State<_AttendanceTimerCard> createState() => _AttendanceTimerCardState();
}

class _AttendanceTimerCardState extends State<_AttendanceTimerCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Tick every second so the elapsed timer updates live.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.provider.isPunchedIn) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _elapsed() {
    final start = widget.provider.punchInTime;
    if (start == null) return '00:00:00';
    final diff = DateTime.now().difference(start);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = widget.provider;
    final isPunchedIn = provider.isPunchedIn;

    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPunchedIn
                      ? AppColors.pastelGreen
                      : AppColors.pastelRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPunchedIn ? Icons.timer : Icons.timer_off,
                  color: isPunchedIn ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance', style: theme.textTheme.titleMedium),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPunchedIn
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPunchedIn ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isPunchedIn ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isPunchedIn && provider.punchInTime != null) ...[
            // Running elapsed timer
            Text(
              _elapsed(),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Checked in at ${DateFormat('hh:mm a').format(provider.punchInTime!)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          if (provider.isBiometricPunch && isPunchedIn)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fingerprint,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Checked in via Biometric',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Please use the biometric device to check out',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  if (!isPunchedIn) {
                    NativeAttendanceCheckIn.show(context);
                  } else {
                    provider.togglePunch();
                  }
                },
                icon: Icon(isPunchedIn ? Icons.logout : Icons.login),
                label: Text(
                  isPunchedIn ? 'Check Out' : 'Check In',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPunchedIn
                      ? AppColors.danger
                      : AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AnnouncementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(title),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

// Redesigned org chart - vertical chain style
class _OrgChainItem extends StatelessWidget {
  final String name;
  final String role;
  final Color color;
  final bool isYou;
  final bool isFirst;
  final bool isLast;

  const _OrgChainItem({
    required this.name,
    required this.role,
    required this.color,
    this.isYou = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isYou
            ? color.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.grey.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
        border: isYou
            ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              name[0],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  role,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgChainConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(time, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int index;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.index = 0,
    this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    // Stagger the entrance + continuous float by card position.
    final entranceDelay = (widget.index * 90 + 600).ms;
    final floatDelay = (widget.index * 160).ms;

    final card = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.label} action opened'),
              backgroundColor: widget.color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: AnimatedScale(
        // Interactive press feedback.
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: NeuCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      border: Border.all(color: widget.color.withValues(alpha: 0.4), width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  )
                  // Gentle, continuous floating motion on the icon.
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -4,
                    duration: 1700.ms,
                    delay: floatDelay,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Staggered entrance: fade + slide-up + pop-in scale.
    return card
        .animate()
        .fadeIn(duration: 380.ms, delay: entranceDelay)
        .slideY(
          begin: 0.18,
          end: 0,
          duration: 420.ms,
          delay: entranceDelay,
          curve: Curves.easeOutCubic,
        )
        .scaleXY(
          begin: 0.85,
          end: 1.0,
          duration: 420.ms,
          delay: entranceDelay,
          curve: Curves.easeOutBack,
        );
  }
}

class StatusDot extends StatelessWidget {
  final Color color;
  const StatusDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
