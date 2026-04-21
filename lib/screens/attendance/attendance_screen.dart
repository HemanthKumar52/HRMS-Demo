import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../animations/skeleton_loading.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';

import '../../widgets/native_ios_attendance_view.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _touchedBarIndex = -1;
  late DateTime _currentMonth;
  late DateTime _today;

  int _workingDaysCount = 0;
  int _absentCount = 0;
  int _leaveCount = 0;
  int _holidayCount = 0;

  List<double> _weeklyHours = [0, 0, 0, 0, 0];
  List<_PunchData> _punchData = [];

  // Day status: 0=none, 1=working, 2=absent, 3=leave, 4=holiday
  final Map<int, int> _dayStatuses = {};
  List<Map<String, dynamic>> _dailyLog = [];
  bool _isLoading = true;

  bool? _lastPunchedIn;
  Timer? _biometricPoll;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _currentMonth = DateTime(_today.year, _today.month);
    _loadAttendanceData();
    // Poll dashboard summary every 30s so a biometric punch (made on the
    // physical device) is reflected in the app without manual refresh.
    _biometricPoll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<AppProvider>().fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _biometricPoll?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-reload when punch status changes (user punched in/out)
    final isPunchedIn = context.read<AppProvider>().isPunchedIn;
    if (_lastPunchedIn != null && _lastPunchedIn != isPunchedIn) {
      _loadAttendanceData();
    }
    _lastPunchedIn = isPunchedIn;
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadAttendanceData();
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAttendanceSummary(
        month: _currentMonth.month,
        year: _currentMonth.year,
      );

      final summary = data['summary'] ?? {};
      final daily = List<Map<String, dynamic>>.from(data['daily'] ?? []);

      _workingDaysCount = (summary['present'] ?? 0) as int;
      _absentCount = (summary['absent'] ?? 0) as int;
      _leaveCount = (summary['leave'] ?? 0) as int;
      _holidayCount = (summary['holidays'] ?? 0) as int;

      // Store raw daily data for log table (only present days, newest first)
      _dailyLog = daily
          .where((d) => d['status'] == 'present' && d['punch_in'] != null)
          .toList()
          .reversed
          .toList();

      // Build day statuses from real data
      _dayStatuses.clear();
      for (var d in daily) {
        final dateStr = d['date'] as String;
        final day = int.parse(dateStr.split('-').last);
        final status = d['status'] as String;
        switch (status) {
          case 'present':
            _dayStatuses[day] = 1;
            break;
          case 'absent':
            _dayStatuses[day] = 2;
            break;
          case 'leave':
            _dayStatuses[day] = 3;
            break;
          case 'holiday':
            _dayStatuses[day] = 4;
            break;
          case 'weekend':
          case 'upcoming':
          default:
            _dayStatuses[day] = 0;
        }
      }

      // Load weekly data
      try {
        final weekData = await ApiService.getWeeklyAttendance();
        final dailyHours = List<Map<String, dynamic>>.from(
          weekData['daily_hours'] ?? [],
        );
        _weeklyHours = dailyHours.take(5).map((d) {
          final h = ((d['hours'] ?? 0) as num).toDouble();
          return h.clamp(0.0, 24.0); // safety clamp
        }).toList();
        while (_weeklyHours.length < 5) _weeklyHours.add(0);

        _punchData =
            List<Map<String, dynamic>>.from(weekData['punch_times'] ?? [])
                .take(5)
                .map(
                  (d) => _PunchData(
                    day: d['day'] ?? '',
                    punchIn: ((d['punch_in'] ?? 0) as num).toDouble(),
                    punchOut: ((d['punch_out'] ?? 0) as num).toDouble(),
                  ),
                )
                .where(
                  (d) => d.punchIn > 0 || d.punchOut > 0,
                ) // filter empty entries
                .toList();
      } catch (e) {
        debugPrint('Error fetching weekly: $e');
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: RefreshIndicator(
        onRefresh: _loadAttendanceData,
        color: AppColors.primary,
        child: _isLoading
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const SkeletonCard(lines: 4, showCircle: false),
                    const SizedBox(height: 16),
                    const SkeletonCard(lines: 3, showCircle: false),
                    const SizedBox(height: 16),
                    const SkeletonCard(lines: 5, showCircle: false),
                    const SizedBox(height: 16),
                    const SkeletonCard(lines: 3, showCircle: false),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadAttendanceData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: isApplePlatform
                      ? const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        )
                      : const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Clock In Card ---
                      _ClockInCard(provider: provider)
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .slideY(
                            begin: 0.12,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 16),

                      // --- Today Punch Status ---
                      NeuCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.today_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Today\'s Punch Status',
                                        style: tt.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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
                                          ? _formatDuration(
                                              DateTime.now().difference(
                                                punchTime,
                                              ),
                                            )
                                          : '0h 00m',
                                      color: AppColors.secondary,
                                      tt: tt,
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

                      const SizedBox(height: 16),

                      // --- Calendar Grid (with month navigation that controls everything) ---
                      NeuCard(
                            child: Column(
                              children: [
                                // Month navigation arrows
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    isApplePlatform
                                        ? CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: _goToPreviousMonth,
                                            child: const Icon(
                                              CupertinoIcons.chevron_left,
                                              size: 20,
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.chevron_left_rounded,
                                            ),
                                            onPressed: _goToPreviousMonth,
                                          ),
                                    Text(
                                      DateFormat(
                                        'MMMM yyyy',
                                      ).format(_currentMonth),
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    isApplePlatform
                                        ? CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: _goToNextMonth,
                                            child: const Icon(
                                              CupertinoIcons.chevron_right,
                                              size: 20,
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.chevron_right_rounded,
                                            ),
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
                          )
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

                      const SizedBox(height: 16),

                      // --- Summary ---
                      NeuCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.pie_chart_rounded,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
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

                      const SizedBox(height: 16),

                      // --- Working Hours Line Chart ---
                      NeuCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.show_chart_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Working Hours',
                                      style: tt.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat(
                                        'MMM yyyy',
                                      ).format(_currentMonth),
                                      style: tt.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _legendDot(AppColors.success, 'Worked'),
                                    const SizedBox(width: 12),
                                    _legendDot(AppColors.warning, 'Min Hours'),
                                    const SizedBox(width: 12),
                                    _legendDot(AppColors.primary, 'Overtime'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: Builder(
                                    builder: (_) {
                                      // Dynamic maxY: must be at least 10 (above min hours 8)
                                      final maxWorked = _weeklyHours.reduce(
                                        (a, b) => a > b ? a : b,
                                      );
                                      final dynamicMaxY =
                                          ((maxWorked > 8 ? maxWorked : 8) + 2)
                                              .ceilToDouble();
                                      // Dynamic Y interval based on range
                                      final yInterval = dynamicMaxY <= 12
                                          ? 2.0
                                          : 4.0;

                                      return LineChart(
                                        LineChartData(
                                          minX: 0,
                                          maxX: 4,
                                          minY: 0,
                                          maxY: dynamicMaxY,
                                          lineTouchData: LineTouchData(
                                            enabled: true,
                                            touchTooltipData: LineTouchTooltipData(
                                              getTooltipColor: (_) => isDark
                                                  ? AppColors.darkCard
                                                  : Colors.white,
                                              getTooltipItems: (spots) =>
                                                  spots.map((s) {
                                                    const days = [
                                                      'Mon',
                                                      'Tue',
                                                      'Wed',
                                                      'Thu',
                                                      'Fri',
                                                    ];
                                                    final day =
                                                        s.x.toInt() <
                                                            days.length
                                                        ? days[s.x.toInt()]
                                                        : '';
                                                    final label =
                                                        s.barIndex == 0
                                                        ? 'Worked'
                                                        : (s.barIndex == 1
                                                              ? 'Min'
                                                              : 'OT');
                                                    return LineTooltipItem(
                                                      '$day: ${s.y.toStringAsFixed(1)}h ($label)',
                                                      TextStyle(
                                                        color:
                                                            s.bar.color ??
                                                            (isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 11,
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                          titlesData: FlTitlesData(
                                            show: true,
                                            bottomTitles: AxisTitles(
                                              axisNameWidget: Text(
                                                'Day',
                                                style: tt.bodySmall?.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                              axisNameSize: 22,
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                interval: 1,
                                                getTitlesWidget: (value, meta) {
                                                  const days = [
                                                    'Mon',
                                                    'Tue',
                                                    'Wed',
                                                    'Thu',
                                                    'Fri',
                                                  ];
                                                  final idx = value.toInt();
                                                  if (idx < 0 ||
                                                      idx >= days.length ||
                                                      value != idx.toDouble())
                                                    return const SizedBox.shrink();
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8,
                                                        ),
                                                    child: Text(
                                                      days[idx],
                                                      style: tt.bodySmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 11,
                                                            color: isDark
                                                                ? Colors.white70
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                reservedSize: 28,
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              axisNameWidget: Text(
                                                'Hours',
                                                style: tt.bodySmall?.copyWith(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                              axisNameSize: 22,
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 32,
                                                interval: yInterval,
                                                getTitlesWidget: (value, meta) {
                                                  if (value >= meta.max)
                                                    return const SizedBox.shrink();
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 6,
                                                        ),
                                                    child: Text(
                                                      '${value.toInt()}h',
                                                      style: tt.bodySmall
                                                          ?.copyWith(
                                                            fontSize: 10,
                                                            color: isDark
                                                                ? Colors.white70
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            topTitles: const AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: false,
                                              ),
                                            ),
                                            rightTitles: const AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: false,
                                              ),
                                            ),
                                          ),
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            horizontalInterval: yInterval,
                                            getDrawingHorizontalLine: (value) =>
                                                FlLine(
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.08,
                                                        )
                                                      : Colors.grey.withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  strokeWidth: 1,
                                                ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            // Worked hours line (green)
                                            LineChartBarData(
                                              spots: List.generate(
                                                5,
                                                (i) => FlSpot(
                                                  i.toDouble(),
                                                  _weeklyHours[i],
                                                ),
                                              ),
                                              isCurved: true,
                                              curveSmoothness: 0.3,
                                              color: AppColors.success,
                                              barWidth: 3,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(
                                                show: true,
                                                getDotPainter:
                                                    (
                                                      spot,
                                                      percent,
                                                      bar,
                                                      index,
                                                    ) => FlDotCirclePainter(
                                                      radius: 4,
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                      strokeColor:
                                                          AppColors.success,
                                                    ),
                                              ),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    AppColors.success
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    AppColors.success
                                                        .withValues(
                                                          alpha: 0.01,
                                                        ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Min hours reference line (orange dashed)
                                            LineChartBarData(
                                              spots: List.generate(
                                                5,
                                                (i) => FlSpot(i.toDouble(), 8),
                                              ),
                                              isCurved: false,
                                              color: AppColors.warning,
                                              barWidth: 1.5,
                                              dotData: const FlDotData(
                                                show: false,
                                              ),
                                              dashArray: [6, 4],
                                            ),
                                            // Overtime line (primary/blue)
                                            LineChartBarData(
                                              spots: List.generate(5, (i) {
                                                final ot = (_weeklyHours[i] - 8)
                                                    .clamp(0.0, 24.0);
                                                return FlSpot(i.toDouble(), ot);
                                              }),
                                              isCurved: true,
                                              curveSmoothness: 0.3,
                                              color: AppColors.primary,
                                              barWidth: 2,
                                              isStrokeCapRound: true,
                                              dotData: FlDotData(
                                                show: true,
                                                getDotPainter:
                                                    (
                                                      spot,
                                                      percent,
                                                      bar,
                                                      index,
                                                    ) => FlDotCirclePainter(
                                                      radius: 3,
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                      strokeColor:
                                                          AppColors.primary,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        curve: Curves.easeInOutCubic,
                                      );
                                    },
                                  ),
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

                      // --- Daily Work Time Logs (Line Chart) ---
                      NeuCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.show_chart_rounded,
                                      color: AppColors.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Daily Work Time',
                                      style: tt.titleMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      'This Week',
                                      style: tt.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _legendDot(
                                      AppColors.primary,
                                      'Worked Hours',
                                    ),
                                    const SizedBox(width: 12),
                                    _legendDot(
                                      AppColors.warning.withValues(alpha: 0.5),
                                      'Min Hours (8h)',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child:
                                      _punchData.isEmpty &&
                                          _weeklyHours.every((h) => h == 0)
                                      ? Center(
                                          child: Text(
                                            'No work time data this week',
                                            style: tt.bodyMedium?.copyWith(
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                          ),
                                        )
                                      : Builder(
                                          builder: (_) {
                                            final dwMaxWorked = _weeklyHours
                                                .reduce(
                                                  (a, b) => a > b ? a : b,
                                                );
                                            final dwMaxY =
                                                ((dwMaxWorked > 8
                                                            ? dwMaxWorked
                                                            : 8) +
                                                        2)
                                                    .ceilToDouble();
                                            final dwYInterval = dwMaxY <= 12
                                                ? 2.0
                                                : 4.0;
                                            return LineChart(
                                              LineChartData(
                                                minX: 0,
                                                maxX: 4,
                                                minY: 0,
                                                maxY: dwMaxY,
                                                lineTouchData: LineTouchData(
                                                  enabled: true,
                                                  touchTooltipData: LineTouchTooltipData(
                                                    getTooltipColor: (_) =>
                                                        isDark
                                                        ? AppColors.darkCard
                                                        : Colors.white,
                                                    getTooltipItems: (spots) =>
                                                        spots.map((s) {
                                                          const days = [
                                                            'Mon',
                                                            'Tue',
                                                            'Wed',
                                                            'Thu',
                                                            'Fri',
                                                          ];
                                                          final day =
                                                              s.x.toInt() <
                                                                  days.length
                                                              ? days[s.x
                                                                    .toInt()]
                                                              : '';
                                                          return LineTooltipItem(
                                                            '$day\n${s.y.toStringAsFixed(1)}h',
                                                            TextStyle(
                                                              color: isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .black87,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 12,
                                                            ),
                                                          );
                                                        }).toList(),
                                                  ),
                                                ),
                                                titlesData: FlTitlesData(
                                                  show: true,
                                                  bottomTitles: AxisTitles(
                                                    axisNameWidget: Text(
                                                      'Day',
                                                      style: tt.bodySmall
                                                          ?.copyWith(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                      .grey
                                                                      .shade600,
                                                          ),
                                                    ),
                                                    axisNameSize: 22,
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      interval: 1,
                                                      getTitlesWidget: (value, meta) {
                                                        const days = [
                                                          'Mon',
                                                          'Tue',
                                                          'Wed',
                                                          'Thu',
                                                          'Fri',
                                                        ];
                                                        final idx = value
                                                            .toInt();
                                                        if (idx < 0 ||
                                                            idx >=
                                                                days.length ||
                                                            value !=
                                                                idx.toDouble())
                                                          return const SizedBox.shrink();
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8,
                                                              ),
                                                          child: Text(
                                                            days[idx],
                                                            style: tt.bodySmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 11,
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white70
                                                                      : Colors
                                                                            .black87,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      reservedSize: 28,
                                                    ),
                                                  ),
                                                  leftTitles: AxisTitles(
                                                    axisNameWidget: Text(
                                                      'Hours',
                                                      style: tt.bodySmall
                                                          ?.copyWith(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors
                                                                      .grey
                                                                      .shade600,
                                                          ),
                                                    ),
                                                    axisNameSize: 22,
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      reservedSize: 32,
                                                      interval: dwYInterval,
                                                      getTitlesWidget: (value, meta) {
                                                        if (value >= meta.max)
                                                          return const SizedBox.shrink();
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                right: 6,
                                                              ),
                                                          child: Text(
                                                            '${value.toInt()}h',
                                                            style: tt.bodySmall
                                                                ?.copyWith(
                                                                  fontSize: 10,
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white70
                                                                      : Colors
                                                                            .black87,
                                                                ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  topTitles: const AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: false,
                                                    ),
                                                  ),
                                                  rightTitles: const AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: false,
                                                    ),
                                                  ),
                                                ),
                                                gridData: FlGridData(
                                                  show: true,
                                                  drawVerticalLine: false,
                                                  horizontalInterval:
                                                      dwYInterval,
                                                  getDrawingHorizontalLine:
                                                      (value) => FlLine(
                                                        color: isDark
                                                            ? Colors.white
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  )
                                                            : Colors.grey
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                        strokeWidth: 1,
                                                      ),
                                                ),
                                                borderData: FlBorderData(
                                                  show: false,
                                                ),
                                                lineBarsData: [
                                                  // Min hours reference line (8h)
                                                  LineChartBarData(
                                                    spots: List.generate(
                                                      5,
                                                      (i) => FlSpot(
                                                        i.toDouble(),
                                                        8,
                                                      ),
                                                    ),
                                                    isCurved: false,
                                                    color: AppColors.warning
                                                        .withValues(alpha: 0.4),
                                                    barWidth: 1.5,
                                                    dotData: const FlDotData(
                                                      show: false,
                                                    ),
                                                    dashArray: [6, 4],
                                                  ),
                                                  // Actual worked hours
                                                  LineChartBarData(
                                                    spots: List.generate(
                                                      5,
                                                      (i) => FlSpot(
                                                        i.toDouble(),
                                                        _weeklyHours[i],
                                                      ),
                                                    ),
                                                    isCurved: true,
                                                    curveSmoothness: 0.35,
                                                    color: AppColors.primary,
                                                    barWidth: 3,
                                                    isStrokeCapRound: true,
                                                    dotData: FlDotData(
                                                      show: true,
                                                      getDotPainter:
                                                          (
                                                            spot,
                                                            percent,
                                                            bar,
                                                            index,
                                                          ) => FlDotCirclePainter(
                                                            radius: 4,
                                                            color: Colors.white,
                                                            strokeWidth: 2.5,
                                                            strokeColor:
                                                                AppColors
                                                                    .primary,
                                                          ),
                                                    ),
                                                    belowBarData: BarAreaData(
                                                      show: true,
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          AppColors.primary
                                                              .withValues(
                                                                alpha: 0.25,
                                                              ),
                                                          AppColors.primary
                                                              .withValues(
                                                                alpha: 0.02,
                                                              ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              duration: const Duration(
                                                milliseconds: 800,
                                              ),
                                              curve: Curves.easeInOutCubic,
                                            );
                                          },
                                        ),
                                ),
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

                      // --- Monthly Attendance Bar Chart ---
                      NeuCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bar_chart_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Monthly Attendance',
                                      style: tt.titleMedium,
                                    ),
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
                                ClipRect(
                                  child: SizedBox(
                                    height: 200,
                                    child: BarChart(
                                      BarChartData(
                                        alignment:
                                            BarChartAlignment.spaceAround,
                                        maxY: (_workingDaysCount + 2)
                                            .toDouble()
                                            .clamp(5, 30),
                                        barTouchData: BarTouchData(
                                          enabled: true,
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            axisNameWidget: Text(
                                              'Status',
                                              style: tt.bodySmall?.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                            axisNameSize: 22,
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final labels = [
                                                  'Working',
                                                  'Absent',
                                                  'Leave',
                                                ];
                                                if (value.toInt() >=
                                                    labels.length)
                                                  return const SizedBox.shrink();
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8,
                                                      ),
                                                  child: Text(
                                                    labels[value.toInt()],
                                                    style: tt.bodySmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 11,
                                                          color: isDark
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                        ),
                                                  ),
                                                );
                                              },
                                              reservedSize: 28,
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            axisNameWidget: Text(
                                              'Days',
                                              style: tt.bodySmall?.copyWith(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                            axisNameSize: 22,
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 28,
                                              interval: 5,
                                              getTitlesWidget: (value, meta) {
                                                if (value % 5 != 0)
                                                  return const SizedBox.shrink();
                                                return Text(
                                                  '${value.toInt()}',
                                                  style: tt.bodySmall?.copyWith(
                                                    fontSize: 10,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: 1,
                                          getDrawingHorizontalLine: (value) =>
                                              FlLine(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.06,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.06,
                                                      ),
                                                strokeWidth: 1,
                                              ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        barGroups: [
                                          BarChartGroupData(
                                            x: 0,
                                            barRods: [
                                              BarChartRodData(
                                                toY: _workingDaysCount
                                                    .toDouble(),
                                                width: 24,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(4),
                                                    ),
                                                color: AppColors.success,
                                              ),
                                            ],
                                          ),
                                          BarChartGroupData(
                                            x: 1,
                                            barRods: [
                                              BarChartRodData(
                                                toY: _absentCount.toDouble(),
                                                width: 24,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(4),
                                                    ),
                                                color: AppColors.danger,
                                              ),
                                            ],
                                          ),
                                          BarChartGroupData(
                                            x: 2,
                                            barRods: [
                                              BarChartRodData(
                                                toY: _leaveCount.toDouble(),
                                                width: 24,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(4),
                                                    ),
                                                color: AppColors.orange,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                    ),
                                  ),
                                ),
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

                      // ── Attendance Log Table ──
                      const SizedBox(height: 8),
                      Text(
                            'Attendance Log',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          )
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
                      _buildAttendanceLogTable(tt, isDark),

                      const SizedBox(height: 12),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAttendanceLogTable(TextTheme tt, bool isDark) {
    if (_dailyLog.isEmpty) {
      return NeuCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No attendance records this month',
              style: tt.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
          ),
        ),
      );
    }

    final borderColor = isApplePlatform
        ? AdaptiveColors.separator(context)
        : isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.25);
    final headerBg = isApplePlatform
        ? AdaptiveColors.systemFill(context)
        : isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF5F5F5);
    final headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 11,
      color: isDark ? Colors.white : Colors.black87,
    );
    final cellStyle = TextStyle(
      fontSize: 11,
      color: isDark ? Colors.white70 : Colors.black87,
    );

    final rows = _dailyLog.take(15).toList();

    return NeuCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder(
                  verticalInside: BorderSide(color: borderColor, width: 1),
                  horizontalInside: BorderSide(color: borderColor, width: 0.5),
                  top: BorderSide(color: borderColor, width: 0.5),
                  bottom: BorderSide(color: borderColor, width: 0.5),
                  left: BorderSide.none,
                  right: BorderSide.none,
                ),
                defaultColumnWidth: const FixedColumnWidth(90),
                columnWidths: const {
                  0: FixedColumnWidth(100), // Date
                },
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(color: headerBg),
                    children: [
                      _tableHeaderCell(
                        'Date',
                        Icons.calendar_today_outlined,
                        headerStyle,
                      ),
                      _tableHeaderCell(
                        'Check-In',
                        Icons.login_outlined,
                        headerStyle,
                      ),
                      _tableHeaderCell(
                        'Check-Out',
                        Icons.logout_outlined,
                        headerStyle,
                      ),
                      _tableHeaderCell(
                        'At Work',
                        Icons.timer_outlined,
                        headerStyle,
                      ),
                      _tableHeaderCell(
                        'Min Hour',
                        Icons.hourglass_bottom_outlined,
                        headerStyle,
                      ),
                      _tableHeaderCell(
                        'Overtime',
                        Icons.more_time_outlined,
                        headerStyle,
                      ),
                      _tableHeaderCell(
                        'Total',
                        Icons.access_time_filled_outlined,
                        headerStyle,
                      ),
                    ],
                  ),
                  // Data rows
                  ...rows.map((d) {
                    final dateStr = d['date'] as String? ?? '';
                    final punchIn = d['punch_in'] as String? ?? '';
                    final punchOut = d['punch_out'] as String?;
                    final totalHours = d['total_hours'] as String? ?? '';
                    final minHour = d['min_hour'] as String? ?? '00:00';
                    final overtime = d['overtime'] as String? ?? '00:00';

                    String fmtDate = dateStr;
                    try {
                      fmtDate = DateFormat(
                        'dd/MM/yyyy',
                      ).format(DateTime.parse(dateStr));
                    } catch (_) {}

                    String fmtIn = _fmtTime(punchIn);
                    String fmtOut = punchOut != null
                        ? _fmtTime(punchOut)
                        : '--';

                    return TableRow(
                      children: [
                        _tableCell(fmtDate, cellStyle, bold: true),
                        _tableCell(fmtIn, cellStyle),
                        _tableCell(fmtOut, cellStyle),
                        _tableCell(
                          totalHours.isNotEmpty ? totalHours : '-',
                          cellStyle,
                        ),
                        _tableCell(minHour, cellStyle),
                        _tableCell(overtime, cellStyle),
                        _tableCell(
                          totalHours.isNotEmpty ? totalHours : '-',
                          cellStyle,
                          bold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 420.ms, delay: 640.ms)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 420.ms,
          delay: 640.ms,
          curve: Curves.easeOutCubic,
        );
  }

  String _fmtTime(String time) {
    if (time.isEmpty) return '--';
    try {
      final parts = time.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:${m.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return time;
    }
  }

  Widget _tableHeaderCell(String text, IconData icon, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: style.color?.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, TextStyle style, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: bold ? style.copyWith(fontWeight: FontWeight.w600) : style,
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
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
              duration: const Duration(milliseconds: 1500),
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
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
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
                            width: barWidth.clamp(
                              4.0,
                              totalWidth < 4.0 ? 4.0 : totalWidth,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B5FE5),
                                    Color(0xFF5B7FF9),
                                  ],
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
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
    const dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // Monday of the week containing the 1st (weekday: Mon=1..Sun=7)
    final gridStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    // Always render 6 rows × 7 columns = 42 cells for a stable layout.
    final cells = List<DateTime>.generate(
      42,
      (i) => gridStart.add(Duration(days: i)),
    );

    final mutedLabel = isDark ? Colors.white54 : Colors.black45;

    return Column(
      children: [
        Row(
          children: dayLabels
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mutedLabel,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        ...List.generate(6, (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List.generate(7, (col) {
                final date = cells[week * 7 + col];
                final isCurrentMonth = date.month == _currentMonth.month;
                final status = isCurrentMonth
                    ? (_dayStatuses[date.day] ?? 0)
                    : 0;
                final isToday =
                    date.year == _today.year &&
                    date.month == _today.month &&
                    date.day == _today.day;

                return Expanded(
                  child: _DayCell(
                    day: date.day,
                    isCurrentMonth: isCurrentMonth,
                    isToday: isToday,
                    statusColor: status > 0 ? _statusColor(status) : null,
                    isDark: isDark,
                    textStyle: tt.bodyMedium,
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
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
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
                isPunchedIn ? workedText : '0h 00m',
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
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Clock In / Clock Out button OR Biometric badge
              if (provider.isBiometricPunch && isPunchedIn)
                Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fingerprint,
                        color: AppColors.primary,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Biometric Active',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Use device to punch out',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    if (!isPunchedIn) {
                      // Native iOS or Flutter fallback face verification.
                      NativeAttendanceCheckIn.show(context);
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
                          color:
                              (isPunchedIn
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF2A8F7D))
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
                          isPunchedIn
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
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
                  Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isPunchedIn
                          ? 'Clocked in at ${DateFormat('hh:mm a').format(punchTime!)}'
                          : 'Synced with Password',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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

class _DayCell extends StatelessWidget {
  final int day;
  final bool isCurrentMonth;
  final bool isToday;
  final Color? statusColor;
  final bool isDark;
  final TextStyle? textStyle;

  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.statusColor,
    required this.isDark,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Today: solid dark filled chip with white text (matches reference image).
    final todayFill = isDark ? Colors.white : const Color(0xFF1B1B1F);
    final todayText = isDark ? const Color(0xFF1B1B1F) : Colors.white;

    // Idle (in-month) tile: very subtle raised surface.
    final tileFill = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white;
    final tileBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    // Out-of-month days: muted, no surface.
    final outOfMonthText = isDark ? Colors.white24 : Colors.black26;
    final inMonthText = isDark ? Colors.white : const Color(0xFF1B1B1F);

    final BoxDecoration decoration = isToday
        ? BoxDecoration(
            color: todayFill,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: todayFill.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : isCurrentMonth
        ? BoxDecoration(
            color: tileFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tileBorder, width: 1),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          )
        : const BoxDecoration();

    final Color textColor = isToday
        ? todayText
        : isCurrentMonth
        ? inMonthText
        : outOfMonthText;

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: decoration,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$day',
            style: textStyle?.copyWith(
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
          if (statusColor != null && !isToday)
            Positioned(
              bottom: 5,
              child: Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (statusColor != null && isToday)
            Positioned(
              bottom: 5,
              child: Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: todayText.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
