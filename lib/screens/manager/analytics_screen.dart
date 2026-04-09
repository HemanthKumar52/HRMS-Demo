import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/styled_donut_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0 = Week, 1 = Month, 2 = Quarter
  bool _isLoading = true;

  // Data from API
  List<Map<String, dynamic>> _departments = [];
  int _totalEmployees = 0;
  int _newJoiners = 0;
  double _attritionRate = 0;
  String _mostUsedLeaveType = '';
  double _avgLeavesPerEmployee = 0;

  // Chart colors
  static const _chartColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.orange,
    AppColors.pink,
    AppColors.warning,
    AppColors.neonPurple,
    Color(0xFF00BCD4),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await ApiService.getDashboardAnalytics();
      if (!mounted) return;
      final deptBreakdown = (data['department_breakdown'] as List?) ?? [];
      final leaveAnalytics = data['leave_analytics'] as Map<String, dynamic>? ?? {};

      setState(() {
        _departments = deptBreakdown
            .map<Map<String, dynamic>>((d) => Map<String, dynamic>.from(d))
            .toList();
        _totalEmployees = (data['total_employees'] ?? 0) as int;
        _newJoiners = (data['new_joiners'] ?? 0) as int;
        _attritionRate = ((data['attrition_rate'] ?? 0) as num).toDouble();
        _mostUsedLeaveType = leaveAnalytics['most_used_type']?.toString() ?? 'N/A';
        _avgLeavesPerEmployee = ((leaveAnalytics['avg_leaves_per_employee'] ?? 0) as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Analytics',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              _buildPeriodSelector(isDark)
                  .animate()
                  .fadeIn(duration: 420.ms)
                  .slideY(begin: 0.12, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 20),

              // Headcount Overview
              Text('Headcount Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 80.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 80.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),
              _buildHeadcountChart(isDark)
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 160.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 160.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),

              // Attendance Trend
              Text('Attendance Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 240.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 240.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),
              _buildAttendanceTrendChart(isDark)
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 320.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 320.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),

              // Department Distribution
              Text('Department Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 400.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 400.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),
              _buildDepartmentPieChart(isDark)
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 480.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 480.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 24),

              // Key Metrics
              Text('Key Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 560.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 560.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 12),
              _buildKeyMetrics(theme, isDark)
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 640.ms)
                  .slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 640.ms, curve: Curves.easeOutCubic),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final periods = ['Week', 'Month', 'Quarter'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    periods[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeadcountChart(bool isDark) {
    final totalEmp = _totalEmployees > 0 ? _totalEmployees.toDouble() : 16.0;
    final maxY = (totalEmp * 1.3).ceilToDouble();

    return _buildChartCard(
      isDark: isDark,
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  const titles = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                  if (value.toInt() >= titles.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      titles[value.toInt()],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
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
            _makeBarGroup(0, totalEmp * 0.85),
            _makeBarGroup(1, totalEmp * 0.90),
            _makeBarGroup(2, totalEmp * 0.93),
            _makeBarGroup(3, totalEmp * 0.88),
            _makeBarGroup(4, totalEmp * 0.95),
            _makeBarGroup(5, totalEmp),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF7C8FFF)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 24,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _buildAttendanceTrendChart(bool isDark) {
    return _buildChartCard(
      isDark: isDark,
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[idx],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      ),
                    ),
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
          maxX: 4,
          minY: 85,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 95),
                FlSpot(1, 92),
                FlSpot(2, 97),
                FlSpot(3, 94),
                FlSpot(4, 96),
              ],
              isCurved: true,
              color: AppColors.success,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 5,
                  color: AppColors.success,
                  strokeWidth: 2,
                  strokeColor: isDark ? AppColors.darkCard : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.2),
                    AppColors.success.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  Widget _buildDepartmentPieChart(bool isDark) {
    final hasDepts = _departments.isNotEmpty;
    final totalEmp = _totalEmployees > 0 ? _totalEmployees : 16;

    return _buildChartCard(
      isDark: isDark,
      child: _isLoading
          ? const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()))
          : StyledDonutChart(
              segments: hasDepts
                  ? _departments.asMap().entries.map((entry) {
                      final i = entry.key;
                      final dept = entry.value;
                      final count = ((dept['count'] ?? 0) as num).toDouble();
                      final color = _chartColors[i % _chartColors.length];
                      return DonutSegment(
                        label: dept['department'] as String? ?? 'Unknown',
                        value: count,
                        color: color,
                      );
                    }).toList()
                  : const [
                      DonutSegment(label: 'Engineering', value: 5, color: AppColors.primary),
                      DonutSegment(label: 'Design', value: 3, color: AppColors.secondary),
                      DonutSegment(label: 'Marketing', value: 4, color: AppColors.success),
                      DonutSegment(label: 'HR', value: 2, color: AppColors.orange),
                      DonutSegment(label: 'Finance', value: 3, color: AppColors.pink),
                    ],
              centerLabel: '$totalEmp\nEmployees',
            ),
    );
  }

  Widget _buildChartCard({required bool isDark, Widget? child, double? height}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: height != null ? SizedBox(height: height, child: child) : child,
    );
  }

  Widget _buildKeyMetrics(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(
              title: 'Total Employees',
              value: _isLoading ? '...' : '$_totalEmployees',
              change: '$_newJoiners new',
              changeColor: AppColors.success,
              icon: Icons.people_outline,
              iconColor: AppColors.primary,
              isDark: isDark,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(
              title: 'Attrition Rate',
              value: _isLoading ? '...' : '${_attritionRate.toStringAsFixed(1)}%',
              change: _attritionRate <= 3 ? 'Healthy' : 'High',
              changeColor: _attritionRate <= 3 ? AppColors.success : AppColors.warning,
              icon: Icons.trending_down,
              iconColor: AppColors.success,
              isDark: isDark,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(
              title: 'Top Leave Type',
              value: _isLoading ? '...' : _mostUsedLeaveType,
              change: 'Most used',
              changeColor: AppColors.orange,
              icon: Icons.event_busy_outlined,
              iconColor: AppColors.orange,
              isDark: isDark,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(
              title: 'Avg. Leaves',
              value: _isLoading ? '...' : _avgLeavesPerEmployee.toStringAsFixed(1),
              change: 'Per employee',
              changeColor: AppColors.secondary,
              icon: Icons.analytics_outlined,
              iconColor: AppColors.secondary,
              isDark: isDark,
            )),
          ],
        ),
      ],
    );
  }
}


class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color changeColor;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.changeColor,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkText : AppColors.lightText), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(change, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: changeColor)),
        ],
      ),
    );
  }
}
