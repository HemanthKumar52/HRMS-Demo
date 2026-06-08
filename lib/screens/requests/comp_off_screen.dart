import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../animations/success_overlay.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../utils/platform_adaptive.dart';
import '../../theme/adaptive_colors.dart';
import '../../widgets/form_fields.dart';

/// Comp Off (compensatory leave) request — mirrors the web's
/// "Comp Off Request" form (Employee / Worked On / Reason).
/// Posts to /v1/comp-off, which writes the shared
/// leave_compensatoryleaverequest table (same DB as the web).
class CompOffScreen extends StatefulWidget {
  const CompOffScreen({super.key});

  @override
  State<CompOffScreen> createState() => _CompOffScreenState();
}

class _CompOffScreenState extends State<CompOffScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _workedOn = DateTime.now();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workedOn == null) {
      showErrorSnackbar(context, 'Please select the date you worked on');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitCompOff({
        'worked_on': _workedOn!.toIso8601String().split('T')[0],
        'reason': _reasonController.text.trim(),
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(context, message: 'Comp Off request submitted');
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

  Widget _readonlyField(String value) {
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
        value,
        style: textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AppProvider>().userName;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Comp Off Request',
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
              const FormLabel('Employee', required: true),
              formLabelGap,
              _readonlyField(userName.isNotEmpty ? userName : 'Me'),
              formFieldGap,

              const FormLabel('Worked On', required: true),
              formLabelGap,
              FormDateField(
                value: formatDate(_workedOn),
                hasValue: _workedOn != null,
                onTap: () async {
                  final picked = await pickDate(context, initial: _workedOn);
                  if (picked != null) setState(() => _workedOn = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Reason for Comp Off', required: true),
              formLabelGap,
              FormInput(
                controller: _reasonController,
                hint: 'Reason for Comp Off',
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
