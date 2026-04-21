import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/employee_cc_field.dart';
import '../../widgets/form_fields.dart';

class WorkTypeRequestScreen extends StatefulWidget {
  const WorkTypeRequestScreen({super.key});

  @override
  State<WorkTypeRequestScreen> createState() => _WorkTypeRequestScreenState();
}

class _WorkTypeRequestScreenState extends State<WorkTypeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _requestingWorkType;
  DateTime? _requestedDate;
  DateTime? _requestedTill;
  bool _permanentRequest = false;
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _ccUsers = [];

  List<String> _workTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final wts = await ApiService.getWorkTypes();
      if (!mounted) return;
      setState(() {
        _workTypes = wts
            .map<String>((w) => w['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        if (_workTypes.isNotEmpty) {
          _requestingWorkType = _workTypes.first;
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
      await ApiService.post('/work-type/request', {
        'work_type': _requestingWorkType ?? '',
        'requested_date': (_requestedDate ?? DateTime.now())
            .toIso8601String()
            .split('T')[0],
        'requested_till': _requestedTill?.toIso8601String().split('T')[0],
        'description': _descriptionController.text,
        'cc': _ccUsers.map((u) => u['user_id']).toList(),
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(
        context,
        message: 'Work type request submitted',
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Work Type Request',
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
              Text(
                'Work Type Request',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              formFieldGap,

              const FormLabel('Requesting Work Type'),
              formLabelGap,
              FormDropdown(
                value: _requestingWorkType,
                hint: 'Select work type',
                items: _workTypes,
                onChanged: (v) => setState(
                  () => _requestingWorkType =
                      v ?? (_workTypes.isNotEmpty ? _workTypes.first : null),
                ),
              ),
              formFieldGap,

              const FormLabel('Requested Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_requestedDate),
                hasValue: _requestedDate != null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _requestedDate,
                    accentColor: AppColors.pink,
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
                    accentColor: AppColors.pink,
                  );
                  if (picked != null) setState(() => _requestedTill = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Description',
                maxLines: 3,
              ),
              formFieldGap,

              // Permanent Request toggle
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Permanent Request',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _permanentRequest,
                    onChanged: (v) => setState(() => _permanentRequest = v),
                    activeTrackColor: AppColors.pink,
                  ),
                ],
              ),
              formSectionGap,

              EmployeeCcField(
                selected: _ccUsers,
                onChanged: (next) => setState(() {
                  _ccUsers
                    ..clear()
                    ..addAll(next);
                }),
              ),
              formSectionGap,

              FormActionButtons(
                isSubmitting: _isSubmitting,
                onSubmit: _submit,
                buttonColor: AppColors.pink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
