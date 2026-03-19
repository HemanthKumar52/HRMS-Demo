import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../home/face_verification_dialog.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _touchedBarIndex = -1;
  late DateTime _currentMonth;
  late DateTime _today;

  final int _workingDaysCount = 18;
  final int _absentCount = 2;
  final int _leaveCount = 1;
  final int _holidayCount = 2;

  // Weekly hours data (Mon-Fri only)
  final List<double> _weeklyHours = [8.5, 9.0, 7.5, 8.0, 8.5];

  // Monthly week-wise attendance data
  final List<_WeekData> _monthlyData = [
    _WeekData(week: 'W1', present: 5, absent: 0, leave: 0),
    _WeekData(week: 'W2', present: 4, absent: 1, leave: 0),
    _WeekData(week: 'W3', present: 4, absent: 0, leave: 1),
    _WeekData(week: 'W4', present: 5, absent: 1, leave: 0),
  ];

  // Punch time data for the week (Mon-Fri only)
  final List<_PunchData> _punchData = [
    _PunchData(day: 'Mon', punchIn: 9.0, punchOut: 17.5),
    _PunchData(day: 'Tue', punchIn: 8.5, punchOut: 18.0),
    _PunchData(day: 'Wed', punchIn: 9.2, punchOut: 16.7),
    _PunchData(day: 'Thu', punchIn: 9.0, punchOut: 17.0),
    _PunchData(day: 'Fri', punchIn: 8.8, punchOut: 17.3),
  ];

  // Day status: 0=none, 1=working, 2=absent, 3=leave, 4=holiday
  final Map<int, int> _dayStatuses = {};

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _currentMonth = DateTime(_today.year, _today.month);
    _generateMockStatuses();
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _generateMockStatuses();
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _generateMockStatuses();
    });
  }

  void _generateMockStatuses() {
    _dayStatuses.clear();
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final weekday = date.weekday;
      if (weekday == 6 || weekday == 7) continue; // skip weekends entirely
      if (day == 5 || day == 19) {
        _dayStatuses[day] = 4; // holiday
      } else if (day == 12) {
        _dayStatuses[day] = 3; // leave
      } else if (day == 8 || day == 22) {
        _dayStatuses[day] = 2; // absent
      } else if (date.isBefore(_today) || date.isAtSameMomentAs(_today)) {
        _dayStatuses[day] = 1; // working
      } else {
        _dayStatuses[day] = 0; // future
      }
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.danger;
      case 3:
        return AppColors.orange;
      case 4:
        return AppColors.primary;
      default:
        return Colors.transparent;
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final isPunchedIn = provider.isPunchedIn;
    final punchTime = provider.punchInTime;

    // Derive punch status strings from provider
    final punchInTime = isPunchedIn && punchTime != null
        ? DateFormat('hh:mm a').format(punchTime)
        : '--:--';
    final punchOutTime = '--:--';
    final currentStatus = isPunchedIn ? 'Checked In' : 'Not Clocked In';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Clock In Card ---
            _ClockInCard(provider: provider)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Today Punch Status ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Today\'s Punch Status', style: tt.titleLarge),
                      const Spacer(),
                      _buildStatusBadge(currentStatus, isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildPunchItem(
                        icon: Icons.login_rounded,
                        label: 'Punch In',
                        value: punchInTime,
                        color: AppColors.success,
                        tt: tt,
                      ),
                      const SizedBox(width: 16),
                      _buildPunchItem(
                        icon: Icons.logout_rounded,
                        label: 'Punch Out',
                        value: punchOutTime,
                        color: AppColors.danger,
                        tt: tt,
                      ),
                      const SizedBox(width: 16),
                      _buildPunchItem(
                        icon: Icons.timer_outlined,
                        label: 'Total Hours',
                        value: isPunchedIn && punchTime != null
                            ? _formatDuration(DateTime.now().difference(punchTime))
                            : '0h 00m',
                        color: AppColors.secondary,
                        tt: tt,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Calendar Grid (with month navigation that controls everything) ---
            NeuCard(
              child: Column(
                children: [
                  // Month navigation arrows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _goToPreviousMonth,
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMonthView(tt, isDark),
                  const SizedBox(height: 16),
                  _buildLegend(tt),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Summary ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart_rounded,
                          color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text('Summary', style: tt.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSummaryItem(
                        label: 'Working',
                        count: _workingDaysCount,
                        color: AppColors.success,
                        bgColor: AppColors.pastelGreen,
                        tt: tt,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryItem(
                        label: 'Absent',
                        count: _absentCount,
                        color: AppColors.danger,
                        bgColor: AppColors.pastelRed,
                        tt: tt,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryItem(
                        label: 'Leave',
                        count: _leaveCount,
                        color: AppColors.orange,
                        bgColor: AppColors.pastelOrange,
                        tt: tt,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryItem(
                        label: 'Holiday',
                        count: _holidayCount,
                        color: AppColors.primary,
                        bgColor: AppColors.pastelBlue,
                        tt: tt,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Working Hours Bar Chart ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Working Hours', style: tt.titleMedium),
                      const Spacer(),
                      Text(DateFormat('MMM yyyy').format(_currentMonth), style: tt.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchCallback: (FlTouchEvent event, barTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                _touchedBarIndex = -1;
                                return;
                              }
                              _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                            });
                          },
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => isDark
                                ? AppColors.darkCard
                                : Colors.white,
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                              return BarTooltipItem(
                                '${days[group.x]}\n${rod.toY.toStringAsFixed(1)}h',
                                TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['M', 'T', 'W', 'T', 'F'];
                                if (value.toInt() >= days.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    days[value.toInt()],
                                    style: tt.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}h',
                                  style: tt.bodySmall?.copyWith(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(5, (i) {
                          final hours = _weeklyHours[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: hours,
                                width: _touchedBarIndex == i ? 26.0 : 20.0,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                                color: hours > 0
                                    ? (hours >= 8
                                        ? AppColors.success
                                        : AppColors.warning)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ],
                          );
                        }),
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Daily Work Time Logs (Timeline Range) ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text('Daily Work Time Logs', style: tt.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _legendDot(AppColors.primary, 'Work Period'),
                      const SizedBox(width: 12),
                      _legendDot(AppColors.success, 'Punch In'),
                      const SizedBox(width: 12),
                      _legendDot(AppColors.danger, 'Punch Out'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._punchData.map((data) => _buildTimelineRow(data, tt, isDark)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Monthly Attendance Bar Chart ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Monthly Attendance', style: tt.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _legendDot(AppColors.success, 'Working'),
                      const SizedBox(width: 12),
                      _legendDot(AppColors.danger, 'Absent'),
                      const SizedBox(width: 12),
                      _legendDot(AppColors.orange, 'Leave'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 6,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= _monthlyData.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _monthlyData[value.toInt()].week,
                                    style: tt.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                );
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: tt.bodySmall?.copyWith(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(_monthlyData.length, (i) {
                          final data = _monthlyData[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: data.present.toDouble(),
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                                color: AppColors.success,
                              ),
                              BarChartRodData(
                                toY: data.absent.toDouble(),
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                                color: AppColors.danger,
                              ),
                              BarChartRodData(
                                toY: data.leave.toDouble(),
                                width: 16,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                                color: AppColors.orange,
                              ),
                            ],
                          );
                        }),
                      ),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 480.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final isCheckedIn = status == 'Checked In';
    final badgeColor = isCheckedIn ? AppColors.success : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required TextTheme tt,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: tt.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required TextTheme tt,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.12) : bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: count),
              duration: const Duration(milliseconds: 3500),
              curve: Curves.easeOutExpo,
              builder: (context, value, _) => Text(
                '$value',
                style: tt.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  Widget _buildTimelineRow(_PunchData data, TextTheme tt, bool isDark) {
    // Timeline spans 7AM (7.0) to 8PM (20.0) = 13 hours
    const minHour = 7.0;
    const maxHour = 20.0;
    const range = maxHour - minHour;

    final startFraction = ((data.punchIn - minHour) / range).clamp(0.0, 1.0);
    final endFraction = ((data.punchOut - minHour) / range).clamp(0.0, 1.0);
    final workedHours = data.punchOut - data.punchIn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Day label
          SizedBox(
            width: 36,
            child: Text(
              data.day,
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          // Timeline bar
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final barLeft = startFraction * totalWidth;
                final barWidth = (endFraction - startFraction) * totalWidth;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Stack(
                        children: [
                          // Background track
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          // Work range bar
                          Positioned(
                            left: barLeft,
                            top: 2,
                            bottom: 2,
                            width: barWidth.clamp(4.0, totalWidth),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B5FE5), Color(0xFF5B7FF9)],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              alignment: Alignment.center,
                              child: barWidth > 50
                                  ? Text(
                                      '${workedHours.toStringAsFixed(1)}h',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          // Punch In dot
                          Positioned(
                            left: barLeft - 5,
                            top: 9,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                          // Punch Out dot
                          Positioned(
                            left: barLeft + barWidth - 5,
                            top: 9,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Time labels
                    Row(
                      children: [
                        SizedBox(
                          width: barLeft,
                        ),
                        Text(
                          _formatHour(data.punchIn),
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatHour(data.punchOut),
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(TextTheme tt, bool isDark) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    const dayLabels = ['M', 'T', 'W', 'T', 'F'];

    // Build weeks with weekdays only (Mon-Fri)
    List<List<int?>> weeks = [];
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // Find the Monday of the first week
    final firstMonday = firstDay.subtract(Duration(days: (firstDay.weekday - 1)));

    DateTime currentMonday = firstMonday;
    while (true) {
      List<int?> week = [];
      bool hasAnyDay = false;
      for (int i = 0; i < 5; i++) {
        final date = currentMonday.add(Duration(days: i));
        if (date.month == _currentMonth.month && date.year == _currentMonth.year) {
          week.add(date.day);
          hasAnyDay = true;
        } else {
          week.add(null);
        }
      }
      if (hasAnyDay) {
        weeks.add(week);
      }
      currentMonday = currentMonday.add(const Duration(days: 7));
      // Stop if we've passed the last day of the month
      if (currentMonday.month != _currentMonth.month &&
          currentMonday.isAfter(DateTime(_currentMonth.year, _currentMonth.month, daysInMonth))) {
        break;
      }
    }

    return Column(
      children: [
        Row(
          children: dayLabels
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: tt.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ...weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(5, (col) {
                final dayIndex = week[col];
                if (dayIndex == null) {
                  return const Expanded(child: SizedBox(height: 38));
                }

                final status = _dayStatuses[dayIndex] ?? 0;
                final color = _statusColor(status);
                final isToday = dayIndex == _today.day &&
                    _currentMonth.month == _today.month &&
                    _currentMonth.year == _today.year;

                return Expanded(
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: status > 0
                          ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayIndex',
                      style: tt.bodySmall?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: status > 0 ? color : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegend(TextTheme tt) {
    final items = [
      ('Working Days', AppColors.success),
      ('Absent', AppColors.danger),
      ('Leave', AppColors.orange),
      ('Holiday', AppColors.primary),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.$2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(item.$1, style: tt.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}

class _ClockInCard extends StatelessWidget {
  final AppProvider provider;
  const _ClockInCard({required this.provider});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPunchedIn = provider.isPunchedIn;
    final punchTime = provider.punchInTime;

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final worked = isPunchedIn && punchTime != null
            ? now.difference(punchTime)
            : Duration.zero;
        final workedText = _formatDuration(worked);

        return NeuCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            children: [
              // Total hours display
              Text(
                isPunchedIn ? workedText : '9h 30m',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPunchedIn ? 'Working' : 'Not Clocked In',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Clock In / Clock Out button
              GestureDetector(
                onTap: () {
                  if (!isPunchedIn) {
                    showDialog(context: context, builder: (_) => const FaceVerificationDialog());
                  } else {
                    provider.togglePunch();
                  }
                },
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isPunchedIn
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2A8F7D), Color(0xFF1B5E50)],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPunchedIn ? const Color(0xFFE53935) : const Color(0xFF2A8F7D))
                            .withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPunchedIn ? Icons.logout_rounded : Icons.login_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPunchedIn ? 'CLOCK OUT' : 'CLOCK IN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Synced info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.more_horiz, size: 18, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  const SizedBox(width: 6),
                  Text(
                    isPunchedIn
                        ? 'Clocked in at ${DateFormat('hh:mm a').format(punchTime!)}'
                        : 'Synced with Password',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekData {
  final String week;
  final int present;
  final int absent;
  final int leave;

  const _WeekData({
    required this.week,
    required this.present,
    required this.absent,
    required this.leave,
  });
}

class _PunchData {
  final String day;
  final double punchIn;
  final double punchOut;

  const _PunchData({
    required this.day,
    required this.punchIn,
    required this.punchOut,
  });
}
