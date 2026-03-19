import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_fields.dart';

class WorkTypeRequestScreen extends StatefulWidget {
  const WorkTypeRequestScreen({super.key});

  @override
  State<WorkTypeRequestScreen> createState() => _WorkTypeRequestScreenState();
}

class _WorkTypeRequestScreenState extends State<WorkTypeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedEmployee;
  String? _requestingWorkType;
  DateTime? _requestedDate;
  DateTime? _requestedTill;
  bool _permanentRequest = false;
  bool _isSubmitting = false;

  final List<String> _employees = [
    'Venkat Kumar',
    'Priya Sharma',
    'Rahul Verma',
    'Anita Desai',
  ];

  final List<String> _workTypes = [
    'Work From Home',
    'Work From Office',
    'Hybrid',
    'Remote',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_requestedDate == null) {
      showErrorSnackbar(context, 'Please select requested date');
      return;
    }
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showSuccessSnackbar(context, 'Work type request submitted');
      NotificationService.instance.showRequestApplied('Work Type');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Work Type Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Work Type Request', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              formFieldGap,

              const FormLabel('Employee'),
              formLabelGap,
              FormDropdown(
                value: _selectedEmployee,
                hint: 'Select employee',
                items: _employees,
                onChanged: (v) => setState(() => _selectedEmployee = v),
              ),
              formFieldGap,

              const FormLabel('Requesting Work Type'),
              formLabelGap,
              FormDropdown(
                value: _requestingWorkType,
                hint: 'Select work type',
                items: _workTypes,
                onChanged: (v) => setState(() => _requestingWorkType = v),
              ),
              formFieldGap,

              const FormLabel('Requested Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_requestedDate),
                hasValue: _requestedDate != null,
                onTap: () async {
                  final picked = await pickDate(context, initial: _requestedDate, accentColor: AppColors.pink);
                  if (picked != null) {
                    setState(() {
                      _requestedDate = picked;
                      if (_requestedTill != null && _requestedTill!.isBefore(picked)) _requestedTill = picked;
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
                  final picked = await pickDate(context, initial: _requestedTill ?? _requestedDate, accentColor: AppColors.pink);
                  if (picked != null) setState(() => _requestedTill = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(controller: _descriptionController, hint: 'Description', maxLines: 3),
              formFieldGap,

              // Permanent Request toggle
              Row(
                children: [
                  Expanded(
                    child: Text('Permanent Request', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Switch.adaptive(
                    value: _permanentRequest,
                    onChanged: (v) => setState(() => _permanentRequest = v),
                    activeTrackColor: AppColors.pink,
                  ),
                ],
              ),
              formSectionGap,

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit, buttonColor: AppColors.pink),
            ],
          ),
        ),
      ),
    );
  }
}
