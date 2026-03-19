import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final role = provider.role;
    final isManagerOrHr = role == UserRole.manager || role == UserRole.hr;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Greetings ──────────────────────────────────────────────
          Text(
            'Good ${_getGreeting()},',
            style: theme.textTheme.bodyMedium,
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 2),
          Text(
            provider.userName.split(' ').first,
            style: theme.textTheme.headlineLarge,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 80.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // ── 2. Attendance Timer ───────────────────────────────────────
          _AttendanceTimerCard(provider: provider)
              .animate()
              .fadeIn(duration: 400.ms, delay: 160.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // ── 3. Quick Actions ──────────────────────────────────────────
          Text('Quick Actions', style: theme.textTheme.titleMedium)
              .animate()
              .fadeIn(duration: 400.ms, delay: 240.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _QuickAction(icon: Icons.event_busy, label: 'Leave', color: AppColors.primary),
              _QuickAction(icon: Icons.receipt, label: 'Claims', color: AppColors.success),
              _QuickAction(icon: Icons.confirmation_num, label: 'Tickets', color: AppColors.orange),
              _QuickAction(icon: Icons.swap_horiz, label: 'Shift', color: AppColors.secondary),
              _QuickAction(icon: Icons.work, label: 'Work Type', color: AppColors.pink),
              _QuickAction(icon: Icons.access_time, label: 'Attendance', color: AppColors.primaryDark),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 320.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // ── 4. Manager Insights (Manager/HR only) ─────────────────────
          if (isManagerOrHr) ...[
            _ManagerInsightsSection(isDark: isDark, role: role),
          ],

          // ── 5. Team Attendance (Manager/HR only) ──────────────────────
          if (isManagerOrHr) ...[
            _TeamAttendanceCard(isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms, delay: 560.ms)
                .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 560.ms, curve: Curves.easeOut),
            const SizedBox(height: 16),
          ],

          // ── 6. Leave Balance ──────────────────────────────────────────
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
                        ),
                        child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('Leave Balance', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: 12),
                        duration: const Duration(milliseconds: 3500),
                        curve: Curves.easeOutExpo,
                        builder: (context, value, _) => Text(
                          '$value',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text('Days remaining', style: theme.textTheme.bodySmall),
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
                        ),
                        child: const Icon(Icons.trending_up, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('Attendance', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: 96),
                        duration: const Duration(milliseconds: 3500),
                        curve: Curves.easeOutExpo,
                        builder: (context, value, _) => Text(
                          '$value%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      Text('This month', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (isManagerOrHr ? 640 : 400).ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (isManagerOrHr ? 640 : 400).ms, curve: Curves.easeOut),
          const SizedBox(height: 14),

          // ── 7. Leave Summary ──────────────────────────────────────────
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
                      ),
                      child: const Icon(Icons.calendar_month, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Leave Summary', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _LeaveTypeChip(label: 'Casual', used: 3, total: 8, color: AppColors.primary, isDark: isDark),
                    const SizedBox(width: 10),
                    _LeaveTypeChip(label: 'Sick', used: 1, total: 6, color: AppColors.orange, isDark: isDark),
                    const SizedBox(width: 10),
                    _LeaveTypeChip(label: 'Earned', used: 2, total: 10, color: AppColors.success, isDark: isDark),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (isManagerOrHr ? 720 : 480).ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (isManagerOrHr ? 720 : 480).ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // ── 8. Performance (Manager/HR only) ──────────────────────────
          if (isManagerOrHr) ...[
            _PerformanceSection(isDark: isDark, role: role),
          ],

          // ── 9. Announcements ──────────────────────────────────────────
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
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Announcements', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AnnouncementItem(
                  title: 'Company Town Hall',
                  subtitle: 'March 15, 2026 at 3:00 PM',
                  icon: Icons.event,
                ),
                const Divider(height: 16),
                _AnnouncementItem(
                  title: 'New Leave Policy Update',
                  subtitle: 'Effective from April 1, 2026',
                  icon: Icons.policy,
                ),
                if (isManagerOrHr) ...[
                  const Divider(height: 16),
                  _AnnouncementItem(
                    title: 'Quarterly Review Deadline',
                    subtitle: 'Submit reviews by March 25, 2026',
                    icon: Icons.assessment,
                  ),
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (isManagerOrHr ? 880 : 560).ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (isManagerOrHr ? 880 : 560).ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // ── Recent Activity ───────────────────────────────────────────
          Text('Recent Activity', style: theme.textTheme.titleMedium)
              .animate()
              .fadeIn(duration: 400.ms, delay: (isManagerOrHr ? 960 : 640).ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (isManagerOrHr ? 960 : 640).ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          NeuCard(
            child: Column(
              children: [
                _ActivityItem(
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  title: 'Leave Approved',
                  subtitle: 'Casual leave on Mar 5 was approved',
                  time: '2 hours ago',
                ),
                Divider(height: 20, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                _ActivityItem(
                  icon: Icons.login_rounded,
                  color: AppColors.primary,
                  title: 'Punch In',
                  subtitle: 'Punched in at 09:02 AM today',
                  time: '5 hours ago',
                ),
                Divider(height: 20, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                _ActivityItem(
                  icon: Icons.receipt_long,
                  color: AppColors.orange,
                  title: 'Expense Submitted',
                  subtitle: 'Travel reimbursement - ₹34,500',
                  time: 'Yesterday',
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (isManagerOrHr ? 1040 : 720).ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (isManagerOrHr ? 1040 : 720).ms, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // ── HR-specific: Employee Stats & Leave Analytics ─────────────
          if (role == UserRole.hr) ...[
            _HrAnalyticsSection(isDark: isDark),
          ],
        ],
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

// =============================================================================
// MANAGER INSIGHTS SECTION
// =============================================================================
class _ManagerInsightsSection extends StatelessWidget {
  final bool isDark;
  final UserRole role;
  const _ManagerInsightsSection({required this.isDark, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              role == UserRole.hr ? 'HR Insights' : 'Manager Insights',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 400.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),
        const SizedBox(height: 14),

        // Pending Approvals Card
        NeuCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.pastelRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pending_actions_rounded, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Pending Approvals', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: 15),
                      duration: const Duration(milliseconds: 3500),
                      curve: Curves.easeOutExpo,
                      builder: (context, value, _) => Text(
                        '$value',
                        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InsightActionRow(
                label: 'Leave Requests',
                count: '8',
                color: AppColors.warning,
                onTap: () => _navigateToRequested(context),
              ),
              const SizedBox(height: 10),
              _InsightActionRow(
                label: 'Claims',
                count: '4',
                color: AppColors.primary,
                onTap: () => _navigateToRequested(context),
              ),
              const SizedBox(height: 10),
              _InsightActionRow(
                label: 'Shift Changes',
                count: '3',
                color: AppColors.secondary,
                onTap: () => _navigateToRequested(context),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 480.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),
        const SizedBox(height: 16),
      ],
    );
  }

  void _navigateToRequested(BuildContext context) {
    context.read<AppProvider>().navigateToRequested();
  }
}

// =============================================================================
// TEAM ATTENDANCE CARD
// =============================================================================
class _TeamAttendanceCard extends StatelessWidget {
  final bool isDark;
  const _TeamAttendanceCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Team Attendance', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _TeamStatMini(label: 'Present', value: '5', color: AppColors.success, isDark: isDark),
              const SizedBox(width: 10),
              _TeamStatMini(label: 'WFH', value: '1', color: AppColors.primary, isDark: isDark),
              const SizedBox(width: 10),
              _TeamStatMini(label: 'Leave', value: '1', color: AppColors.warning, isDark: isDark),
              const SizedBox(width: 10),
              _TeamStatMini(label: 'Absent', value: '1', color: AppColors.danger, isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.75),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFD0D4DC),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '75% of your team is present today',
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PERFORMANCE SECTION (Manager/HR)
// =============================================================================
class _PerformanceSection extends StatelessWidget {
  final bool isDark;
  final UserRole role;
  const _PerformanceSection({required this.isDark, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeuCard(
          padding: const EdgeInsets.all(20),
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
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Team Performance', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              _PerformanceRow(label: 'On-time Completion', pct: 0.88, pctText: '88%', color: AppColors.success, isDark: isDark),
              const SizedBox(height: 14),
              _PerformanceRow(label: 'Avg. Work Hours', pct: 0.92, pctText: '9.2h', color: AppColors.primary, isDark: isDark),
              const SizedBox(height: 14),
              _PerformanceRow(label: 'Attendance Rate', pct: 0.95, pctText: '95%', color: AppColors.secondary, isDark: isDark),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 800.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 800.ms, curve: Curves.easeOut),
        const SizedBox(height: 16),
      ],
    );
  }
}

// =============================================================================
// HR ANALYTICS SECTION
// =============================================================================
class _HrAnalyticsSection extends StatelessWidget {
  final bool isDark;
  const _HrAnalyticsSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employee Statistics
        Row(
          children: [
            Expanded(child: _HrStatMini(label: 'Total', value: '1,240', color: AppColors.primary, icon: Icons.groups_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _HrStatMini(label: 'Active', value: '1,198', color: AppColors.success, icon: Icons.check_circle_outline)),
            const SizedBox(width: 10),
            Expanded(child: _HrStatMini(label: 'On Leave', value: '42', color: AppColors.warning, icon: Icons.event_busy)),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 1120.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 1120.ms, curve: Curves.easeOut),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _HrStatMini(label: 'New Hires', value: '8', color: AppColors.secondary, icon: Icons.person_add)),
            const SizedBox(width: 10),
            Expanded(child: _HrStatMini(label: 'Exits', value: '3', color: AppColors.danger, icon: Icons.person_remove)),
            const SizedBox(width: 10),
            Expanded(child: _HrStatMini(label: 'Open Roles', value: '12', color: AppColors.orange, icon: Icons.work_outline)),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 1200.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 1200.ms, curve: Curves.easeOut),
        const SizedBox(height: 16),

        // Leave Analytics
        NeuCard(
          padding: const EdgeInsets.all(20),
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
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Leave Utilization', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              _LeaveUtilRow(label: 'Casual Leave', pct: 0.62, pctText: '62%', color: AppColors.primary, isDark: isDark),
              const SizedBox(height: 14),
              _LeaveUtilRow(label: 'Sick Leave', pct: 0.28, pctText: '28%', color: AppColors.orange, isDark: isDark),
              const SizedBox(height: 14),
              _LeaveUtilRow(label: 'Earned Leave', pct: 0.45, pctText: '45%', color: AppColors.success, isDark: isDark),
              const SizedBox(height: 14),
              _LeaveUtilRow(label: 'Comp Off', pct: 0.15, pctText: '15%', color: AppColors.secondary, isDark: isDark),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 1280.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 1280.ms, curve: Curves.easeOut),
        const SizedBox(height: 20),

        // Attendance Trends Chart
        NeuCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.pastelGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Attendance Trends', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()}%',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                            if (value.toInt() >= days.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(days[value.toInt()], style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: [
                      _makeBarGroup(0, 95, AppColors.success),
                      _makeBarGroup(1, 92, AppColors.success),
                      _makeBarGroup(2, 97, AppColors.success),
                      _makeBarGroup(3, 89, AppColors.warning),
                      _makeBarGroup(4, 94, AppColors.success),
                    ],
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 1360.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 1360.ms, curve: Curves.easeOut),
        const SizedBox(height: 20),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: color, width: 28, borderRadius: BorderRadius.circular(6)),
      ],
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _AttendanceTimerCard extends StatefulWidget {
  final AppProvider provider;
  const _AttendanceTimerCard({required this.provider});

  @override
  State<_AttendanceTimerCard> createState() => _AttendanceTimerCardState();
}

class _AttendanceTimerCardState extends State<_AttendanceTimerCard> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPunchedIn = widget.provider.isPunchedIn;
    final punchTime = widget.provider.punchInTime;

    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: StreamBuilder<DateTime>(
        stream: _clockStream,
        builder: (context, snapshot) {
          final now = snapshot.data ?? DateTime.now();
          final worked = isPunchedIn && punchTime != null
              ? now.difference(punchTime)
              : Duration.zero;
          final workedText = _formatDuration(worked);
          // Progress out of 9h target
          final progress = isPunchedIn
              ? (worked.inMinutes / 540).clamp(0.0, 1.0)
              : 0.0;

          return Column(
            children: [
              Text('Attendance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                DateFormat('hh:mm:ss a, dd MMM yyyy').format(now),
                style: theme.textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
              ),
              const SizedBox(height: 24),

              // Circular progress ring
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(isPunchedIn ? AppColors.success : Colors.grey.shade300),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total Hours', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                        const SizedBox(height: 4),
                        Text(
                          workedText,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Production chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Production : $workedText',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),

              // Punch in time
              if (isPunchedIn && punchTime != null)
                Text(
                  'Punch In at ${DateFormat('hh:mm a').format(punchTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              if (!isPunchedIn)
                Text(
                  'Not punched in yet',
                  style: theme.textTheme.bodySmall?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                ),
              const SizedBox(height: 20),

              // Punch button – navigates to Attendance tab
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Attendance tab (index 2)
                    widget.provider.setBottomNavIndex(2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPunchedIn ? AppColors.danger : AppColors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    isPunchedIn ? 'Punch Out' : 'Punch In',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeaveTypeChip extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final Color color;
  final bool isDark;
  const _LeaveTypeChip({required this.label, required this.used, required this.total, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: remaining),
              duration: const Duration(milliseconds: 3500),
              curve: Curves.easeOutExpo,
              builder: (context, value, _) => Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: used / total),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value, minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('$used/$total used', style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _AnnouncementItem({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(title), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 1)),
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
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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
  const _ActivityItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label action opened'), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 1)),
        );
      },
      child: NeuCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// Manager Insight Action Row - tappable to navigate to Requested page
class _InsightActionRow extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final VoidCallback onTap;
  const _InsightActionRow({required this.label, required this.count, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkText : AppColors.lightText))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        ],
      ),
    );
  }
}

class _TeamStatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _TeamStatMini({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.15 : 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final double pct;
  final String pctText;
  final Color color;
  final bool isDark;
  const _PerformanceRow({required this.label, required this.pct, required this.pctText, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText))),
            Text(pctText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value, minHeight: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFD0D4DC),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _HrStatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _HrStatMini({required this.label, required this.value, required this.color, required this.icon});

  int get _numericValue => int.tryParse(value.replaceAll(',', '')) ?? 0;
  String _formatValue(int v) {
    if (v >= 1000) return '${(v ~/ 1000)},${(v % 1000).toString().padLeft(3, '0')}';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NeuCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: _numericValue),
            duration: const Duration(milliseconds: 3500),
            curve: Curves.easeOutExpo,
            builder: (context, val, _) => Text(_formatValue(val), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LeaveUtilRow extends StatelessWidget {
  final String label;
  final double pct;
  final String pctText;
  final Color color;
  final bool isDark;
  const _LeaveUtilRow({required this.label, required this.pct, required this.pctText, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText))),
            Text(pctText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value, minHeight: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFD0D4DC),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
