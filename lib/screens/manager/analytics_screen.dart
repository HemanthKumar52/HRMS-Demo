import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0 = Week, 1 = Month, 2 = Quarter

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(isDark)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // Headcount Overview
          Text('Headcount Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(duration: 400.ms, delay: 80.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          _buildHeadcountChart(isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 160.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Attendance Trend
          Text('Attendance Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(duration: 400.ms, delay: 240.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          _buildAttendanceTrendChart(isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 320.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Department Distribution
          Text('Department Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          _buildDepartmentPieChart(isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 480.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Key Metrics
          Text('Key Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(duration: 400.ms, delay: 560.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 560.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          _buildKeyMetrics(theme, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 640.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 640.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final periods = ['Week', 'Month', 'Quarter'];
    return NeuCard(
      padding: const EdgeInsets.all(4),
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
                  borderRadius: BorderRadius.circular(16),
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
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 1400,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                    const titles = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        titles[value.toInt()],
                        style: TextStyle(
                          fontSize: 11,
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
              _makeBarGroup(0, 1180, AppColors.primary),
              _makeBarGroup(1, 1200, AppColors.primary),
              _makeBarGroup(2, 1220, AppColors.primary),
              _makeBarGroup(3, 1210, AppColors.primary),
              _makeBarGroup(4, 1235, AppColors.primary),
              _makeBarGroup(5, 1240, AppColors.primary),
            ],
          ),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        ),
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
          width: 22,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildAttendanceTrendChart(bool isDark) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
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
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                    if (value.toInt() >= days.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[value.toInt()],
                        style: TextStyle(
                          fontSize: 11,
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
                      FlDotCirclePainter(radius: 4, color: AppColors.success, strokeWidth: 2, strokeColor: Colors.white),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.success.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        ),
      ),
    );
  }

  Widget _buildDepartmentPieChart(bool isDark) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: 480,
                    title: '39%',
                    color: AppColors.primary,
                    radius: 45,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: 280,
                    title: '23%',
                    color: AppColors.secondary,
                    radius: 45,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: 200,
                    title: '16%',
                    color: AppColors.success,
                    radius: 45,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: 180,
                    title: '14%',
                    color: AppColors.orange,
                    radius: 45,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: 100,
                    title: '8%',
                    color: AppColors.pink,
                    radius: 45,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _Legend(label: 'Engineering', color: AppColors.primary),
              _Legend(label: 'Design', color: AppColors.secondary),
              _Legend(label: 'Marketing', color: AppColors.success),
              _Legend(label: 'HR', color: AppColors.orange),
              _Legend(label: 'Finance', color: AppColors.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(
              title: 'Avg. Work Hours',
              value: '8.2h',
              change: '+0.3h',
              changeColor: AppColors.success,
              icon: Icons.schedule,
              iconColor: AppColors.primary,
              isDark: isDark,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(
              title: 'Turnover Rate',
              value: '2.1%',
              change: '-0.5%',
              changeColor: AppColors.success,
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
              title: 'Open Positions',
              value: '12',
              change: '3 urgent',
              changeColor: AppColors.warning,
              icon: Icons.work_outline,
              iconColor: AppColors.orange,
              isDark: isDark,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(
              title: 'Satisfaction',
              value: '4.3/5',
              change: '+0.2',
              changeColor: AppColors.success,
              icon: Icons.sentiment_satisfied,
              iconColor: AppColors.secondary,
              isDark: isDark,
            )),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
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
    return NeuCard(
      padding: const EdgeInsets.all(16),
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
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 4),
          Text(change, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: changeColor)),
        ],
      ),
    );
  }
}
