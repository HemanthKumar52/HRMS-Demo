import 'package:flutter/material.dart';
import '../../widgets/form_fields.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startBreakdown;
  String? _endBreakdown;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _attachmentName;

  final List<String> _leaveTypes = [
    'Casual Leave',
    'Sick Leave',
    'Earned Leave',
    'Comp Off',
    'Maternity Leave',
    'Paternity Leave',
    'Bereavement Leave',
  ];

  final List<String> _breakdownOptions = [
    'Full Day',
    'First Half',
    'Second Half',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeaveType == null) {
      showErrorSnackbar(context, 'Please select a leave type');
      return;
    }
    if (_startDate == null || _endDate == null) {
      showErrorSnackbar(context, 'Please select start and end dates');
      return;
    }

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showSuccessSnackbar(context, 'Leave request submitted successfully');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Leave')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Leave Request', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              formFieldGap,

              const FormLabel('Leave Type'),
              formLabelGap,
              FormDropdown(
                value: _selectedLeaveType,
                hint: 'Select leave type',
                items: _leaveTypes,
                onChanged: (v) => setState(() => _selectedLeaveType = v),
                validator: (v) => v == null ? 'Please select a leave type' : null,
              ),
              formFieldGap,

              const FormLabel('Start Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_startDate),
                hasValue: _startDate != null,
                onTap: () async {
                  final picked = await pickDate(context, initial: _startDate);
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              const FormLabel('Start Date Breakdown'),
              formLabelGap,
              FormDropdown(
                value: _startBreakdown,
                hint: 'Select breakdown',
                items: _breakdownOptions,
                onChanged: (v) => setState(() => _startBreakdown = v),
              ),
              formFieldGap,

              const FormLabel('End Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_endDate),
                hasValue: _endDate != null,
                onTap: () async {
                  final picked = await pickDate(context, initial: _endDate ?? _startDate);
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
              const SizedBox(height: 16),

              const FormLabel('End Date Breakdown'),
              formLabelGap,
              FormDropdown(
                value: _endBreakdown,
                hint: 'Select breakdown',
                items: _breakdownOptions,
                onChanged: (v) => setState(() => _endBreakdown = v),
              ),
              formFieldGap,

              const FormLabel('Attachment'),
              formLabelGap,
              FormAttachment(
                fileName: _attachmentName,
                onTap: () => setState(() => _attachmentName = 'medical_certificate.pdf'),
                onRemove: () => setState(() => _attachmentName = null),
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(controller: _descriptionController, hint: 'Description', maxLines: 4),
              formSectionGap,

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
