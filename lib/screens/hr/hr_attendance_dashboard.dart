import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

class HrAttendanceDashboard extends StatefulWidget {
  const HrAttendanceDashboard({super.key});

  @override
  State<HrAttendanceDashboard> createState() => _HrAttendanceDashboardState();
}

class _HrAttendanceDashboardState extends State<HrAttendanceDashboard> {
  String _selectedFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Today', 'This Week', 'This Month', 'Custom'].map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E8EE)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !isSelected
                            ? null
                            : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), offset: const Offset(0, 3), blurRadius: 8)],
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // Overall Attendance Summary
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Present', value: '1,180', pct: '95.2%', color: AppColors.success, icon: Icons.check_circle)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(label: 'Absent', value: '18', pct: '1.5%', color: AppColors.danger, icon: Icons.cancel)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Late', value: '32', pct: '2.6%', color: AppColors.warning, icon: Icons.schedule)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(label: 'WFH', value: '10', pct: '0.8%', color: AppColors.primary, icon: Icons.home_work)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Department-wise Attendance
          Text('Department-wise Attendance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _DeptAttendanceRow(dept: 'Engineering', present: 456, total: 480, color: AppColors.primary, isDark: isDark),
                const SizedBox(height: 16),
                _DeptAttendanceRow(dept: 'Design', present: 246, total: 280, color: AppColors.secondary, isDark: isDark),
                const SizedBox(height: 16),
                _DeptAttendanceRow(dept: 'Marketing', present: 184, total: 200, color: AppColors.success, isDark: isDark),
                const SizedBox(height: 16),
                _DeptAttendanceRow(dept: 'HR', present: 178, total: 180, color: AppColors.orange, isDark: isDark),
                const SizedBox(height: 16),
                _DeptAttendanceRow(dept: 'Finance', present: 95, total: 100, color: AppColors.pink, isDark: isDark),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Weekly Attendance Heatmap
          Text('Weekly Attendance Rate', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),
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
                        return BarTooltipItem('${rod.toY.toInt()}%', const TextStyle(color: Colors.white, fontWeight: FontWeight.w600));
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
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
                    _makeBarGroup(0, 95.2, AppColors.success),
                    _makeBarGroup(1, 92.8, AppColors.success),
                    _makeBarGroup(2, 97.1, AppColors.success),
                    _makeBarGroup(3, 89.5, AppColors.warning),
                    _makeBarGroup(4, 94.3, AppColors.success),
                    _makeBarGroup(5, 45.0, AppColors.primary),
                  ],
                ),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 480.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Attendance Anomalies
          Text('Attendance Anomalies', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              .animate().fadeIn(duration: 400.ms, delay: 560.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 560.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          ..._buildAnomalies(theme, isDark),
          const SizedBox(height: 24),

          // Bulk Actions
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bulk Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BulkActionBtn(icon: Icons.download, label: 'Export Report', color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BulkActionBtn(icon: Icons.email, label: 'Send Reminders', color: AppColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BulkActionBtn(icon: Icons.edit_note, label: 'Regularize', color: AppColors.success),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BulkActionBtn(icon: Icons.print, label: 'Print Summary', color: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 720.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 720.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: color, width: 22, borderRadius: BorderRadius.circular(6)),
      ],
    );
  }

  List<Widget> _buildAnomalies(ThemeData theme, bool isDark) {
    final anomalies = [
      {'name': 'Ravi Menon', 'issue': 'Late 4 times this week', 'dept': 'Engineering', 'icon': Icons.schedule, 'color': AppColors.warning},
      {'name': 'Kavita Das', 'issue': 'Absent without notice (2 days)', 'dept': 'Design', 'icon': Icons.person_off_outlined, 'color': AppColors.danger},
      {'name': 'Sunil Reddy', 'issue': 'Consecutive late check-ins since Mon', 'dept': 'Engineering', 'icon': Icons.trending_down_rounded, 'color': AppColors.orange},
      {'name': 'Pooja Iyer', 'issue': 'Missing punch-out 3 times', 'dept': 'Marketing', 'icon': Icons.warning_amber_rounded, 'color': AppColors.warning},
    ];

    return anomalies.asMap().entries.map((entry) {
      final i = entry.key;
      final a = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: NeuCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (a['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? AppColors.darkText : AppColors.lightText)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(a['dept'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(a['issue'] as String, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 20),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: (640 + i * 60).ms).slideY(begin: 0.06, end: 0, duration: 400.ms, delay: (640 + i * 60).ms, curve: Curves.easeOut),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Summary Card
// ---------------------------------------------------------------------------
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String pct;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.pct,
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
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                const SizedBox(height: 2),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _numericValue),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) => Text(_formatValue(val), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                ),
              ],
            ),
          ),
          Text(pct, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Department Attendance Row
// ---------------------------------------------------------------------------
class _DeptAttendanceRow extends StatelessWidget {
  final String dept;
  final int present;
  final int total;
  final Color color;
  final bool isDark;

  const _DeptAttendanceRow({
    required this.dept,
    required this.present,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = present / total;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(dept, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText))),
            Text('$present/$total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 8),
            Text('${(pct * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
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
}

// ---------------------------------------------------------------------------
// Bulk Action Button
// ---------------------------------------------------------------------------
class _BulkActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BulkActionBtn({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label initiated'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
