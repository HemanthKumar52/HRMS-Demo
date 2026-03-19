import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_fields.dart';

class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ccController = TextEditingController();
  String? _ticketType;
  String? _priority;
  String? _department;
  String? _status;
  String? _attachmentName;
  bool _isSubmitting = false;

  final List<String> _ticketTypes = [
    'IT Support',
    'HR Query',
    'Facilities',
    'Finance',
    'General',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  final List<String> _departments = [
    'IT Department',
    'HR Department',
    'Facilities',
    'Finance',
    'Admin',
  ];

  final List<String> _statuses = [
    'Open',
    'In Progress',
    'On Hold',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ccController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showSuccessSnackbar(context, 'Ticket raised successfully');
      NotificationService.instance.showRequestApplied('Ticket');
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Raise Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Ticket', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              formFieldGap,

              const FormLabel('Title'),
              formLabelGap,
              FormInput(
                controller: _titleController,
                hint: 'Title',
                validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Describe your issue or request...',
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
              ),
              formFieldGap,

              const FormLabel('Ticket Type'),
              formLabelGap,
              FormDropdown(
                value: _ticketType,
                hint: 'Select ticket type',
                items: _ticketTypes,
                onChanged: (v) => setState(() => _ticketType = v),
              ),
              formFieldGap,

              const FormLabel('Priority'),
              formLabelGap,
              FormDropdown(
                value: _priority,
                hint: 'Select priority',
                items: _priorities,
                onChanged: (v) => setState(() => _priority = v),
              ),
              formFieldGap,

              const FormLabel('Assign to Department'),
              formLabelGap,
              FormDropdown(
                value: _department,
                hint: 'Select department',
                items: _departments,
                onChanged: (v) => setState(() => _department = v),
              ),
              formFieldGap,

              const FormLabel('Status'),
              formLabelGap,
              FormDropdown(
                value: _status,
                hint: 'Select status',
                items: _statuses,
                onChanged: (v) => setState(() => _status = v),
              ),
              formFieldGap,

              const FormLabel('CC'),
              formLabelGap,
              FormInput(controller: _ccController, hint: 'Add CC (email addresses)'),
              formFieldGap,

              const FormLabel('Attachments'),
              formLabelGap,
              FormAttachment(
                fileName: _attachmentName,
                onTap: () => setState(() => _attachmentName = 'screenshot.png'),
                onRemove: () => setState(() => _attachmentName = null),
              ),
              formSectionGap,

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit, buttonColor: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
