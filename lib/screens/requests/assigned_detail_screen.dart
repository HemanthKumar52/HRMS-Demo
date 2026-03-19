import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';

class AssignedDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  const AssignedDetailScreen({super.key, required this.request});

  @override
  State<AssignedDetailScreen> createState() => _AssignedDetailScreenState();
}

class _AssignedDetailScreenState extends State<AssignedDetailScreen> {
  late Map<String, dynamic> _request;
  bool _showRejectionField = false;
  final _rejectionController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _request = Map<String, dynamic>.from(widget.request);
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
        _request['status'] = 'Accepted';
        widget.request['status'] = 'Accepted';
        _isProcessing = false;
      });
      NotificationService.instance.showRequestAssigned(_request['type'] as String? ?? 'Request');
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
    // Submit rejection
    setState(() => _isProcessing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _request['status'] = 'Rejected';
        _request['rejectionReason'] = _rejectionController.text.isNotEmpty
            ? _rejectionController.text
            : 'Rejected by manager';
        widget.request['status'] = 'Rejected';
        widget.request['rejectionReason'] = _request['rejectionReason'];
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
    final status = _request['status'] as String;
    final isPending = status == 'Pending';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Assigned Request')),
      body: SingleChildScrollView(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _request['id'] as String,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
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
                          color: (_request['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_request['icon'] as IconData, color: _request['color'] as Color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_request['title'] as String, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(_request['type'] as String, style: textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),

            const SizedBox(height: 16),

            // Details card
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  _DetailRow(icon: Icons.person_outline_rounded, label: 'Requested By', value: _request['requestedBy'] as String),
                  const SizedBox(height: 12),
                  if (_request['appliedDate'] != null) ...[
                    _DetailRow(icon: Icons.calendar_today_rounded, label: 'Applied Date', value: _request['appliedDate'] as String),
                    const SizedBox(height: 12),
                  ],
                  _DetailRow(icon: Icons.category_rounded, label: 'Type', value: _request['type'] as String),
                  if (_request['deadline'] != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(icon: Icons.schedule_rounded, label: 'Timeline', value: _request['deadline'] as String),
                  ],
                  if (_request['priority'] != null) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.flag_rounded,
                      label: 'Priority',
                      value: _request['priority'] as String,
                      valueColor: _priorityColor(_request['priority'] as String),
                    ),
                  ],
                  if (_request['description'] != null) ...[
                    const SizedBox(height: 16),
                    Divider(color: textTheme.bodySmall?.color?.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    Text('Description', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: textTheme.titleMedium?.color)),
                    const SizedBox(height: 6),
                    Text(_request['description'] as String, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),

            // Rejection reason display (for already rejected)
            if (status == 'Rejected' && _request['rejectionReason'] != null) ...[
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
                      child: Text(_request['rejectionReason'] as String, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
            ],

            // Accept/Reject actions for pending
            if (isPending) ...[
              const SizedBox(height: 24),

              // Rejection reason field (shown after user clicks Reject)
              if (_showRejectionField) ...[
                Text('Reason for Rejection', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _rejectionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for rejection...',
                      hintStyle: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: textTheme.bodyLarge,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms),
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
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                            : const Icon(Icons.close_rounded, size: 18),
                        label: Text(
                          _showRejectionField ? 'Confirm Reject' : 'Reject',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
