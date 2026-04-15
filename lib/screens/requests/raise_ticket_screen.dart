import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/employee_cc_field.dart';
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
  final List<Map<String, dynamic>> _ccUsers = [];
  late String _ticketType;
  late String _priority;
  late String _department;
  String? _attachmentName;
  bool _attachmentEnabled = false;
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

  @override
  void initState() {
    super.initState();
    // Default to first option in each dropdown
    _ticketType = _ticketTypes.first;
    _priority = _priorities.first;
    _department = _departments.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // _ccUsers is a plain list, no controller to dispose.
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService.raiseTicket({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _priority.toLowerCase(),
        'ticket_type': _ticketType,
        'department': _department,
        'cc': _ccUsers.map((u) => u['user_id']).toList(),
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(context, message: 'Ticket raised successfully');
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
        title: 'Raise Ticket',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Ticket',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              formFieldGap,

              const FormLabel('Title'),
              formLabelGap,
              FormInput(
                controller: _titleController,
                hint: 'Title',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              formFieldGap,

              const FormLabel('Ticket Type'),
              formLabelGap,
              FormDropdown(
                value: _ticketType,
                hint: 'Select ticket type',
                items: _ticketTypes,
                onChanged: (v) =>
                    setState(() => _ticketType = v ?? _ticketTypes.first),
              ),
              formFieldGap,

              const FormLabel('Priority'),
              formLabelGap,
              FormDropdown(
                value: _priority,
                hint: 'Select priority',
                items: _priorities,
                onChanged: (v) =>
                    setState(() => _priority = v ?? _priorities.first),
              ),
              formFieldGap,

              const FormLabel('Assign to Department'),
              formLabelGap,
              FormDropdown(
                value: _department,
                hint: 'Select department',
                items: _departments,
                onChanged: (v) =>
                    setState(() => _department = v ?? _departments.first),
              ),
              formFieldGap,

              EmployeeCcField(
                selected: _ccUsers,
                onChanged: (next) => setState(() {
                  _ccUsers
                    ..clear()
                    ..addAll(next);
                }),
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Describe your issue or request...',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Description is required' : null,
              ),
              formFieldGap,

              FormAttachmentToggle(
                enabled: _attachmentEnabled,
                fileName: _attachmentName,
                onToggle: (v) => setState(() {
                  _attachmentEnabled = v;
                  if (!v) _attachmentName = null;
                }),
                onPick: () async {
                  final picker = ImagePicker();
                  final XFile? file = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (file != null) {
                    setState(() => _attachmentName = file.name);
                  }
                },
                onRemove: () => setState(() => _attachmentName = null),
              ),
              formSectionGap,

              FormActionButtons(
                isSubmitting: _isSubmitting,
                onSubmit: _submit,
                buttonColor: AppColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
