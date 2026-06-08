import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/request_action_dialog.dart';
import '../../widgets/status_chip.dart';

class AssignedDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  const AssignedDetailScreen({super.key, required this.request});

  @override
  State<AssignedDetailScreen> createState() => _AssignedDetailScreenState();
}

class _AssignedDetailScreenState extends State<AssignedDetailScreen> {
  late Map<String, dynamic> _request;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _request = Map<String, dynamic>.from(widget.request);
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

  Future<void> _handleAction({required bool approve}) async {
    HapticFeedback.mediumImpact();
    final type = (_request['type'] as String? ?? 'Request');
    final reason = await RequestActionDialog.show(
      context,
      approve: approve,
      requestType: type,
    );
    if (reason == null) return;

    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _request['status'] = approve ? 'Accepted' : 'Rejected';
      widget.request['status'] = _request['status'];
      if (!approve) {
        _request['rejectionReason'] = reason;
        widget.request['rejectionReason'] = reason;
      }
      _isProcessing = false;
    });
    if (approve) {
      NotificationService.instance.showRequestAssigned(type);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Request approved' : 'Request rejected'),
        backgroundColor: approve ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _request['status'] as String;
    final isPending = status == 'Pending';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Assigned Request',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        physics: isApplePlatform ? const BouncingScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _request['id'] as String,
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
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (_request['color'] as Color).withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _request['icon'] as IconData,
                              color: _request['color'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _request['title'] as String,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _request['type'] as String,
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
                )
                .animate()
                .fadeIn(duration: 420.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 16),

            // Details card
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
                        icon: Icons.person_outline_rounded,
                        label: 'Requested By',
                        value: _request['requestedBy'] as String,
                      ),
                      const SizedBox(height: 12),
                      if (_request['appliedDate'] != null) ...[
                        _DetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Applied Date',
                          value: _request['appliedDate'] as String,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _DetailRow(
                        icon: Icons.category_rounded,
                        label: 'Type',
                        value: _request['type'] as String,
                      ),
                      if (_request['deadline'] != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Timeline',
                          value: _request['deadline'] as String,
                        ),
                      ],
                      if (_request['priority'] != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.flag_rounded,
                          label: 'Priority',
                          value: _request['priority'] as String,
                          valueColor: _priorityColor(
                            _request['priority'] as String,
                          ),
                        ),
                      ],
                      if (_request['description'] != null) ...[
                        const SizedBox(height: 16),
                        Divider(
                          color: textTheme.bodySmall?.color?.withValues(
                            alpha: 0.15,
                          ),
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
                          _request['description'] as String,
                          style: textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 80.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 420.ms,
                  delay: 80.ms,
                  curve: Curves.easeOutCubic,
                ),

            // Rejection reason display (for already rejected)
            if (status == 'Rejected' &&
                _request['rejectionReason'] != null) ...[
              const SizedBox(height: 16),
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
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1.2),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Rejection Reason',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
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
                              color: AppColors.danger.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            _request['rejectionReason'] as String,
                            style: textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 160.ms)
                  .slideY(
                    begin: 0.12,
                    end: 0,
                    duration: 420.ms,
                    delay: 160.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ],

            // Approve/Reject actions for pending
            if (isPending) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleAction(approve: false),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _handleAction(approve: true),
                        icon: _isProcessing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: isApplePlatform
                                    ? const CupertinoActivityIndicator(
                                        color: Colors.white,
                                      )
                                    : const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Approve',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppColors.danger;
      case 'High':
        return AppColors.orange;
      case 'Medium':
        return AppColors.warning;
      default:
        return AppColors.success;
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
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
