import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../animations/success_overlay.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../services/live_activity_service.dart';
import '../../services/notification_service.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/employee_cc_field.dart';
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
  late String _startBreakdown;
  late String _endBreakdown;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _attachmentName;
  bool _attachmentEnabled = false;
  final List<Map<String, dynamic>> _ccUsers = [];

  List<String> _leaveTypes = [];

  final List<String> _breakdownOptions = [
    'Full Day',
    'First Half',
    'Second Half',
  ];

  @override
  void initState() {
    super.initState();
    _startBreakdown = _breakdownOptions.first;
    _endBreakdown = _breakdownOptions.first;
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    try {
      final types = await ApiService.getLeaveTypes();
      if (!mounted) return;
      setState(() {
        _leaveTypes = types
            .map<String>((t) => t['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        if (_leaveTypes.isNotEmpty) {
          _selectedLeaveType = _leaveTypes.first;
        }
      });
    } catch (_) {
      _leaveTypes = ['Casual Leave', 'Sick Leave', 'Earned Leave'];
      if (mounted) {
        setState(() => _selectedLeaveType = _leaveTypes.first);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
    try {
      await ApiService.applyLeave({
        'leave_type': _selectedLeaveType!,
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate!.toIso8601String().split('T')[0],
        'start_breakdown': _startBreakdown.toLowerCase().replaceAll(' ', '_'),
        'end_breakdown': _endBreakdown.toLowerCase().replaceAll(' ', '_'),
        'description': _descriptionController.text,
        'cc': _ccUsers.map((u) => u['user_id']).toList(),
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      // (Single notification only — SuccessOverlay below covers it.)
      // Start leave tracking live activity
      LiveActivityService.instance.startLeaveTracking(
        leaveType: _selectedLeaveType!,
        dateRange: '${formatDate(_startDate)} - ${formatDate(_endDate)}',
        status: 'submitted',
      );
      // Refresh notifications so badge updates
      try {
        await ApiService.getNotifications().then((data) {
          if (!mounted) return;
          final provider = context.read<AppProvider>();
          provider.updateNotifications(
            List<Map<String, dynamic>>.from(
              (data['notifications'] as List? ?? []).map(
                (n) => Map<String, dynamic>.from(n),
              ),
            ),
            (data['unread_count'] ?? 0) as int,
          );
        });
      } catch (e) {
        debugPrint('NOTIF_REFRESH ERROR after leave: $e');
      }
      if (!mounted) return;
      await SuccessOverlay.show(context, message: 'Leave request submitted');
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
        title: 'Leave',
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
                'Create Leave Request',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              formFieldGap,

              const FormLabel('Leave Type'),
              formLabelGap,
              FormDropdown(
                value: _selectedLeaveType,
                hint: 'Select leave type',
                items: _leaveTypes,
                onChanged: (v) => setState(
                  () => _selectedLeaveType =
                      v ?? (_leaveTypes.isNotEmpty ? _leaveTypes.first : null),
                ),
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
                      if (_endDate != null && _endDate!.isBefore(picked))
                        _endDate = picked;
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
                onChanged: (v) => setState(
                  () => _startBreakdown = v ?? _breakdownOptions.first,
                ),
              ),
              formFieldGap,

              const FormLabel('End Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_endDate),
                hasValue: _endDate != null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _endDate ?? _startDate,
                  );
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
                onChanged: (v) => setState(
                  () => _endBreakdown = v ?? _breakdownOptions.first,
                ),
              ),
              formFieldGap,

              const FormLabel('Description'),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Description',
                maxLines: 4,
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

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
