import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class RequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? requestData;

  const RequestDetailScreen({super.key, this.requestData});

  StatusChip _buildStatusChip(String status) {
    switch (status) {
      case 'Accepted':
        return StatusChip.accepted();
      case 'Rejected':
        return StatusChip.rejected();
      default:
        return StatusChip.pending();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use passed data or fallback sample
    final data = requestData ??
        (ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>?) ??
        {
          'id': 'REQ-001',
          'type': 'Leave',
          'title': 'Casual Leave',
          'status': 'Pending',
        };

    final status = data['status'] as String? ?? 'Pending';
    final appliedDate = data['appliedDate'] as String? ??
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final employeeName = data['employeeName'] as String?;

    // Build timeline based on status
    final timeline = data['timeline'] as List<Map<String, dynamic>>? ??
        _buildDefaultTimeline(status, appliedDate, data);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          if (status == 'Pending')
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Edit request feature coming soon'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['id'] as String? ?? 'REQ-000',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data['title'] as String? ?? 'Request',
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['type'] as String? ?? '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // Details Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  if (employeeName != null) ...[
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Employee',
                      value: employeeName,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Applied Date',
                    value: appliedDate,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.category_rounded,
                    label: 'Type',
                    value: data['type'] as String? ?? '-',
                  ),
                  if (data['subtitle'] != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.date_range_rounded,
                      label: 'Duration',
                      value: data['subtitle'] as String,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Status',
                    value: status,
                    valueColor: _statusColor(status),
                  ),
                  if (data['description'] != null &&
                      (data['description'] as String).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(color: textTheme.bodySmall?.color?.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    Text(
                      'Description',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['description'] as String,
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // Rejection Reason Card (if rejected)
            if (status == 'Rejected' && data['rejectionReason'] != null) ...[
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.danger),
                        ),
                        const SizedBox(width: 10),
                        Text('Rejection Reason', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        data['rejectionReason'] as String,
                        style: textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 120.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 120.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
            ],

            // Approval Timeline Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Timeline',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  ...timeline.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isDone = step['done'] as bool;
                    final isLast = index == timeline.length - 1;
                    final stepName = step['step'] as String;
                    final stepDate = step['date'] as String;
                    final stepTime = step['time'] as String? ?? '';
                    final isRejected = stepName.toLowerCase().contains('reject');

                    Color stepColor;
                    if (isRejected && isDone) {
                      stepColor = AppColors.danger;
                    } else if (isDone) {
                      stepColor = AppColors.success;
                    } else {
                      stepColor = textTheme.bodySmall?.color?.withValues(alpha: 0.3) ?? Colors.grey;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stepper line and circle
                        SizedBox(
                          width: 32,
                          child: Column(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isDone ? stepColor : stepColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: isDone ? null : Border.all(color: stepColor, width: 2),
                                ),
                                child: isDone
                                    ? Icon(
                                        isRejected ? Icons.close_rounded : Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 44,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: isDone
                                      ? stepColor.withValues(alpha: 0.4)
                                      : stepColor.withValues(alpha: 0.15),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Step content
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stepName,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: isDone ? (isRejected ? AppColors.danger : textTheme.titleMedium?.color) : textTheme.bodySmall?.color,
                                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                if (stepDate.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: isDone ? stepColor : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        stepTime.isNotEmpty ? '$stepDate at $stepTime' : stepDate,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: isDone ? stepColor : null,
                                          fontWeight: isDone ? FontWeight.w500 : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // Show rejection reason inline in timeline
                                if (isRejected && isDone && step['reason'] != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.15)),
                                    ),
                                    child: Text(
                                      step['reason'] as String,
                                      style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),

            // Cancel button for pending requests
            if (status == 'Pending') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Cancel Request?'),
                        content: const Text('Are you sure you want to cancel this request? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('No, Keep It'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Request cancelled'),
                                  backgroundColor: AppColors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildDefaultTimeline(
      String status, String appliedDate, Map<String, dynamic> data) {
    final now = DateTime.now();
    final submittedDate = DateFormat('dd MMM yyyy').format(now);
    final submittedTime = DateFormat('hh:mm a').format(now);

    if (status == 'Accepted') {
      final reviewDate = DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 4)));
      final reviewTime = DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 4)));
      final approveDate = DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 1)));
      final approveTime = DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 1)));
      return [
        {'step': 'Submitted', 'date': submittedDate, 'time': submittedTime, 'done': true},
        {'step': 'Under Review', 'date': reviewDate, 'time': reviewTime, 'done': true},
        {'step': 'Approved', 'date': approveDate, 'time': approveTime, 'done': true},
      ];
    } else if (status == 'Rejected') {
      final reviewDate = DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 3)));
      final reviewTime = DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 3)));
      final rejectDate = DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 1)));
      final rejectTime = DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 1)));
      return [
        {'step': 'Submitted', 'date': submittedDate, 'time': submittedTime, 'done': true},
        {'step': 'Under Review', 'date': reviewDate, 'time': reviewTime, 'done': true},
        {
          'step': 'Rejected',
          'date': rejectDate,
          'time': rejectTime,
          'done': true,
          'reason': data['rejectionReason'] as String? ?? 'Request did not meet the criteria.',
        },
      ];
    } else {
      return [
        {'step': 'Submitted', 'date': submittedDate, 'time': submittedTime, 'done': true},
        {'step': 'Under Review', 'date': 'Pending', 'time': '', 'done': false},
        {'step': 'Final Approval', 'date': '', 'time': '', 'done': false},
      ];
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: valueColor),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
