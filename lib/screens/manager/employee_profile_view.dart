import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class EmployeeProfileView extends StatelessWidget {
  final String name;
  final String initials;
  final Color avatarColor;
  final String jobTitle;
  final String department;

  const EmployeeProfileView({
    super.key,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.jobTitle,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _ProfileHeader(
              name: name,
              initials: initials,
              avatarColor: avatarColor,
              jobTitle: jobTitle,
              department: department,
            ),
            const SizedBox(height: 20),

            // Attendance Summary
            _AttendanceSummarySection(),
            const SizedBox(height: 16),

            // Leave History
            _LeaveHistorySection(),
            const SizedBox(height: 16),

            // Performance Notes
            _PerformanceNotesSection(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Header
// ---------------------------------------------------------------------------
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String initials;
  final Color avatarColor;
  final String jobTitle;
  final String department;

  const _ProfileHeader({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.jobTitle,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: avatarColor.withValues(alpha: 0.15),
            child: Text(
              initials,
              style: TextStyle(
                color: avatarColor,
                fontWeight: FontWeight.w700,
                fontSize: 26,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(jobTitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileInfoChip(
                icon: Icons.business,
                label: department,
                color: AppColors.primary,
              ),
              _ProfileInfoChip(
                icon: Icons.email_outlined,
                label: '${name.split(' ').first.toLowerCase()}@ppulse.com',
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProfileInfoChip(
                icon: Icons.phone_outlined,
                label: '+91 98765 43210',
                color: AppColors.success,
              ),
              _ProfileInfoChip(
                icon: Icons.badge_outlined,
                label: 'EMP-2024-${name.hashCode.abs() % 900 + 100}',
                color: AppColors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance Summary Section
// ---------------------------------------------------------------------------
class _AttendanceSummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pastelBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Attendance Summary', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _StatTile(
                    label: 'Present', value: '21', color: AppColors.success),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                    label: 'Absent', value: '2', color: AppColors.danger),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                    label: 'Late', value: '3', color: AppColors.warning),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                    label: 'Leave', value: '1', color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Attendance percentage bar
          Row(
            children: [
              Text('Attendance Rate', style: theme.textTheme.bodySmall),
              const Spacer(),
              Text(
                '91%',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.91,
              minHeight: 8,
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leave History Section
// ---------------------------------------------------------------------------
class _LeaveRecord {
  final String type;
  final String dateRange;
  final String status;
  final String reason;

  const _LeaveRecord({
    required this.type,
    required this.dateRange,
    required this.status,
    required this.reason,
  });
}

const _sampleLeaveHistory = [
  _LeaveRecord(
    type: 'Sick Leave',
    dateRange: 'Feb 20 - Feb 21, 2026',
    status: 'Approved',
    reason: 'Flu and fever',
  ),
  _LeaveRecord(
    type: 'Casual Leave',
    dateRange: 'Jan 15, 2026',
    status: 'Approved',
    reason: 'Personal work',
  ),
  _LeaveRecord(
    type: 'Privilege Leave',
    dateRange: 'Dec 24 - Dec 26, 2025',
    status: 'Approved',
    reason: 'Holiday travel',
  ),
  _LeaveRecord(
    type: 'Casual Leave',
    dateRange: 'Nov 10, 2025',
    status: 'Rejected',
    reason: 'Project deadline conflict',
  ),
];

class _LeaveHistorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pastelPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_note,
                    color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Leave History', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_sampleLeaveHistory.length, (index) {
            final record = _sampleLeaveHistory[index];
            return Column(
              children: [
                if (index > 0) const Divider(height: 16),
                _LeaveRow(record: record),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LeaveRow extends StatelessWidget {
  final _LeaveRecord record;
  const _LeaveRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.type,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(record.dateRange, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(record.reason,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        record.status == 'Approved'
            ? StatusChip.approved()
            : StatusChip.rejected(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Performance Notes Section
// ---------------------------------------------------------------------------
class _PerformanceNote {
  final String title;
  final String note;
  final String date;
  final String author;

  const _PerformanceNote({
    required this.title,
    required this.note,
    required this.date,
    required this.author,
  });
}

const _samplePerformanceNotes = [
  _PerformanceNote(
    title: 'Q4 2025 Review',
    note:
        'Consistently exceeded sprint targets. Strong collaboration with cross-functional teams. Recommended for senior role consideration.',
    date: 'Jan 5, 2026',
    author: 'James Wilson',
  ),
  _PerformanceNote(
    title: 'Project Milestone',
    note:
        'Successfully delivered the payment integration module ahead of schedule. Code quality and documentation were excellent.',
    date: 'Nov 20, 2025',
    author: 'James Wilson',
  ),
  _PerformanceNote(
    title: 'Training Completion',
    note:
        'Completed advanced Flutter architecture course. Applied learnings effectively in the mobile app refactor.',
    date: 'Oct 8, 2025',
    author: 'HR Department',
  ),
];

class _PerformanceNotesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.pastelGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_border_rounded,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Performance Notes', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_samplePerformanceNotes.length, (index) {
            final note = _samplePerformanceNotes[index];
            return Column(
              children: [
                if (index > 0) const Divider(height: 20),
                _PerformanceNoteRow(note: note),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PerformanceNoteRow extends StatelessWidget {
  final _PerformanceNote note;
  const _PerformanceNoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                note.title,
                style:
                    theme.textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
            ),
            Text(note.date, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          note.note,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              note.author,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
