import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/employee_cc_field.dart';
import '../../widgets/form_fields.dart';

class RaiseTicketScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const RaiseTicketScreen({super.key, this.editData});

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

  bool get _isEditing => widget.editData != null;
  String? get _editId => widget.editData?['id']?.toString();

  @override
  void initState() {
    super.initState();
    _ticketType = _ticketTypes.first;
    _priority = _priorities.first;
    _department = _departments.first;
    _prefillFromEditData();
  }

  void _prefillFromEditData() {
    final data = widget.editData;
    if (data == null) return;
    final md = data['metadata'] as Map<String, dynamic>? ?? {};
    _titleController.text =
        md['title']?.toString() ?? data['description']?.toString() ?? '';
    _descriptionController.text =
        data['description']?.toString() ?? md['description']?.toString() ?? '';
    if (md['priority'] != null) {
      final p = md['priority'].toString();
      final match = _priorities.where(
        (o) => o.toLowerCase() == p.toLowerCase(),
      );
      if (match.isNotEmpty) _priority = match.first;
    }
    if (md['ticket_type'] != null) {
      final t = md['ticket_type'].toString();
      final match = _ticketTypes.where(
        (o) => o.toLowerCase() == t.toLowerCase(),
      );
      if (match.isNotEmpty) _ticketType = match.first;
    }
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
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _priority.toLowerCase(),
        'ticket_type': _ticketType,
        'department': _department,
        'cc': _ccUsers.map((u) => u['user_id']).toList(),
      };
      if (_isEditing) {
        await ApiService.updateTicket(int.parse(_editId!), payload);
      } else {
        await ApiService.raiseTicket(payload);
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(
        context,
        message: _isEditing ? 'Ticket updated' : 'Ticket raised successfully',
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
        title: _isEditing ? 'Edit Ticket Request' : 'Ticket Request',
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
              const FormLabel('Title', required: true),
              formLabelGap,
              FormInput(
                controller: _titleController,
                hint: 'Title',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              formFieldGap,

              const FormLabel('Ticket Type', required: true),
              formLabelGap,
              FormDropdown(
                value: _ticketType,
                hint: 'Select ticket type',
                items: _ticketTypes,
                onChanged: (v) =>
                    setState(() => _ticketType = v ?? _ticketTypes.first),
              ),
              formFieldGap,

              const FormLabel('Priority', required: true),
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

              const FormLabel('Reason', required: true),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Reason',
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
