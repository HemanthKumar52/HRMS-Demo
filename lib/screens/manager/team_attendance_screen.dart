import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/styled_donut_chart.dart';

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
          ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.12, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 20),

          // Attendance Summary Donut Chart
          Text('Attendance Summary', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const _AttendanceDonutChart().animate().fadeIn(duration: 420.ms, delay: 80.ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: 80.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 24),

          // Today's Team List
          Text("Today's Team", style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(_teamMembers.length, (index) {
            final member = _teamMembers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TeamMemberRow(member: member),
            ).animate().fadeIn(duration: 420.ms, delay: (160 + index * 60).ms).slideY(begin: 0.12, end: 0, duration: 420.ms, delay: (160 + index * 60).ms, curve: Curves.easeOutCubic);
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
class _AttendanceDonutChart extends StatelessWidget {
  const _AttendanceDonutChart();

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      child: StyledDonutChart(
        segments: const [
          DonutSegment(label: 'Present', value: 18, color: AppColors.success),
          DonutSegment(label: 'Absent', value: 3, color: AppColors.danger),
          DonutSegment(label: 'Late', value: 4, color: AppColors.warning),
          DonutSegment(label: 'Leave', value: 2, color: AppColors.secondary),
        ],
        centerLabel: 'Team',
        size: 200,
      ),
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
