import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    // Use passed data or fallback sample
    final data = requestData ??
        (ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>?) ??
        {
          'id': 'REQ-001',
          'type': 'Leave',
          'title': 'Casual Leave',
          'subtitle': 'Mar 10 - Mar 12, 2026',
          'status': 'Pending',
          'description': 'Family function',
          'timeline': [
            {'step': 'Applied', 'date': 'Mar 5, 2026', 'done': true},
            {'step': 'Manager Review', 'date': 'Pending', 'done': false},
            {'step': 'HR Approval', 'date': '', 'done': false},
          ],
        };

    final status = data['status'] as String? ?? 'Pending';
    final timeline = data['timeline'] as List<Map<String, dynamic>>? ??
        [
          {'step': 'Submitted', 'date': 'Today', 'done': true},
          {'step': 'Under Review', 'date': 'Pending', 'done': false},
          {'step': 'Final Approval', 'date': '', 'done': false},
        ];

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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Dates',
                    value: data['subtitle'] as String? ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.category_rounded,
                    label: 'Type',
                    value: data['type'] as String? ?? '-',
                  ),
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
                    Divider(
                      color: textTheme.bodySmall?.color?.withValues(alpha: 0.15),
                    ),
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

            // Approval Timeline Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Timeline',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...timeline.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isDone = step['done'] as bool;
                    final isLast = index == timeline.length - 1;
                    final stepName = step['step'] as String;
                    final stepDate = step['date'] as String;
                    final isRejected = stepName.toLowerCase() == 'rejected';

                    Color stepColor;
                    if (isRejected && isDone) {
                      stepColor = AppColors.danger;
                    } else if (isDone) {
                      stepColor = AppColors.success;
                    } else {
                      stepColor = textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.3) ??
                          Colors.grey;
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
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? stepColor
                                      : stepColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: isDone
                                      ? null
                                      : Border.all(color: stepColor, width: 2),
                                ),
                                child: isDone
                                    ? Icon(
                                        isRejected
                                            ? Icons.close_rounded
                                            : Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 40,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
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
                            padding: EdgeInsets.only(
                              bottom: isLast ? 0 : 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stepName,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: isDone
                                        ? textTheme.titleMedium?.color
                                        : textTheme.bodySmall?.color,
                                    fontWeight: isDone
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (stepDate.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    stepDate,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDone
                                          ? stepColor
                                          : null,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text('Cancel Request?'),
                        content: const Text(
                          'Are you sure you want to cancel this request? This action cannot be undone.',
                        ),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Yes, Cancel',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
