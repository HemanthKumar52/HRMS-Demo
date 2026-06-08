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
import '../timesheet/timesheet_screen.dart';
import '../../utils/responsive.dart';
import '../../widgets/neu_card.dart';

import '../../widgets/ios_screen_wrapper.dart';
import '../../widgets/native_ios_attendance_view.dart';
import '../../widgets/native_ios_views.dart';

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

  // Day status (mirrors the web): 0=none/weekend/upcoming,
  // 1=Work From Office, 2=On Break/Not Working (absent), 3=On Leave,
  // 4=Holiday, 5=Work From Home.
  final Map<int, int> _dayStatuses = {};
  // Day-of-month -> holiday name (for the holiday tap/notification).
  final Map<int, String> _holidayNames = {};
  List<Map<String, dynamic>> _dailyLog = [];
  bool _isLoading = true;
  int _logPage = 0;
  static const int _logPageSize = 5;

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
    setState(() {
      _isLoading = true;
      _logPage = 0;
    });
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

      // Build day statuses from real data, matching the web's status set.
      _dayStatuses.clear();
      _holidayNames.clear();
      for (var d in daily) {
        final dateStr = d['date'] as String;
        final day = int.parse(dateStr.split('-').last);
        final status = d['status'] as String;
        final workType = (d['work_type'] ?? '').toString().toLowerCase();
        switch (status) {
          case 'present':
            // Distinguish Work From Home vs Work From Office (default).
            _dayStatuses[day] = workType.contains('home') ? 5 : 1;
            break;
          case 'absent':
            _dayStatuses[day] = 2; // On Break / Not Working
            break;
          case 'leave':
            _dayStatuses[day] = 3; // On Leave
            break;
          case 'holiday':
            _dayStatuses[day] = 4;
            final name = (d['holiday_name'] ?? '').toString();
            if (name.isNotEmpty) _holidayNames[day] = name;
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
        return AppColors.success; // Work From Office (green)
      case 2:
        return Colors.grey; // On Break / Not Working (grey)
      case 3:
        return AppColors.danger; // On Leave (red)
      case 4:
        return AppColors.secondary; // Holiday (violet)
      case 5:
        return AppColors.primary; // Work From Home (blue)
      default:
        return Colors.transparent;
    }
  }

  // ---- Monthly Attendance bar-chart axis helpers ---------------------------
  // A "nice" rounded top so the chart has a clearly defined ceiling.
  double get _chartMaxY {
    final raw = [_workingDaysCount, _absentCount, _leaveCount]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    if (raw <= 5) return 5;
    return (raw / 5).ceil() * 5.0;
  }

  // Gridline / label spacing that keeps ~5 divisions regardless of scale.
  double get _chartStep {
    final maxY = _chartMaxY;
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    return 5;
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
    final currentStatus = isPunchedIn ? 'Checked In' : 'Not Checked In';

    if (shouldUseNativeIOS) {
      return IOSScreenWrapper(
        iosViewType: NativeViewTypes.attendance,
        iosParams: {
          'isPunchedIn': isPunchedIn,
          'punchInTime': punchInTime,
          'punchOutTime': punchOutTime,
          'currentStatus': currentStatus,
          'workingDays': _workingDaysCount,
          'absentDays': _absentCount,
          'leaveDays': _leaveCount,
          'holidays': _holidayCount,
          'currentMonth': DateFormat('MMMM yyyy').format(_currentMonth),
          'weeklyHours': _weeklyHours,
          'dailyLog': _dailyLog.take(10).toList(),
        },
        onNavigate: (screen, args) {
          switch (screen) {
            case 'previousMonth':
              _goToPreviousMonth();
              break;
            case 'nextMonth':
              _goToNextMonth();
              break;
            case 'refresh':
              _loadAttendanceData();
              break;
          }
        },
        dartChild: _buildDartScaffold(
          context,
          tt,
          isDark,
          provider,
          isPunchedIn,
          punchTime,
          punchInTime,
          punchOutTime,
          currentStatus,
        ),
      );
    }

    return _buildDartScaffold(
      context,
      tt,
      isDark,
      provider,
      isPunchedIn,
      punchTime,
      punchInTime,
      punchOutTime,
      currentStatus,
    );
  }

  Widget _buildDartScaffold(
    BuildContext context,
    TextTheme tt,
    bool isDark,
    AppProvider provider,
    bool isPunchedIn,
    DateTime? punchTime,
    String punchInTime,
    String punchOutTime,
    String currentStatus,
  ) {
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
                  child: ResponsiveCenter(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Attendance Carousel (Clock In + Working Hours + Break Hours) ---
                        _AttendanceCarousel(
                              provider: provider,
                              todayLog: _dailyLog.isNotEmpty
                                  ? _dailyLog.first
                                  : null,
                            )
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
                                  const SizedBox(height: 18),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildPunchItem(
                                          icon: Icons.login_rounded,
                                          label: 'Check In',
                                          value: punchInTime,
                                          color: AppColors.success,
                                          tt: tt,
                                          isDark: isDark,
                                        ),
                                        _punchDivider(isDark),
                                        _buildPunchItem(
                                          icon: Icons.logout_rounded,
                                          label: 'Check Out',
                                          value: punchOutTime,
                                          color: AppColors.danger,
                                          tt: tt,
                                          isDark: isDark,
                                        ),
                                        _punchDivider(isDark),
                                        _buildPunchItem(
                                          icon: Icons.timer_outlined,
                                          label: 'Total Hours',
                                          value:
                                              isPunchedIn && punchTime != null
                                              ? _formatDuration(
                                                  DateTime.now().difference(
                                                    punchTime,
                                                  ),
                                                )
                                              : '0h 00m',
                                          color: AppColors.secondary,
                                          tt: tt,
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
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

                        // --- Timesheet entry (moved here from dashboard) ---
                        NeuCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TimesheetScreen(),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isApplePlatform
                                      ? CupertinoIcons.time
                                      : Icons.timer_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Timesheet',
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Log and review your weekly hours',
                                      style: tt.bodySmall?.copyWith(
                                        color: isDark
                                            ? AppColors.darkSubtext
                                            : AppColors.lightSubtext,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.25),
                              ),
                            ],
                          ),
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
                                        Icons.radar_rounded,
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
                                      _legendDot(
                                        AppColors.warning,
                                        'Min Hours',
                                      ),
                                      const SizedBox(width: 12),
                                      _legendDot(AppColors.primary, 'Overtime'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 250,
                                    child: Builder(
                                      builder: (_) {
                                        const days = [
                                          'Mon',
                                          'Tue',
                                          'Wed',
                                          'Thu',
                                          'Fri',
                                        ];
                                        final worked = _weeklyHours;
                                        final gridColor = isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.10,
                                              );
                                        return RadarChart(
                                          RadarChartData(
                                            radarShape: RadarShape.polygon,
                                            dataSets: [
                                              // Worked hours (green filled)
                                              RadarDataSet(
                                                dataEntries: [
                                                  for (int i = 0; i < 5; i++)
                                                    RadarEntry(
                                                      value: worked[i],
                                                    ),
                                                ],
                                                fillColor: AppColors.success
                                                    .withValues(alpha: 0.18),
                                                borderColor: AppColors.success,
                                                borderWidth: 2.5,
                                                entryRadius: 3,
                                              ),
                                              // Min hours reference (orange)
                                              RadarDataSet(
                                                dataEntries: const [
                                                  RadarEntry(value: 8),
                                                  RadarEntry(value: 8),
                                                  RadarEntry(value: 8),
                                                  RadarEntry(value: 8),
                                                  RadarEntry(value: 8),
                                                ],
                                                fillColor: Colors.transparent,
                                                borderColor: AppColors.warning,
                                                borderWidth: 1.5,
                                                entryRadius: 0,
                                              ),
                                              // Overtime (blue overlay)
                                              RadarDataSet(
                                                dataEntries: [
                                                  for (int i = 0; i < 5; i++)
                                                    RadarEntry(
                                                      value: (worked[i] - 8)
                                                          .clamp(0.0, 24.0),
                                                    ),
                                                ],
                                                fillColor: AppColors.primary
                                                    .withValues(alpha: 0.10),
                                                borderColor: AppColors.primary,
                                                borderWidth: 1.5,
                                                entryRadius: 2,
                                              ),
                                            ],
                                            radarBackgroundColor:
                                                Colors.transparent,
                                            radarBorderData: BorderSide(
                                              color: gridColor,
                                              width: 1,
                                            ),
                                            gridBorderData: BorderSide(
                                              color: gridColor,
                                              width: 1,
                                            ),
                                            tickBorderData: BorderSide(
                                              color: gridColor,
                                              width: 0.5,
                                            ),
                                            tickCount: 4,
                                            ticksTextStyle: TextStyle(
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                              fontSize: 9,
                                            ),
                                            titlePositionPercentageOffset: 0.13,
                                            getTitle: (index, angle) =>
                                                RadarChartTitle(
                                                  text: index < days.length
                                                      ? days[index]
                                                      : '',
                                                ),
                                            titleTextStyle: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                            radarTouchData: RadarTouchData(
                                              enabled: false,
                                            ),
                                          ),
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          curve: Curves.easeOutCubic,
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
                                        AppColors.warning.withValues(
                                          alpha: 0.5,
                                        ),
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
                                                      getTooltipItems:
                                                          (spots) => spots.map((
                                                            s,
                                                          ) {
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
                                                                    ? Colors
                                                                          .white
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
                                                                  FontWeight
                                                                      .w600,
                                                              color: isDark
                                                                  ? Colors
                                                                        .white54
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
                                                              style: tt.bodySmall?.copyWith(
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
                                                                  FontWeight
                                                                      .w600,
                                                              color: isDark
                                                                  ? Colors
                                                                        .white54
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
                                                              style: tt
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    fontSize:
                                                                        10,
                                                                    color:
                                                                        isDark
                                                                        ? Colors
                                                                              .white70
                                                                        : Colors
                                                                              .black87,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
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
                                                    rightTitles:
                                                        const AxisTitles(
                                                          sideTitles:
                                                              SideTitles(
                                                                showTitles:
                                                                    false,
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
                                                                      alpha:
                                                                          0.08,
                                                                    )
                                                              : Colors.grey
                                                                    .withValues(
                                                                      alpha:
                                                                          0.15,
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
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
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
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2.5,
                                                              strokeColor:
                                                                  AppColors
                                                                      .primary,
                                                            ),
                                                      ),
                                                      belowBarData: BarAreaData(
                                                        show: true,
                                                        gradient:
                                                            LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                AppColors
                                                                    .primary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.25,
                                                                    ),
                                                                AppColors
                                                                    .primary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.02,
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
                                  SizedBox(
                                    height: 240,
                                    child: BarChart(
                                      BarChartData(
                                        alignment:
                                            BarChartAlignment.spaceAround,
                                        minY: 0,
                                        maxY: _chartMaxY,
                                        barTouchData: BarTouchData(
                                          enabled: false,
                                          touchTooltipData:
                                              BarTouchTooltipData(
                                                getTooltipColor: (_) =>
                                                    Colors.transparent,
                                                tooltipPadding:
                                                    EdgeInsets.zero,
                                                tooltipMargin: 2,
                                                getTooltipItem:
                                                    (group, gi, rod, ri) =>
                                                        BarTooltipItem(
                                                          rod.toY
                                                              .toInt()
                                                              .toString(),
                                                          TextStyle(
                                                            color: rod.color,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                              ),
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
                                            axisNameSize: 18,
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                              interval: _chartStep,
                                              getTitlesWidget: (value, meta) {
                                                // Label every gridline, incl. 0 and the top.
                                                if (value % _chartStep != 0) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 6,
                                                      ),
                                                  child: Text(
                                                    '${value.toInt()}',
                                                    style: tt.bodySmall
                                                        ?.copyWith(
                                                          fontSize: 10,
                                                          color: isDark
                                                              ? Colors.white54
                                                              : Colors
                                                                    .grey
                                                                    .shade600,
                                                        ),
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
                                          horizontalInterval: _chartStep,
                                          getDrawingHorizontalLine: (value) =>
                                              FlLine(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.08,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.07,
                                                      ),
                                                strokeWidth: 1,
                                              ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border(
                                            left: BorderSide(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.18,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.18,
                                                    ),
                                              width: 1,
                                            ),
                                            bottom: BorderSide(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.18,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.18,
                                                    ),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        barGroups: [
                                          BarChartGroupData(
                                            x: 0,
                                            showingTooltipIndicators: [0],
                                            barRods: [
                                              BarChartRodData(
                                                toY: _workingDaysCount
                                                    .toDouble(),
                                                width: 26,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(5),
                                                    ),
                                                color: AppColors.success,
                                                backDrawRodData:
                                                    BackgroundBarChartRodData(
                                                      show: true,
                                                      toY: _chartMaxY,
                                                      color: isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.04,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.03,
                                                                ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                          BarChartGroupData(
                                            x: 1,
                                            showingTooltipIndicators: [0],
                                            barRods: [
                                              BarChartRodData(
                                                toY: _absentCount.toDouble(),
                                                width: 26,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(5),
                                                    ),
                                                color: AppColors.danger,
                                                backDrawRodData:
                                                    BackgroundBarChartRodData(
                                                      show: true,
                                                      toY: _chartMaxY,
                                                      color: isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.04,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.03,
                                                                ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                          BarChartGroupData(
                                            x: 2,
                                            showingTooltipIndicators: [0],
                                            barRods: [
                                              BarChartRodData(
                                                toY: _leaveCount.toDouble(),
                                                width: 26,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(5),
                                                    ),
                                                color: AppColors.orange,
                                                backDrawRodData:
                                                    BackgroundBarChartRodData(
                                                      show: true,
                                                      toY: _chartMaxY,
                                                      color: isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.04,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.03,
                                                                ),
                                                    ),
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

    final totalRows = _dailyLog.length;
    final totalPages = (totalRows / _logPageSize).ceil().clamp(1, 999);
    final start = _logPage * _logPageSize;
    final end = (start + _logPageSize).clamp(0, totalRows);
    final rows = _dailyLog.sublist(start, end);

    return NeuCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder(
                      verticalInside: BorderSide(color: borderColor, width: 1),
                      horizontalInside: BorderSide(
                        color: borderColor,
                        width: 0.5,
                      ),
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
                            'Break',
                            Icons.coffee_outlined,
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
                        final breakTime = d['break_time'] as String? ?? '00:00';
                        final minHour = d['min_hour'] as String? ?? '00:00';
                        final overtime = d['overtime'] as String? ?? '00:00';

                        String fmtDate = dateStr;
                        try {
                          fmtDate = DateFormat(
                            'dd MMM yyyy',
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
                            _tableCell(breakTime, cellStyle),
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
                // Pagination controls
                if (totalRows > _logPageSize)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${start + 1}–$end of $totalRows',
                          style: cellStyle.copyWith(fontSize: 12),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                size: 22,
                              ),
                              onPressed: _logPage > 0
                                  ? () => setState(() => _logPage--)
                                  : null,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                              ),
                              onPressed: end < totalRows
                                  ? () => setState(() => _logPage++)
                                  : null,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
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
      child: Text(text, style: style, overflow: TextOverflow.ellipsis),
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
            shape: BoxShape.circle,
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
        color: badgeColor.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.45),
          width: 0.8,
        ),
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
              boxShadow: isCheckedIn
                  ? [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
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

  /// Thin vertical separator between punch items.
  Widget _punchDivider(bool isDark) => Container(
    width: 1,
    height: 46,
    color: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07),
  );

  Widget _buildPunchItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required TextTheme tt,
    required bool isDark,
  }) {
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final isPlaceholder = value == '--:--' || value == '0h 00m';
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
              color: subtext,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isPlaceholder ? subtext : text,
            ),
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
                          // Clock In dot
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
                          // Clock Out dot
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
                final holidayName = isCurrentMonth
                    ? _holidayNames[date.day]
                    : null;

                return Expanded(
                  child: GestureDetector(
                    onTap: holidayName != null
                        ? () => _showHolidayInfo(date, holidayName)
                        : null,
                    child: _DayCell(
                      day: date.day,
                      isCurrentMonth: isCurrentMonth,
                      isToday: isToday,
                      statusColor: status > 0 ? _statusColor(status) : null,
                      isDark: isDark,
                      textStyle: tt.bodyMedium,
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
      ('Work From Office', AppColors.success),
      ('Work From Home', AppColors.primary),
      ('On Leave', AppColors.danger),
      ('Holiday', AppColors.secondary),
      ('Not Working', Colors.grey),
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
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(item.$1, style: tt.bodySmall),
          ],
        );
      }).toList(),
    );
  }

  /// Show the holiday name (set by admin on the web) for a tapped calendar day.
  void _showHolidayInfo(DateTime date, String name) {
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(date);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Holiday · $dateStr',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ATTENDANCE CAROUSEL — 3 swipable cards with page indicator
// =============================================================================
class _AttendanceCarousel extends StatefulWidget {
  final AppProvider provider;
  final Map<String, dynamic>? todayLog;
  const _AttendanceCarousel({required this.provider, this.todayLog});

  @override
  State<_AttendanceCarousel> createState() => _AttendanceCarouselState();
}

class _AttendanceCarouselState extends State<_AttendanceCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScroll;

  @override
  void initState() {
    super.initState();
    // The carousel should only auto-rotate while the user is in an active work
    // session (checked in via mobile, or clocked in via web/biometric — all of
    // which surface as provider.isPunchedIn). When they're not clocked in, it
    // stays put instead of sliding "aside" on its own. Listen for check-in/out
    // so the rotation starts/stops live.
    widget.provider.addListener(_syncAutoScroll);
    _syncAutoScroll();
  }

  /// Start the 7s auto-rotate only when clocked in; stop it otherwise.
  /// Idempotent — safe to call repeatedly from the provider listener.
  void _syncAutoScroll() {
    if (!mounted) return;
    final shouldRun = widget.provider.isPunchedIn;
    if (shouldRun && _autoScroll == null) {
      _autoScroll = Timer.periodic(const Duration(seconds: 7), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % 3;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    } else if (!shouldRun && _autoScroll != null) {
      _autoScroll!.cancel();
      _autoScroll = null;
    }
  }

  @override
  void dispose() {
    widget.provider.removeListener(_syncAutoScroll);
    _autoScroll?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 356,
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _ClockInCard(provider: widget.provider),
              _WorkingHoursCard(
                provider: widget.provider,
                todayLog: widget.todayLog,
              ),
              _BreakHoursCard(
                provider: widget.provider,
                todayLog: widget.todayLog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.primary
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.shade300),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// =============================================================================
// CARD 2: WORKING HOURS (synced from DB)
// =============================================================================
class _WorkingHoursCard extends StatelessWidget {
  final AppProvider provider;
  final Map<String, dynamic>? todayLog;
  const _WorkingHoursCard({required this.provider, this.todayLog});

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

    // Try to get total_hours from DB log
    final dbHours = todayLog?['total_hours'] as String?;

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        String workedText;
        double progress;

        if (isPunchedIn && punchTime != null) {
          final worked = now.difference(punchTime);
          workedText = _formatDuration(worked);
          progress = (worked.inMinutes / 540).clamp(0.0, 1.0); // 9h target
        } else if (dbHours != null && dbHours.isNotEmpty) {
          workedText = dbHours;
          // Parse HH:MM:SS
          final parts = dbHours.split(':');
          final h = int.tryParse(parts[0]) ?? 0;
          final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          progress = ((h * 60 + m) / 540).clamp(0.0, 1.0);
        } else {
          workedText = '0h 00m';
          progress = 0.0;
        }

        return NeuCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _CardIconBadge(
                icon: Icons.work_history_rounded,
                color: AppColors.success,
              ),
              const SizedBox(height: 14),
              Text('Working Hours', style: _cardTitleStyle(isDark)),
              const SizedBox(height: 12),
              _DurationText(
                text: workedText,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              const SizedBox(height: 20),
              _CardProgress(
                progress: progress,
                color: AppColors.success,
                isDark: isDark,
                caption: 'of 9h target',
              ),
              const SizedBox(height: 18),
              _StatFooter(
                isDark: isDark,
                left: _MiniStat(
                  label: 'Check In',
                  value: isPunchedIn && punchTime != null
                      ? DateFormat('hh:mm a').format(punchTime)
                      : '--:--',
                  color: AppColors.success,
                  isDark: isDark,
                ),
                right: _MiniStat(
                  label: 'Target',
                  value: '9h 00m',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// CARD 3: BREAK HOURS (synced from DB)
// =============================================================================
class _BreakHoursCard extends StatelessWidget {
  final AppProvider provider;
  final Map<String, dynamic>? todayLog;
  const _BreakHoursCard({required this.provider, this.todayLog});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get break time from DB
    final dbBreak = todayLog?['break_time'] as String?;
    String breakText = '0h 00m';
    double breakMinutes = 0;

    if (dbBreak != null && dbBreak.isNotEmpty && dbBreak != '00:00') {
      final parts = dbBreak.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      breakText = '${h}h ${m.toString().padLeft(2, '0')}m';
      breakMinutes = (h * 60 + m).toDouble();
    }

    final allowedBreak = 60.0; // 1h allowed
    final progress = (breakMinutes / allowedBreak).clamp(0.0, 1.0);
    final isOverBreak = breakMinutes > allowedBreak;

    return NeuCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _CardIconBadge(
            icon: Icons.coffee_rounded,
            color: AppColors.orange,
          ),
          const SizedBox(height: 14),
          Text('Break Hours', style: _cardTitleStyle(isDark)),
          const SizedBox(height: 12),
          _DurationText(
            text: breakText,
            color: isOverBreak
                ? AppColors.danger
                : (isDark ? AppColors.darkText : AppColors.lightText),
          ),
          const SizedBox(height: 20),
          _CardProgress(
            progress: progress,
            color: isOverBreak ? AppColors.danger : AppColors.orange,
            isDark: isDark,
            caption: isOverBreak
                ? 'Exceeded allowed break time'
                : 'of ${allowedBreak.toInt()}m allowed',
            captionColor: isOverBreak ? AppColors.danger : null,
          ),
          const SizedBox(height: 18),
          _StatFooter(
            isDark: isDark,
            left: _MiniStat(
              label: 'Used',
              value: breakText,
              color: AppColors.orange,
              isDark: isDark,
            ),
            right: _MiniStat(
              label: 'Allowed',
              value: '1h 00m',
              color: AppColors.primary,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Shared section title used by the Working/Break Hours cards.
TextStyle _cardTitleStyle(bool isDark) => TextStyle(
  fontSize: 13,
  letterSpacing: 0.4,
  fontWeight: FontWeight.w600,
  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
);

/// Gradient circular icon with a soft outer glow — the header of each card.
class _CardIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CardIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 27),
    );
  }
}

/// Big duration like "0h 00m" with large bold digits and smaller dimmed units.
class _DurationText extends StatelessWidget {
  final String text;
  final Color color;
  const _DurationText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final letter = RegExp(r'[a-zA-Z]');
    final spans = <TextSpan>[
      for (final ch in text.split(''))
        TextSpan(
          text: ch,
          style: TextStyle(
            fontSize: letter.hasMatch(ch) ? 22 : 46,
            fontWeight: letter.hasMatch(ch)
                ? FontWeight.w700
                : FontWeight.w900,
            color: letter.hasMatch(ch) ? color.withValues(alpha: 0.5) : color,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),
    ];
    return RichText(text: TextSpan(children: spans));
  }
}

/// Rounded progress bar with a trailing percentage chip and a caption below.
class _CardProgress extends StatelessWidget {
  final double progress;
  final Color color;
  final bool isDark;
  final String caption;
  final Color? captionColor;
  const _CardProgress({
    required this.progress,
    required this.color,
    required this.isDark,
    required this.caption,
    this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: captionColor ??
                  (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two MiniStats inside a soft container split by a vertical divider.
class _StatFooter extends StatelessWidget {
  final Widget left;
  final Widget right;
  final bool isDark;
  const _StatFooter({
    required this.left,
    required this.right,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: left),
          Container(
            width: 1,
            height: 32,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
          Expanded(child: right),
        ],
      ),
    );
  }
}

// =============================================================================
// CARD 1: CLOCK IN/OUT (original)
// =============================================================================
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
                isPunchedIn ? 'Working' : 'Not Checked In',
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
                        'Use device to check out',
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
                          isPunchedIn ? 'CHECK OUT' : 'CHECK IN',
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
              // Clock-in time info (only shown once punched in).
              if (isPunchedIn && punchTime != null) ...[
                const SizedBox(height: 20),
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
                        'Clocked in at ${DateFormat('hh:mm a').format(punchTime!)}',
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
