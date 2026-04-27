import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/form_fields.dart';

class ShiftChangeScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const ShiftChangeScreen({super.key, this.editData});

  @override
  State<ShiftChangeScreen> createState() => _ShiftChangeScreenState();
}

class _ShiftChangeScreenState extends State<ShiftChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _requestingShift;
  DateTime? _requestedDate;
  DateTime? _requestedTill;
  bool _permanentRequest = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.editData != null;
  String? get _editId => widget.editData?['id']?.toString();

  List<String> _shifts = [];

  @override
  void initState() {
    super.initState();
    _prefillFromEditData();
    _loadData();
  }

  void _prefillFromEditData() {
    final data = widget.editData;
    if (data == null) return;

    _requestingShift = data['requesting_shift']?.toString();
    _descriptionController.text = data['description']?.toString() ?? '';

    final dateStr = data['requested_date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      _requestedDate = DateTime.tryParse(dateStr);
    }

    final tillStr = data['requested_till']?.toString();
    if (tillStr != null && tillStr.isNotEmpty) {
      _requestedTill = DateTime.tryParse(tillStr);
    }
  }

  Future<void> _loadData() async {
    try {
      final shifts = await ApiService.getShifts();
      if (!mounted) return;
      setState(() {
        _shifts = shifts
            .map<String>((s) => s['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        if (_shifts.isNotEmpty && _requestingShift == null) {
          _requestingShift = _shifts.first;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_requestedDate == null) {
      showErrorSnackbar(context, 'Please select requested date');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'requesting_shift': _requestingShift ?? '',
        'requested_date': (_requestedDate ?? DateTime.now())
            .toIso8601String()
            .split('T')[0],
        'requested_till': _permanentRequest
            ? null
            : _requestedTill?.toIso8601String().split('T')[0],
        'description': _descriptionController.text,
        'is_permanent': _permanentRequest,
      };

      if (_isEditing) {
        await ApiService.updateShiftRequest(int.parse(_editId!), payload);
      } else {
        await ApiService.post('/shifts/request', payload);
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(
        context,
        message: _isEditing
            ? 'Shift change request updated'
            : 'Shift change request submitted',
      );
      // (Single notification only — SuccessOverlay above covers it.)
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: _isEditing ? 'Edit Shift Request' : 'Shift Request',
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
              const FormLabel('Requesting Shift', required: true),
              formLabelGap,
              FormDropdown(
                value: _requestingShift,
                hint: 'Select shift',
                items: _shifts,
                onChanged: (v) => setState(
                  () => _requestingShift =
                      v ?? (_shifts.isNotEmpty ? _shifts.first : null),
                ),
              ),
              formFieldGap,

              const FormLabel('Requested Date', required: true),
              formLabelGap,
              FormDateField(
                value: formatDate(_requestedDate),
                hasValue: _requestedDate != null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _requestedDate,
                    accentColor: AppColors.secondary,
                  );
                  if (picked != null) {
                    setState(() {
                      _requestedDate = picked;
                      if (_requestedTill != null &&
                          _requestedTill!.isBefore(picked))
                        _requestedTill = picked;
                    });
                  }
                },
              ),
              formFieldGap,

              const FormLabel('Requested Till'),
              formLabelGap,
              FormDateField(
                value: formatDate(_requestedTill),
                hasValue: _requestedTill != null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _requestedTill ?? _requestedDate,
                    accentColor: AppColors.secondary,
                  );
                  if (picked != null) setState(() => _requestedTill = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Reason'),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Reason',
                maxLines: 3,
              ),
              formFieldGap,

              // Permanent Request toggle
              _buildToggle(textTheme, isDark),
              formSectionGap,

              FormActionButtons(
                isSubmitting: _isSubmitting,
                onSubmit: _submit,
                buttonColor: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(TextTheme textTheme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Make this as permanent',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Switch.adaptive(
          value: _permanentRequest,
          onChanged: (v) => setState(() => _permanentRequest = v),
          activeTrackColor: AppColors.secondary,
        ),
      ],
    );
  }
}
