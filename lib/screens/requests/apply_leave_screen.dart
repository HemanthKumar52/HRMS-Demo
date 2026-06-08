import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../animations/success_overlay.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../services/live_activity_service.dart';
import '../../services/notification_service.dart';
import '../../utils/platform_adaptive.dart';
import '../../theme/adaptive_colors.dart';
import '../../widgets/form_fields.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const ApplyLeaveScreen({super.key, this.editData});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  // Web parity: a single "Day Portion" selector (mapped to both the start and
  // end breakdown the /v1 backend expects — no backend/DB change).
  late String _dayPortion;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _attachmentName;
  bool _attachmentEnabled = false;

  List<String> _leaveTypes = [];
  // Web parity: remaining balance per leave-type name (from /v1/leaves/balance).
  final Map<String, num> _remainingByType = {};

  final List<String> _dayPortionOptions = [
    'Full Day',
    'First Half',
    'Second Half',
  ];

  bool get _isEditing => widget.editData != null;
  String? get _editId => widget.editData?['id']?.toString();

  /// Available leaves for the currently selected leave type (web shows this
  /// read-only beside Leave Type). Defaults to 0 when unknown.
  String get _availableLeaves {
    final t = _selectedLeaveType;
    if (t == null) return '0';
    final v = _remainingByType[t];
    return v == null ? '0' : (v % 1 == 0 ? v.toInt().toString() : v.toString());
  }

  @override
  void initState() {
    super.initState();
    _dayPortion = _dayPortionOptions.first;
    _loadLeaveTypes();
    _loadLeaveBalances();
    _prefillFromEditData();
  }

  void _prefillFromEditData() {
    final data = widget.editData;
    if (data == null) return;
    final md = data['metadata'] as Map<String, dynamic>? ?? {};
    _descriptionController.text = data['description'] as String? ?? '';
    if (md['leave_type'] != null) {
      _selectedLeaveType = md['leave_type'].toString();
    }
    if (md['start_date'] != null) {
      _startDate = DateTime.tryParse(md['start_date'].toString());
    }
    if (md['end_date'] != null) {
      _endDate = DateTime.tryParse(md['end_date'].toString());
    }
    // Prefill the single Day Portion from the stored start breakdown.
    if (md['start_breakdown'] != null) {
      final bd = md['start_breakdown'].toString().replaceAll('_', ' ');
      final match = _dayPortionOptions.where(
        (o) => o.toLowerCase() == bd.toLowerCase(),
      );
      if (match.isNotEmpty) _dayPortion = match.first;
    }
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

  /// Read-only: pull each leave type's remaining balance for the "Available
  /// Leaves" field. Uses the existing GET /v1/leaves/balance — no backend change.
  Future<void> _loadLeaveBalances() async {
    try {
      final data = await ApiService.getLeaveBalance();
      final balances = (data['balances'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        for (final b in balances) {
          if (b is Map) {
            final label = b['label']?.toString();
            final remaining = b['remaining'];
            if (label != null && remaining is num) {
              _remainingByType[label] = remaining;
            }
          }
        }
      });
    } catch (_) {
      // Balance unavailable — field simply shows 0 (same as web with no balance).
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

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      // Map the single Day Portion to the start/end breakdown keys the /v1
      // backend already accepts — identical contract, no backend change.
      final portion = _dayPortion.toLowerCase().replaceAll(' ', '_');
      final payload = {
        'leave_type': _selectedLeaveType!,
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate!.toIso8601String().split('T')[0],
        'start_breakdown': portion,
        'end_breakdown': portion,
        'description': _descriptionController.text,
      };
      if (_isEditing) {
        await ApiService.updateLeave(int.parse(_editId!), payload);
      } else {
        await ApiService.applyLeave(payload);
      }
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
      await SuccessOverlay.show(
        context,
        message: _isEditing
            ? 'Leave request updated'
            : 'Leave request submitted',
      );
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

  /// Read-only "Available Leaves" box — matches the web's disabled field.
  Widget _availableLeavesField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        _availableLeaves,
        style: textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: _isEditing ? 'Edit Leave Request' : 'Create Leave Request',
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
              const FormLabel('Leave Type', required: true),
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

              // Web parity: read-only Available Leaves for the selected type.
              const FormLabel('Available Leaves'),
              formLabelGap,
              _availableLeavesField(),
              formFieldGap,

              const FormLabel('Start Date', required: true),
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
              formFieldGap,

              // Web parity: single "Day Portion" selector.
              const FormLabel('Day Portion'),
              formLabelGap,
              FormDropdown(
                value: _dayPortion,
                hint: 'Select day portion',
                items: _dayPortionOptions,
                onChanged: (v) => setState(
                  () => _dayPortion = v ?? _dayPortionOptions.first,
                ),
              ),
              formFieldGap,

              const FormLabel('End Date', required: true),
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
              formFieldGap,

              const FormLabel('Reason for Leave', required: true),
              formLabelGap,
              FormInput(
                controller: _descriptionController,
                hint: 'Description',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Reason is required'
                    : null,
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
