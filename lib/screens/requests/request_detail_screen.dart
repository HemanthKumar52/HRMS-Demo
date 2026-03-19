import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class RequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? requestData;

  const RequestDetailScreen({super.key, this.requestData});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late Map<String, dynamic> _data;
  bool _showRejectionField = false;
  final _rejectionController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _data = widget.requestData != null
        ? Map<String, dynamic>.from(widget.requestData!)
        : {
            'id': 'REQ-001',
            'type': 'Leave',
            'title': 'Casual Leave',
            'status': 'Pending',
          };
  }

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

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

  void _handleAccept() {
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _data['status'] = 'Accepted';
        if (widget.requestData != null) {
          widget.requestData!['status'] = 'Accepted';
        }
        _isProcessing = false;
      });
      NotificationService.instance
          .showRequestAssigned(_data['type'] as String? ?? 'Request');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Request accepted'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    });
  }

  void _handleReject() {
    if (!_showRejectionField) {
      setState(() => _showRejectionField = true);
      return;
    }
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reason = _rejectionController.text.isNotEmpty
          ? _rejectionController.text
          : 'Rejected by manager';
      setState(() {
        _data['status'] = 'Rejected';
        _data['rejectionReason'] = reason;
        if (widget.requestData != null) {
          widget.requestData!['status'] = 'Rejected';
          widget.requestData!['rejectionReason'] = reason;
        }
        _isProcessing = false;
        _showRejectionField = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Request rejected'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final isManagerOrHr =
        provider.role == UserRole.manager || provider.role == UserRole.hr;

    final data = _data;

    // If route arguments were used
    if (widget.requestData == null) {
      final routeData = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
      if (routeData != null) {
        _data = Map<String, dynamic>.from(routeData);
      }
    }

    final status = data['status'] as String? ?? 'Pending';
    final appliedDate = data['appliedDate'] as String? ??
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final employeeName = data['employeeName'] as String?;
    final isPending = status == 'Pending';

    // Manager/HR viewing an employee request (has employeeName)
    final isManagerViewingEmployee = isManagerOrHr && employeeName != null;

    final timeline = data['timeline'] as List<Map<String, dynamic>>? ??
        _buildDefaultTimeline(status, appliedDate, data);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isManagerViewingEmployee
            ? 'Employee Request'
            : 'Request Details'),
        actions: [
          // Only show edit icon for employee viewing their own pending request
          if (!isManagerViewingEmployee && isPending)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('Edit request feature coming soon'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
                  Row(
                    children: [
                      if (data['icon'] != null && data['color'] != null) ...[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (data['color'] as Color)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(data['icon'] as IconData,
                              color: data['color'] as Color, size: 22),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] as String? ?? 'Request',
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['type'] as String? ?? '',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(
                begin: 0.08,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut),

            const SizedBox(height: 16),

            // Details Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                  // Removed duplicate Status row - already shown in header chip
                  if (data['description'] != null &&
                      (data['description'] as String).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(
                        color: textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.15)),
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
            ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(
                begin: 0.08,
                end: 0,
                duration: 400.ms,
                delay: 80.ms,
                curve: Curves.easeOut),

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
                          child: const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.danger),
                        ),
                        const SizedBox(width: 10),
                        Text('Rejection Reason',
                            style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        data['rejectionReason'] as String,
                        style: textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 120.ms).slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: 120.ms,
                  curve: Curves.easeOut),
              const SizedBox(height: 16),
            ],

            // Approval Timeline Card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Timeline',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                    final isRejected =
                        stepName.toLowerCase().contains('reject');

                    Color stepColor;
                    if (isRejected && isDone) {
                      stepColor = AppColors.danger;
                    } else if (isDone) {
                      stepColor = AppColors.success;
                    } else {
                      stepColor =
                          textTheme.bodySmall?.color?.withValues(alpha: 0.3) ??
                              Colors.grey;
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 32,
                          child: Column(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? stepColor
                                      : stepColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: isDone
                                      ? null
                                      : Border.all(
                                          color: stepColor, width: 2),
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
                                  height: 44,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  color: isDone
                                      ? stepColor.withValues(alpha: 0.4)
                                      : stepColor.withValues(alpha: 0.15),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsets.only(bottom: isLast ? 0 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stepName,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: isDone
                                        ? (isRejected
                                            ? AppColors.danger
                                            : textTheme.titleMedium?.color)
                                        : textTheme.bodySmall?.color,
                                    fontWeight: isDone
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (stepDate.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: isDone
                                            ? stepColor
                                            : (isDark
                                                ? AppColors.darkSubtext
                                                : AppColors.lightSubtext),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          stepTime.isNotEmpty
                                              ? '$stepDate at $stepTime'
                                              : stepDate,
                                          style:
                                              textTheme.bodySmall?.copyWith(
                                            color: isDone
                                                ? stepColor
                                                : null,
                                            fontWeight: isDone
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (isRejected &&
                                    isDone &&
                                    step['reason'] != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.06),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.danger
                                              .withValues(alpha: 0.15)),
                                    ),
                                    child: Text(
                                      step['reason'] as String,
                                      style: textTheme.bodySmall
                                          ?.copyWith(color: AppColors.danger),
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
            ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(
                begin: 0.08,
                end: 0,
                duration: 400.ms,
                delay: 160.ms,
                curve: Curves.easeOut),

            // ── Actions Section ──────────────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 24),

              // Manager/HR viewing employee request: Accept / Reject
              if (isManagerViewingEmployee) ...[
                // Rejection reason field
                if (_showRejectionField) ...[
                  Text('Reason for Rejection',
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _rejectionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter reason for rejection...',
                        hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      style: textTheme.bodyLarge,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _handleReject,
                          icon: _isProcessing && _showRejectionField
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.danger))
                              : const Icon(Icons.close_rounded, size: 18),
                          label: Text(
                            _showRejectionField
                                ? 'Confirm Reject'
                                : 'Reject',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: BorderSide(
                                color:
                                    AppColors.danger.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _handleAccept,
                          icon: _isProcessing && !_showRejectionField
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Accept',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ]
              // Employee viewing own request: Cancel button
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Cancel Request?'),
                          content: const Text(
                              'Are you sure you want to cancel this request? This action cannot be undone.'),
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
                                    content:
                                        const Text('Request cancelled'),
                                    backgroundColor: AppColors.danger,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              child: const Text('Yes, Cancel',
                                  style:
                                      TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Cancel Request',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
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
      final reviewDate =
          DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 4)));
      final reviewTime =
          DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 4)));
      final approveDate =
          DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 1)));
      final approveTime =
          DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 1)));
      return [
        {
          'step': 'Submitted',
          'date': submittedDate,
          'time': submittedTime,
          'done': true
        },
        {
          'step': 'Under Review',
          'date': reviewDate,
          'time': reviewTime,
          'done': true
        },
        {
          'step': 'Approved',
          'date': approveDate,
          'time': approveTime,
          'done': true
        },
      ];
    } else if (status == 'Rejected') {
      final reviewDate =
          DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 3)));
      final reviewTime =
          DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 3)));
      final rejectDate =
          DateFormat('dd MMM yyyy').format(now.subtract(const Duration(hours: 1)));
      final rejectTime =
          DateFormat('hh:mm a').format(now.subtract(const Duration(hours: 1)));
      return [
        {
          'step': 'Submitted',
          'date': submittedDate,
          'time': submittedTime,
          'done': true
        },
        {
          'step': 'Under Review',
          'date': reviewDate,
          'time': reviewTime,
          'done': true
        },
        {
          'step': 'Rejected',
          'date': rejectDate,
          'time': rejectTime,
          'done': true,
          'reason': data['rejectionReason'] as String? ??
              'Request did not meet the criteria.',
        },
      ];
    } else {
      return [
        {
          'step': 'Submitted',
          'date': submittedDate,
          'time': submittedTime,
          'done': true
        },
        {
          'step': 'Under Review',
          'date': 'Pending',
          'time': '',
          'done': false
        },
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon,
              size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600, color: valueColor),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
