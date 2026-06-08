import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../utils/platform_adaptive.dart';
import '../../theme/adaptive_colors.dart';
import '../../widgets/form_fields.dart';

/// Hourly Permission request — mirrors the web's "Permission Request" form
/// (Permission Date / Start Time / End Time / Total Duration / Reason).
/// Posts to /v1/permissions, which writes the shared
/// attendance_permission_request table (same DB as the web).
class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _permissionDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int? get _durationMinutes {
    if (_startTime == null || _endTime == null) return null;
    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    final diff = end - start;
    return diff > 0 ? diff : null;
  }

  String get _durationText {
    final m = _durationMinutes;
    if (m == null) return '--';
    final h = m ~/ 60;
    final mm = m % 60;
    return h > 0 ? '${h}h ${mm}m' : '${mm}m';
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_permissionDate == null || _startTime == null || _endTime == null) {
      showErrorSnackbar(context, 'Please select date, start and end time');
      return;
    }
    if (_durationMinutes == null) {
      showErrorSnackbar(context, 'End time must be after start time');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitPermission({
        'permission_date': _permissionDate!.toIso8601String().split('T')[0],
        'start_time': _fmt(_startTime!),
        'end_time': _fmt(_endTime!),
        'reason': _reasonController.text.trim(),
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(
        context,
        message: 'Permission request submitted',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showErrorSnackbar(
        context,
        'Failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  Widget _durationField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        _durationText,
        style: textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Permission Request',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        physics: isApplePlatform
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormLabel('Permission Date', required: true),
              formLabelGap,
              FormDateField(
                value: formatDate(_permissionDate),
                hasValue: _permissionDate != null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _permissionDate,
                  );
                  if (picked != null) {
                    setState(() => _permissionDate = picked);
                  }
                },
              ),
              formFieldGap,

              const FormLabel('Start Time', required: true),
              formLabelGap,
              FormTimeField(
                value: _startTime == null ? '' : _fmt(_startTime!),
                hasValue: _startTime != null,
                onTap: () async {
                  final picked = await pickTime(context, initial: _startTime);
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
              formFieldGap,

              const FormLabel('End Time', required: true),
              formLabelGap,
              FormTimeField(
                value: _endTime == null ? '' : _fmt(_endTime!),
                hasValue: _endTime != null,
                onTap: () async {
                  final picked = await pickTime(context, initial: _endTime);
                  if (picked != null) setState(() => _endTime = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Total Duration'),
              formLabelGap,
              _durationField(),
              formFieldGap,

              const FormLabel('Reason', required: true),
              formLabelGap,
              FormInput(
                controller: _reasonController,
                hint: 'Enter reason for permission...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Reason is required'
                    : null,
              ),
              formSectionGap,

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
