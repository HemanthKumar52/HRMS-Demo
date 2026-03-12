import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  int _selectedPeriod = 0; // 0 = Week, 1 = Month

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          NeuCard(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _PeriodToggle(
                  label: 'Week',
                  isSelected: _selectedPeriod == 0,
                  onTap: () => setState(() => _selectedPeriod = 0),
                ),
                _PeriodToggle(
                  label: 'Month',
                  isSelected: _selectedPeriod == 1,
                  onTap: () => setState(() => _selectedPeriod = 1),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // Attendance Summary Donut Chart
          Text('Attendance Summary', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const _AttendanceDonutChart().animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),

          // Today's Team List
          Text("Today's Team", style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(_teamMembers.length, (index) {
            final member = _teamMembers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TeamMemberRow(member: member),
            ).animate().fadeIn(duration: 400.ms, delay: (160 + index * 60).ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: (160 + index * 60).ms, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period Toggle Button
// ---------------------------------------------------------------------------
class _PeriodToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
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
  }
}

// ---------------------------------------------------------------------------
// Attendance Donut Chart
// ---------------------------------------------------------------------------
class _AttendanceDonutChart extends StatefulWidget {
  const _AttendanceDonutChart();

  @override
  State<_AttendanceDonutChart> createState() => _AttendanceDonutChartState();
}

class _AttendanceDonutChartState extends State<_AttendanceDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: 18,
                    title: '18',
                    color: AppColors.success,
                    radius: _touchedIndex == 0 ? 55.0 : 45.0,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    value: 3,
                    title: '3',
                    color: AppColors.danger,
                    radius: _touchedIndex == 1 ? 55.0 : 45.0,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    value: 4,
                    title: '4',
                    color: AppColors.warning,
                    radius: _touchedIndex == 2 ? 55.0 : 45.0,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    value: 2,
                    title: '2',
                    color: AppColors.secondary,
                    radius: _touchedIndex == 3 ? 55.0 : 45.0,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _ChartLegend(label: 'Present', color: AppColors.success),
              _ChartLegend(label: 'Absent', color: AppColors.danger),
              _ChartLegend(label: 'Late', color: AppColors.warning),
              _ChartLegend(label: 'Leave', color: AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final String label;
  final Color color;

  const _ChartLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSubtext
                : AppColors.lightSubtext,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Team Member Data & Row
// ---------------------------------------------------------------------------
class _TeamMember {
  final String name;
  final String initials;
  final Color avatarColor;
  final String punchIn;
  final String punchOut;
  final String status; // Present, Absent, Late, Leave

  const _TeamMember({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.punchIn,
    required this.punchOut,
    required this.status,
  });
}

const _teamMembers = [
  _TeamMember(
    name: 'Priya Sharma',
    initials: 'PS',
    avatarColor: AppColors.primary,
    punchIn: '09:02 AM',
    punchOut: '--:--',
    status: 'Present',
  ),
  _TeamMember(
    name: 'Rahul Verma',
    initials: 'RV',
    avatarColor: AppColors.secondary,
    punchIn: '09:35 AM',
    punchOut: '--:--',
    status: 'Late',
  ),
  _TeamMember(
    name: 'Anita Desai',
    initials: 'AD',
    avatarColor: AppColors.orange,
    punchIn: '--:--',
    punchOut: '--:--',
    status: 'Absent',
  ),
  _TeamMember(
    name: 'Karan Mehta',
    initials: 'KM',
    avatarColor: AppColors.success,
    punchIn: '08:55 AM',
    punchOut: '--:--',
    status: 'Present',
  ),
  _TeamMember(
    name: 'Sneha Patel',
    initials: 'SP',
    avatarColor: AppColors.pink,
    punchIn: '--:--',
    punchOut: '--:--',
    status: 'Leave',
  ),
  _TeamMember(
    name: 'Vikram Singh',
    initials: 'VS',
    avatarColor: AppColors.primaryDark,
    punchIn: '09:00 AM',
    punchOut: '--:--',
    status: 'Present',
  ),
  _TeamMember(
    name: 'Neha Gupta',
    initials: 'NG',
    avatarColor: AppColors.danger,
    punchIn: '09:22 AM',
    punchOut: '--:--',
    status: 'Late',
  ),
  _TeamMember(
    name: 'Amit Joshi',
    initials: 'AJ',
    avatarColor: AppColors.warning,
    punchIn: '08:48 AM',
    punchOut: '--:--',
    status: 'Present',
  ),
];

class _TeamMemberRow extends StatelessWidget {
  final _TeamMember member;
  const _TeamMemberRow({required this.member});

  Color _statusColor() {
    switch (member.status) {
      case 'Present':
        return AppColors.success;
      case 'Absent':
        return AppColors.danger;
      case 'Late':
        return AppColors.warning;
      case 'Leave':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon() {
    switch (member.status) {
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Late':
        return Icons.schedule;
      case 'Leave':
        return Icons.event_busy;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeuCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: member.avatarColor.withValues(alpha: 0.15),
            child: Text(
              member.initials,
              style: TextStyle(
                color: member.avatarColor,
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
                Text(member.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.login, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(member.punchIn,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(width: 14),
                    const Icon(Icons.logout, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(member.punchOut,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          StatusChip(
            label: member.status,
            color: _statusColor(),
            icon: _statusIcon(),
          ),
        ],
      ),
    );
  }
}
