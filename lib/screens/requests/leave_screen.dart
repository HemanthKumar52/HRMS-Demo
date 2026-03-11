import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final List<Map<String, dynamic>> _leaveBalances = [
    {
      'type': 'Casual Leave',
      'used': 3,
      'total': 12,
      'color': AppColors.primary,
      'icon': Icons.wb_sunny_rounded,
    },
    {
      'type': 'Sick Leave',
      'used': 1,
      'total': 8,
      'color': AppColors.danger,
      'icon': Icons.local_hospital_rounded,
    },
    {
      'type': 'Earned Leave',
      'used': 5,
      'total': 15,
      'color': AppColors.success,
      'icon': Icons.star_rounded,
    },
    {
      'type': 'Comp Off',
      'used': 0,
      'total': 3,
      'color': AppColors.orange,
      'icon': Icons.swap_calls_rounded,
    },
  ];

  final List<Map<String, dynamic>> _leaveHistory = [
    {
      'type': 'Casual Leave',
      'startDate': 'Mar 10, 2026',
      'endDate': 'Mar 12, 2026',
      'days': 3,
      'status': 'Pending',
      'reason': 'Family function',
      'appliedOn': 'Mar 5, 2026',
      'approver': 'Rajesh Kumar',
      'timeline': [
        {'step': 'Applied', 'date': 'Mar 5, 2026', 'done': true},
        {'step': 'Manager Review', 'date': 'Pending', 'done': false},
        {'step': 'HR Approval', 'date': '', 'done': false},
      ],
    },
    {
      'type': 'Sick Leave',
      'startDate': 'Feb 28, 2026',
      'endDate': 'Feb 28, 2026',
      'days': 1,
      'status': 'Approved',
      'reason': 'Not feeling well',
      'appliedOn': 'Feb 27, 2026',
      'approver': 'Rajesh Kumar',
      'timeline': [
        {'step': 'Applied', 'date': 'Feb 27, 2026', 'done': true},
        {'step': 'Manager Review', 'date': 'Feb 27, 2026', 'done': true},
        {'step': 'HR Approval', 'date': 'Feb 28, 2026', 'done': true},
      ],
    },
    {
      'type': 'Earned Leave',
      'startDate': 'Feb 10, 2026',
      'endDate': 'Feb 14, 2026',
      'days': 5,
      'status': 'Approved',
      'reason': 'Vacation trip',
      'appliedOn': 'Jan 28, 2026',
      'approver': 'Rajesh Kumar',
      'timeline': [
        {'step': 'Applied', 'date': 'Jan 28, 2026', 'done': true},
        {'step': 'Manager Review', 'date': 'Jan 29, 2026', 'done': true},
        {'step': 'HR Approval', 'date': 'Jan 30, 2026', 'done': true},
      ],
    },
    {
      'type': 'Casual Leave',
      'startDate': 'Jan 20, 2026',
      'endDate': 'Jan 20, 2026',
      'days': 1,
      'status': 'Rejected',
      'reason': 'Personal work',
      'appliedOn': 'Jan 18, 2026',
      'approver': 'Rajesh Kumar',
      'timeline': [
        {'step': 'Applied', 'date': 'Jan 18, 2026', 'done': true},
        {'step': 'Manager Review', 'date': 'Jan 19, 2026', 'done': true},
        {'step': 'Rejected', 'date': 'Jan 19, 2026', 'done': true},
      ],
    },
  ];

  Color _leaveTypeColor(String type) {
    switch (type) {
      case 'Casual Leave':
        return AppColors.primary;
      case 'Sick Leave':
        return AppColors.danger;
      case 'Earned Leave':
        return AppColors.success;
      case 'Comp Off':
        return AppColors.orange;
      default:
        return AppColors.secondary;
    }
  }

  StatusChip _buildStatusChip(String status) {
    switch (status) {
      case 'Approved':
        return StatusChip.approved();
      case 'Rejected':
        return StatusChip.rejected();
      default:
        return StatusChip.pending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/apply-leave');
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Apply Leave',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Balance Section
            Text('Leave Balance', style: textTheme.titleLarge),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.35,
              ),
              itemCount: _leaveBalances.length,
              itemBuilder: (context, index) {
                final balance = _leaveBalances[index];
                final used = balance['used'] as int;
                final total = balance['total'] as int;
                final remaining = total - used;
                final progress = used / total;
                final color = balance['color'] as Color;

                return NeuCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            balance['icon'] as IconData,
                            color: color,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              balance['type'] as String,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textTheme.titleMedium?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$remaining',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '$used used / $total total',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 4,
                                  backgroundColor:
                                      color.withValues(alpha: 0.15),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                  strokeCap: StrokeCap.round,
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Leave History Section
            Text('Leave History', style: textTheme.titleLarge),
            const SizedBox(height: 14),
            ..._leaveHistory.map((leave) {
              final color = _leaveTypeColor(leave['type'] as String);
              final timeline =
                  leave['timeline'] as List<Map<String, dynamic>>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: NeuCard(
                  onTap: () {
                    Navigator.pushNamed(context, '/request-detail',
                        arguments: {
                          'id': 'LV-${_leaveHistory.indexOf(leave) + 1}',
                          'type': 'Leave',
                          'title': leave['type'],
                          'subtitle':
                              '${leave['startDate']} - ${leave['endDate']}',
                          'status': leave['status'],
                          'description': leave['reason'],
                          'timeline': timeline,
                        });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              leave['type'] as String,
                              style: textTheme.titleMedium,
                            ),
                          ),
                          _buildStatusChip(leave['status'] as String),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14,
                              color: textTheme.bodyMedium?.color),
                          const SizedBox(width: 6),
                          Text(
                            '${leave['startDate']} - ${leave['endDate']}',
                            style: textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${leave['days']} day${(leave['days'] as int) > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Mini timeline
                      Row(
                        children: timeline.asMap().entries.map((entry) {
                          final step = entry.value;
                          final isDone = step['done'] as bool;
                          final isLast = entry.key == timeline.length - 1;
                          return Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: isDone
                                      ? AppColors.success
                                      : textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    step['step'] as String,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: isDone
                                          ? AppColors.success
                                          : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isLast)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 12,
                                      color: textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.3),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
