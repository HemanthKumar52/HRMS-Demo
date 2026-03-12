import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedPeriod = 0; // 0 = Week, 1 = Month
  int _touchedBarIndex = -1;
  late DateTime _currentMonth;
  late DateTime _today;

  // Mock data
  final String _punchInTime = '09:02 AM';
  final String _punchOutTime = '--:--';
  final String _totalHours = '4h 32m';
  final String _currentStatus = 'Checked In';

  final int _presentCount = 18;
  final int _absentCount = 2;
  final int _leaveCount = 1;
  final int _holidayCount = 2;

  // Weekly hours data (Mon-Sun)
  final List<double> _weeklyHours = [8.5, 9.0, 7.5, 8.0, 8.5, 0, 0];

  // Monthly week-wise attendance data
  final List<_WeekData> _monthlyData = [
    _WeekData(week: 'W1', present: 5, absent: 0, leave: 0),
    _WeekData(week: 'W2', present: 4, absent: 1, leave: 0),
    _WeekData(week: 'W3', present: 4, absent: 0, leave: 1),
    _WeekData(week: 'W4', present: 5, absent: 1, leave: 0),
  ];

  // Punch time data for the week
  final List<_PunchData> _punchData = [
    _PunchData(day: 'Mon', punchIn: 9.0, punchOut: 17.5),
    _PunchData(day: 'Tue', punchIn: 8.5, punchOut: 18.0),
    _PunchData(day: 'Wed', punchIn: 9.2, punchOut: 16.7),
    _PunchData(day: 'Thu', punchIn: 9.0, punchOut: 17.0),
    _PunchData(day: 'Fri', punchIn: 8.8, punchOut: 17.3),
    _PunchData(day: 'Sat', punchIn: 0, punchOut: 0),
    _PunchData(day: 'Sun', punchIn: 0, punchOut: 0),
  ];

  // Day status: 0=none, 1=present, 2=absent, 3=leave, 4=holiday, 5=weekend
  final Map<int, int> _dayStatuses = {};

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _currentMonth = DateTime(_today.year, _today.month);
    _generateMockStatuses();
  }

  void _generateMockStatuses() {
    _dayStatuses.clear();
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final weekday = date.weekday;
      if (weekday == 6 || weekday == 7) {
        _dayStatuses[day] = 5;
      } else if (day == 5 || day == 19) {
        _dayStatuses[day] = 4;
      } else if (day == 12) {
        _dayStatuses[day] = 3;
      } else if (day == 8 || day == 22) {
        _dayStatuses[day] = 2;
      } else if (date.isBefore(_today) || date.isAtSameMomentAs(_today)) {
        _dayStatuses[day] = 1;
      } else {
        _dayStatuses[day] = 0;
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
      case 5:
        return Colors.grey.shade400;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      _buildStatusBadge(_currentStatus, isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildPunchItem(
                        icon: Icons.login_rounded,
                        label: 'Punch In',
                        value: _punchInTime,
                        color: AppColors.success,
                        tt: tt,
                      ),
                      const SizedBox(width: 16),
                      _buildPunchItem(
                        icon: Icons.logout_rounded,
                        label: 'Punch Out',
                        value: _punchOutTime,
                        color: AppColors.danger,
                        tt: tt,
                      ),
                      const SizedBox(width: 16),
                      _buildPunchItem(
                        icon: Icons.timer_outlined,
                        label: 'Total Hours',
                        value: _totalHours,
                        color: AppColors.secondary,
                        tt: tt,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (0 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (0 * 80).ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Period Selector ---
            NeuCard(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Week',
                      selected: _selectedPeriod == 0,
                      onTap: () => setState(() => _selectedPeriod = 0),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleButton(
                      label: 'Month',
                      selected: _selectedPeriod == 1,
                      onTap: () => setState(() => _selectedPeriod = 1),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (1 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (1 * 80).ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // --- Statistics Charts ---
            if (_selectedPeriod == 0) ...[
              // Weekly Hours Bar Chart
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
                        Text('This Week', style: tt.bodySmall),
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
                                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
                                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
                          barGroups: List.generate(7, (i) {
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
              ).animate().fadeIn(duration: 400.ms, delay: (2 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (2 * 80).ms, curve: Curves.easeOut),
              const SizedBox(height: 16),

              // Punch In/Out Times Chart
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text('Punch Times', style: tt.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _legendDot(AppColors.success, 'Punch In'),
                        const SizedBox(width: 16),
                        _legendDot(AppColors.danger, 'Punch Out'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 20,
                          minY: 6,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => isDark
                                  ? AppColors.darkCard
                                  : Colors.white,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final hour = rod.toY;
                                final h = hour.floor();
                                final m = ((hour - h) * 60).round();
                                final period = h >= 12 ? 'PM' : 'AM';
                                final displayH = h > 12 ? h - 12 : h;
                                return BarTooltipItem(
                                  '$displayH:${m.toString().padLeft(2, '0')} $period',
                                  TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
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
                                  final data = _punchData[value.toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(data.day,
                                        style: tt.bodySmall
                                            ?.copyWith(fontWeight: FontWeight.w600)),
                                  );
                                },
                                reservedSize: 28,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                interval: 3,
                                getTitlesWidget: (value, meta) {
                                  final h = value.toInt();
                                  final period = h >= 12 ? 'PM' : 'AM';
                                  final displayH = h > 12 ? h - 12 : h;
                                  return Text(
                                    '$displayH$period',
                                    style: tt.bodySmall?.copyWith(fontSize: 9),
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
                            horizontalInterval: 3,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(_punchData.length, (i) {
                            final data = _punchData[i];
                            if (data.punchIn == 0) {
                              return BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: 6,
                                  width: 8,
                                  color: Colors.transparent,
                                ),
                              ]);
                            }
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: data.punchIn,
                                  fromY: 6,
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                  color: AppColors.success,
                                ),
                                BarChartRodData(
                                  toY: data.punchOut,
                                  fromY: 6,
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                  color: AppColors.danger,
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
              ).animate().fadeIn(duration: 400.ms, delay: (3 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (3 * 80).ms, curve: Curves.easeOut),
            ] else ...[
              // Monthly Attendance Bar Chart
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
                        _legendDot(AppColors.success, 'Present'),
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
              ).animate().fadeIn(duration: 400.ms, delay: (2 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (2 * 80).ms, curve: Curves.easeOut),
              const SizedBox(height: 16),

              // Monthly Attendance Summary numbers
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
                          label: 'Present',
                          count: _presentCount,
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
              ).animate().fadeIn(duration: 400.ms, delay: (3 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (3 * 80).ms, curve: Curves.easeOut),
            ],

            const SizedBox(height: 16),

            // --- Calendar Grid ---
            NeuCard(
              child: Column(
                children: [
                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                                _currentMonth.year, _currentMonth.month - 1);
                            _generateMockStatuses();
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: tt.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(
                                _currentMonth.year, _currentMonth.month + 1);
                            _generateMockStatuses();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMonthView(tt, isDark),
                  const SizedBox(height: 16),
                  // Legend
                  _buildLegend(tt),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (4 * 80).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (4 * 80).ms, curve: Curves.easeOut),

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              color: AppColors.success,
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
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
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

  Widget _buildToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? Colors.white60 : Colors.grey.shade700),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthView(TextTheme tt, bool isDark) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final offset = firstWeekday - 1;
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
        ...List.generate(
          ((offset + daysInMonth) / 7).ceil(),
          (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (col) {
                  final dayIndex = week * 7 + col - offset + 1;
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
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
          },
        ),
      ],
    );
  }

  Widget _buildLegend(TextTheme tt) {
    final items = [
      ('Present', AppColors.success),
      ('Absent', AppColors.danger),
      ('Leave', AppColors.orange),
      ('Holiday', AppColors.primary),
      ('Weekend', Colors.grey.shade400),
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
