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

class AttendanceRequestScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const AttendanceRequestScreen({super.key, this.editData});

  @override
  State<AttendanceRequestScreen> createState() =>
      _AttendanceRequestScreenState();
}

class _AttendanceRequestScreenState extends State<AttendanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  static const List<String> _attendanceTypes = <String>[
    'Missed Punch',
    'Late Entry',
    'Early Exit',
    'Absent Marked',
    'Wrong Shift',
    'Work From Home',
  ];

  DateTime? _attendanceDate;
  String _attendanceType = _attendanceTypes.first;
  String? _selectedShift;
  TimeOfDay? _requestedCheckIn;
  TimeOfDay? _requestedCheckOut;
  String? _attachmentName;
  bool _attachmentEnabled = false;
  bool _isSubmitting = false;
  final List<Map<String, dynamic>> _ccUsers = [];

  List<String> _shifts = [];

  bool get _isEditing => widget.editData != null;
  String? get _editId => widget.editData?['id']?.toString();

  @override
  void initState() {
    super.initState();
    _loadShifts();
    _prefillFromEditData();
  }

  void _prefillFromEditData() {
    final data = widget.editData;
    if (data == null) return;

    // Attendance date
    final dateStr = data['attendance_date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      _attendanceDate = DateTime.tryParse(dateStr);
    }

    // Attendance type
    final type = data['attendance_type']?.toString();
    if (type != null && _attendanceTypes.contains(type)) {
      _attendanceType = type;
    }

    // Reason
    final reason = data['reason']?.toString();
    if (reason != null) {
      _reasonController.text = reason;
    }

    // Shift
    final shift = data['shift']?.toString();
    if (shift != null && shift.isNotEmpty) {
      _selectedShift = shift;
    }

    // Check-in time
    final checkIn = data['requested_check_in']?.toString();
    if (checkIn != null && checkIn.contains(':')) {
      final parts = checkIn.split(':');
      _requestedCheckIn = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    // Check-out time
    final checkOut = data['requested_check_out']?.toString();
    if (checkOut != null && checkOut.contains(':')) {
      final parts = checkOut.split(':');
      _requestedCheckOut = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await ApiService.getShifts();
      if (!mounted) return;
      setState(() {
        _shifts = shifts
            .map<String>((s) => s['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        if (_shifts.isNotEmpty) _selectedShift = _shifts.first;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isWrongShift => _attendanceType == 'Wrong Shift';
  bool get _needsTimes =>
      _attendanceType == 'Missed Punch' ||
      _attendanceType == 'Late Entry' ||
      _attendanceType == 'Early Exit' ||
      _attendanceType == 'Work From Home';

  String? _formatTime24(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attendanceDate == null) {
      showErrorSnackbar(context, 'Please select date of regularization');
      return;
    }
    if (_isWrongShift && (_selectedShift == null || _selectedShift!.isEmpty)) {
      showErrorSnackbar(context, 'Please select the correct shift');
      return;
    }
    if (_needsTimes &&
        _requestedCheckIn == null &&
        _attendanceType == 'Missed Punch') {
      showErrorSnackbar(
        context,
        'Requested check-in time is required for missed punch',
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      final body = <String, dynamic>{
        'attendance_date': _attendanceDate!.toIso8601String().split('T')[0],
        'attendance_type': _attendanceType,
        'reason': _reasonController.text.trim(),
      };
      if (_isWrongShift) body['shift'] = _selectedShift;
      final inStr = _formatTime24(_requestedCheckIn);
      final outStr = _formatTime24(_requestedCheckOut);
      if (inStr != null) body['requested_check_in'] = inStr;
      if (outStr != null) body['requested_check_out'] = outStr;
      if (_attachmentName != null) body['attachment_name'] = _attachmentName;
      body['cc'] = _ccUsers.map((u) => u['user_id']).toList();

      if (_isEditing) {
        await ApiService.updateAttendanceRequest(int.parse(_editId!), body);
      } else {
        await ApiService.post('/attendance/regularize', body);
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(
        context,
        message: _isEditing
            ? 'Attendance request updated'
            : 'Attendance request submitted',
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: _isEditing ? 'Edit Attendance Request' : 'Attendance Request',
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
              const FormLabel('Date of Regularization', required: true),
              formLabelGap,
              FormDateField(
                value: formatDate(_attendanceDate),
                hasValue: _attendanceDate != null,
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: _attendanceDate,
                    accentColor: AppColors.warning,
                  );
                  if (picked != null) setState(() => _attendanceDate = picked);
                },
              ),
              formFieldGap,

              const FormLabel('Attendance Type', required: true),
              formLabelGap,
              FormDropdown(
                value: _attendanceType,
                hint: 'Select type',
                items: _attendanceTypes,
                onChanged: (v) => setState(() {
                  _attendanceType = v ?? _attendanceTypes.first;
                  if (!_needsTimes) {
                    _requestedCheckIn = null;
                    _requestedCheckOut = null;
                  }
                }),
              ),
              formFieldGap,

              if (_isWrongShift) ...[
                const FormLabel('Correct Shift'),
                formLabelGap,
                FormDropdown(
                  value: _selectedShift,
                  hint: 'Select shift',
                  items: _shifts,
                  onChanged: (v) => setState(() => _selectedShift = v),
                ),
                formFieldGap,
              ],

              if (_needsTimes) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FormLabel('Requested Check-in'),
                          formLabelGap,
                          FormTimeField(
                            value: formatTime(_requestedCheckIn),
                            hasValue: _requestedCheckIn != null,
                            onTap: () async {
                              final picked = await pickTime(
                                context,
                                initial: _requestedCheckIn,
                              );
                              if (picked != null)
                                setState(() => _requestedCheckIn = picked);
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
                          const FormLabel('Requested Check-out'),
                          formLabelGap,
                          FormTimeField(
                            value: formatTime(_requestedCheckOut),
                            hasValue: _requestedCheckOut != null,
                            onTap: () async {
                              final picked = await pickTime(
                                context,
                                initial: _requestedCheckOut,
                              );
                              if (picked != null)
                                setState(() => _requestedCheckOut = picked);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                formFieldGap,
              ],

              const FormLabel('Reason / Justification', required: true),
              formLabelGap,
              FormInput(
                controller: _reasonController,
                hint: 'e.g., Client meeting outside, system issue...',
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Reason is required';
                  return null;
                },
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
                  if (file != null) setState(() => _attachmentName = file.name);
                },
                onRemove: () => setState(() => _attachmentName = null),
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
                buttonColor: AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
