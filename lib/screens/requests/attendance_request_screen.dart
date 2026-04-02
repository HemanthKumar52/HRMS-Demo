import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/neu_card.dart';

class AttendanceRequestScreen extends StatefulWidget {
  const AttendanceRequestScreen({super.key});

  @override
  State<AttendanceRequestScreen> createState() => _AttendanceRequestScreenState();
}

class _AttendanceRequestScreenState extends State<AttendanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedEmployee;
  DateTime? _attendanceDate;
  String? _selectedShift;
  String? _attendanceStatus;
  TimeOfDay? _expectedCheckIn;
  TimeOfDay? _expectedCheckOut;
  TimeOfDay? _checkIn;
  TimeOfDay? _checkOut;
  String? _workType;
  String _workedHours = '00:00';
  String? _attachmentName;
  bool _isSubmitting = false;

  List<String> _employees = [];
  List<String> _shifts = [];
  List<String> _workTypes = [];

  final List<String> _statusOptions = [
    'Present', 'Absent', 'Half Day', 'On Duty',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final emps = await ApiService.getEmployees();
      final shifts = await ApiService.getShifts();
      final wts = await ApiService.getWorkTypes();
      if (!mounted) return;
      setState(() {
        _employees = emps.map<String>((e) => e['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        _shifts = shifts.map<String>((s) => s['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        _workTypes = wts.map<String>((w) => w['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _calculateWorkedHours() {
    if (_checkIn != null && _checkOut != null) {
      final inMinutes = _checkIn!.hour * 60 + _checkIn!.minute;
      final outMinutes = _checkOut!.hour * 60 + _checkOut!.minute;
      final diff = outMinutes - inMinutes;
      if (diff > 0) {
        final hours = diff ~/ 60;
        final minutes = diff % 60;
        setState(() => _workedHours = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}');
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attendanceDate == null) {
      showErrorSnackbar(context, 'Please select attendance date');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ApiService.post('/attendance/regularize', {
        'attendance_date': (_attendanceDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'description': _descriptionController.text,
      });
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(context, message: 'Attendance request submitted');
      NotificationService.instance.showRequestApplied('Attendance');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showErrorSnackbar(context, 'Failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Attendance Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Attendance Regularization', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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

              const FormLabel('Attendance Date'),
              formLabelGap,
              FormDateField(
                value: formatDate(_attendanceDate),
                hasValue: _attendanceDate != null,
                onTap: () async {
                  final picked = await pickDate(context, initial: _attendanceDate, accentColor: AppColors.warning);
                  if (picked != null) setState(() => _attendanceDate = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Shift'),
              formLabelGap,
              FormDropdown(
                value: _selectedShift,
                hint: 'Select shift',
                items: _shifts,
                onChanged: (v) => setState(() => _selectedShift = v),
              ),
              formFieldGap,

              const FormLabel('Attendance Status'),
              formLabelGap,
              FormDropdown(
                value: _attendanceStatus,
                hint: 'Select status',
                items: _statusOptions,
                onChanged: (v) => setState(() => _attendanceStatus = v),
              ),
              formFieldGap,

              // Expected Check-In / Check-Out
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Expected Check-In'),
                        formLabelGap,
                        FormTimeField(
                          value: formatTime(_expectedCheckIn),
                          hasValue: _expectedCheckIn != null,
                          onTap: () async {
                            final picked = await pickTime(context, initial: _expectedCheckIn);
                            if (picked != null) setState(() => _expectedCheckIn = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Expected Check-Out'),
                        formLabelGap,
                        FormTimeField(
                          value: formatTime(_expectedCheckOut),
                          hasValue: _expectedCheckOut != null,
                          onTap: () async {
                            final picked = await pickTime(context, initial: _expectedCheckOut);
                            if (picked != null) setState(() => _expectedCheckOut = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              formFieldGap,

              // Check In / Check Out
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Check In'),
                        formLabelGap,
                        FormTimeField(
                          value: formatTime(_checkIn),
                          hasValue: _checkIn != null,
                          onTap: () async {
                            final picked = await pickTime(context, initial: _checkIn);
                            if (picked != null) {
                              setState(() => _checkIn = picked);
                              _calculateWorkedHours();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('Check Out'),
                        formLabelGap,
                        FormTimeField(
                          value: formatTime(_checkOut),
                          hasValue: _checkOut != null,
                          onTap: () async {
                            final picked = await pickTime(context, initial: _checkOut);
                            if (picked != null) {
                              setState(() => _checkOut = picked);
                              _calculateWorkedHours();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              formFieldGap,

              const FormLabel('Work Type'),
              formLabelGap,
              FormDropdown(
                value: _workType,
                hint: 'Select work type',
                items: _workTypes,
                onChanged: (v) => setState(() => _workType = v),
              ),
              formFieldGap,

              // Worked Hours (read-only display)
              const FormLabel('Worked Hours'),
              formLabelGap,
              NeuCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                    const SizedBox(width: 10),
                    Text(_workedHours, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              formFieldGap,

              const FormLabel('Attachment'),
              formLabelGap,
              FormAttachment(
                fileName: _attachmentName,
                onTap: () async {
                  final picker = ImagePicker();
                  final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (file != null) setState(() => _attachmentName = file.name);
                },
                onRemove: () => setState(() => _attachmentName = null),
              ),
              formFieldGap,

              const FormLabel('Reason for Regularization'),
              formLabelGap,
              FormInput(controller: _reasonController, hint: 'Enter reason...', maxLines: 2),
              formFieldGap,

              const FormLabel('Request Description'),
              formLabelGap,
              FormInput(controller: _descriptionController, hint: 'Description', maxLines: 3),
              formSectionGap,

              FormActionButtons(isSubmitting: _isSubmitting, onSubmit: _submit, buttonColor: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}
