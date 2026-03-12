import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../home/face_verification_dialog.dart';

class HrHome extends StatefulWidget {
  const HrHome({super.key});

  @override
  State<HrHome> createState() => _HrHomeState();
}

class _HrHomeState extends State<HrHome> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final myView = provider.isMyView;

    return Column(
      children: [
        // View Toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _buildViewToggle(isDark)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: myView
                ? _buildMyView(theme, isDark)
                : _buildHrDashboard(theme, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle(bool isDark) {
    final provider = context.watch<AppProvider>();
    final isMyView = provider.isMyView;
    return NeuCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setMyView(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isMyView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 18,
                      color: !isMyView
                          ? Colors.white
                          : isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'HR Dashboard',
                      style: TextStyle(
                        color: !isMyView
                            ? Colors.white
                            : isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setMyView(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isMyView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: isMyView
                          ? Colors.white
                          : isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'My View',
                      style: TextStyle(
                        color: isMyView
                            ? Colors.white
                            : isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HR DASHBOARD
  // ===========================================================================
  Widget _buildHrDashboard(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Headcount Stats
          Row(
            children: [
              Expanded(child: _StatMini(label: 'Total', value: '1,240', color: AppColors.primary, icon: Icons.groups_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _StatMini(label: 'Active', value: '1,198', color: AppColors.success, icon: Icons.check_circle_outline)),
              const SizedBox(width: 10),
              Expanded(child: _StatMini(label: 'On Leave', value: '42', color: AppColors.warning, icon: Icons.event_busy)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatMini(label: 'New Hires', value: '8', color: AppColors.secondary, icon: Icons.person_add)),
              const SizedBox(width: 10),
              Expanded(child: _StatMini(label: 'Exits', value: '3', color: AppColors.danger, icon: Icons.person_remove)),
              const SizedBox(width: 10),
              Expanded(child: _StatMini(label: 'Open Roles', value: '12', color: AppColors.orange, icon: Icons.work_outline)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Headcount Trend Chart
          Text('Headcount Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          NeuCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 100,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];
                          if (value.toInt() >= months.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(months[value.toInt()], style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 1100,
                  maxY: 1300,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1180),
                        FlSpot(1, 1195),
                        FlSpot(2, 1200),
                        FlSpot(3, 1210),
                        FlSpot(4, 1220),
                        FlSpot(5, 1232),
                        FlSpot(6, 1240),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(radius: 3, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Leave Utilization
          Text('Leave Utilization', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildLeaveUtilRow('Casual Leave', 0.62, '62%', AppColors.primary, isDark),
                const SizedBox(height: 16),
                _buildLeaveUtilRow('Sick Leave', 0.28, '28%', AppColors.orange, isDark),
                const SizedBox(height: 16),
                _buildLeaveUtilRow('Earned Leave', 0.45, '45%', AppColors.success, isDark),
                const SizedBox(height: 16),
                _buildLeaveUtilRow('Comp Off', 0.15, '15%', AppColors.secondary, isDark),
                const SizedBox(height: 16),
                _buildLeaveUtilRow('Maternity/Paternity', 0.08, '8%', AppColors.pink, isDark),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 480.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Attendance Trends
          Text('Attendance Trends', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(duration: 400.ms, delay: 560.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 560.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          NeuCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
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
          ).animate().fadeIn(duration: 400.ms, delay: 640.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 640.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Quick Actions
          Text('HR Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(duration: 400.ms, delay: 720.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 720.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _QuickAction(icon: Icons.person_add_rounded, label: 'Onboard', color: AppColors.success),
              _QuickAction(icon: Icons.badge_rounded, label: 'ID Cards', color: AppColors.primary),
              _QuickAction(icon: Icons.policy_rounded, label: 'Policies', color: AppColors.secondary),
              _QuickAction(icon: Icons.assessment_rounded, label: 'Reports', color: AppColors.orange),
              _QuickAction(icon: Icons.email_rounded, label: 'Letters', color: AppColors.pink),
              _QuickAction(icon: Icons.gavel_rounded, label: 'Compliance', color: AppColors.warning),
              _QuickAction(icon: Icons.calendar_today_rounded, label: 'Holidays', color: AppColors.primaryDark),
              _QuickAction(icon: Icons.settings_rounded, label: 'Settings', color: AppColors.danger),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 800.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 800.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildLeaveUtilRow(String label, double pct, String pctText, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
            ),
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
              value: value,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFD0D4DC),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MY VIEW - Personal employee view
  // ===========================================================================
  Widget _buildMyView(ThemeData theme, bool isDark) {
    final provider = context.watch<AppProvider>();
    final isPunchedIn = provider.isPunchedIn;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getGreeting()},',
            style: theme.textTheme.bodyMedium,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 2),
          Text(
            provider.userName.split(' ').first,
            style: theme.textTheme.headlineLarge,
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // Punch Card
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPunchedIn ? AppColors.pastelGreen : AppColors.pastelRed,
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
                        Text('My Attendance', style: theme.textTheme.titleMedium),
                        Text(DateFormat('EEEE, MMM d').format(DateTime.now()), style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPunchedIn ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPunchedIn ? 'Active' : 'Inactive',
                        style: TextStyle(color: isPunchedIn ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isPunchedIn && provider.punchInTime != null) ...[
                  Text(
                    DateFormat('hh:mm a').format(provider.punchInTime!),
                    style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('Punched in at', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!isPunchedIn) {
                        showDialog(context: context, builder: (_) => const FaceVerificationDialog());
                      } else {
                        provider.togglePunch();
                      }
                    },
                    icon: Icon(isPunchedIn ? Icons.logout : Icons.login),
                    label: Text(isPunchedIn ? 'Punch Out' : 'Punch In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPunchedIn ? AppColors.danger : AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.pastelBlue, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('Leave Balance', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: 16),
                        duration: const Duration(milliseconds: 3500),
                        curve: Curves.easeOutExpo,
                        builder: (context, value, _) => Text('$value', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                        decoration: BoxDecoration(color: AppColors.pastelGreen, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.trending_up, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('Attendance', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: 99),
                        duration: const Duration(milliseconds: 3500),
                        curve: Curves.easeOutExpo,
                        builder: (context, value, _) => Text('$value%', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.success)),
                      ),
                      Text('This month', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // Payslip
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.pastelGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Latest Payslip', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Feb 2026', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net Pay', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('₹72,000', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.success)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Gross', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('₹1,05,000', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),
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

// ---------------------------------------------------------------------------
// Stat Mini Card
// ---------------------------------------------------------------------------
class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatMini({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  int get _numericValue => int.tryParse(value.replaceAll(',', '')) ?? 0;

  String _formatValue(int v) {
    if (v >= 1000) {
      return '${(v ~/ 1000)},${(v % 1000).toString().padLeft(3, '0')}';
    }
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

// ---------------------------------------------------------------------------
// Quick Action
// ---------------------------------------------------------------------------
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
          SnackBar(
            content: Text('$label action opened'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: NeuCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
