import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../animations/success_overlay.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/form_fields.dart';

/// Mobile adaptation of the web "Simple Timesheet" weekly grid.
/// Same shared `simple_timesheet_*` tables (via /v1/timesheet/*), so entries
/// logged here appear on the web and vice-versa.
class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime _weekStart = _mondayOf(DateTime.now());

  Map<String, dynamic> _period = {};
  List<Map<String, dynamic>> _entries = [];

  static DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1)); // Mon=1
  }

  String get _weekStartIso => _weekStart.toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getTimesheetCurrent(weekStart: _weekStartIso);
      if (!mounted) return;
      setState(() {
        _period = Map<String, dynamic>.from(data['period'] ?? {});
        _entries = ((data['entries'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackbar(
        context,
        'Failed to load timesheet: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Whether the user may navigate forward. Like the web, future weeks (any week
  /// starting after the current week) are not accessible.
  bool get _canGoNextWeek => _weekStart.isBefore(_mondayOf(DateTime.now()));

  void _changeWeek(int deltaWeeks) {
    if (deltaWeeks > 0 && !_canGoNextWeek) {
      showErrorSnackbar(context, 'Future weeks are not accessible');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks)));
    _load();
  }

  double get _totalHours => (_period['total_hours'] as num?)?.toDouble() ?? 0;
  double get _wfoHours => (_period['total_wfo_hours'] as num?)?.toDouble() ?? 0;
  double get _wfhHours => (_period['total_wfh_hours'] as num?)?.toDouble() ?? 0;
  String get _status => (_period['status'] as String?) ?? 'draft';
  int? get _periodId => _period['id'] as int?;

  List<Map<String, dynamic>> _entriesForDay(DateTime day) {
    final iso = day.toIso8601String().split('T')[0];
    return _entries.where((e) => e['date'] == iso).toList();
  }

  Future<void> _openEntryForm({Map<String, dynamic>? existing}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimesheetEntryForm(
        weekStart: _weekStart,
        periodId: _periodId,
        existing: existing,
      ),
    );
    // 'saved' = saved & close, 'again' = saved & open a fresh form to add more.
    if (result == 'saved' || result == 'again') await _load();
    if (result == 'again' && mounted) {
      _openEntryForm();
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final id = entry['id'] as int?;
    if (id == null) return;
    HapticFeedback.mediumImpact();
    try {
      await ApiService.deleteTimesheetEntry(id);
      if (!mounted) return;
      showSuccessSnackbar(context, 'Entry deleted');
      _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Delete failed');
    }
  }

  Future<void> _submit() async {
    if (_periodId == null) return;
    if (_totalHours <= 0) {
      showErrorSnackbar(context, 'Add at least one entry before submitting');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitTimesheet(_periodId!);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await SuccessOverlay.show(context, message: 'Timesheet submitted');
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showErrorSnackbar(
        context,
        'Submit failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final canSubmit = _status == 'draft';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Timesheet',
        showBackButton: true,
        actions: _status == 'approved'
            ? null
            : [
                IconButton(
                  onPressed: () => _openEntryForm(),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Activity/Task',
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _buildWeekNav(isDark, weekEnd),
                  const SizedBox(height: 14),
                  _buildSummaryCards(isDark),
                  const SizedBox(height: 8),
                  _buildStatusBadge(isDark),
                  const SizedBox(height: 12),
                  for (int i = 0; i < 7; i++)
                    _buildDaySection(_weekStart.add(Duration(days: i)), isDark),
                  if (canSubmit && _totalHours > 0) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Timesheet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildWeekNav(bool isDark, DateTime weekEnd) {
    final label =
        '${formatDate(_weekStart)}  –  ${formatDate(weekEnd)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => _changeWeek(-1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Timesheet Period',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            // Future weeks are not accessible (matches web). Disable when the
            // viewed week is the current week.
            onPressed: _canGoNextWeek ? () => _changeWeek(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Row(
      children: [
        _statCard('Total', _totalHours, AppColors.secondary, Icons.access_time_rounded, isDark),
        const SizedBox(width: 10),
        _statCard('WFO', _wfoHours, const Color(0xFF06B6D4), Icons.apartment_rounded, isDark),
        const SizedBox(width: 10),
        _statCard('WFH', _wfhHours, AppColors.success, Icons.home_rounded, isDark),
      ],
    );
  }

  Widget _statCard(String label, double hours, Color color, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _fmtHours(hours),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '$label hrs',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final Color c;
    switch (_status) {
      case 'submitted':
        c = AppColors.warning;
        break;
      case 'approved':
        c = AppColors.success;
        break;
      default:
        c = isDark ? Colors.white38 : Colors.grey;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _status[0].toUpperCase() + _status.substring(1),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
        ),
      ),
    );
  }

  static const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _buildDaySection(DateTime day, bool isDark) {
    final entries = _entriesForDay(day);
    final dayTotal = entries.fold<double>(
      0,
      (s, e) => s + ((e['hours'] as num?)?.toDouble() ?? 0),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_weekdayNames[day.weekday - 1]} ${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              if (dayTotal > 0)
                Text(
                  '${_fmtHours(dayTotal)} hrs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                'No entries',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                ),
              ),
            )
          else
            for (final e in entries) _buildEntryCard(e, isDark),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> e, bool isDark) {
    final loc = (e['work_location'] as String?) ?? 'wfo';
    final isWfo = loc.toLowerCase() == 'wfo';
    final hours = (e['hours'] as num?)?.toDouble() ?? 0;
    final project = (e['project_name'] as String?) ?? 'No project';
    final task = (e['task_name'] as String?) ?? (e['activity_name'] as String?) ?? '';
    final locked = _status == 'approved';

    return Dismissible(
      key: ValueKey('ts_${e['id']}'),
      direction: locked ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        await _deleteEntry(e);
        return false; // _load() rebuilds the list
      },
      child: GestureDetector(
        onTap: locked ? null : () => _openEntryForm(existing: e),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (task.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isWfo ? const Color(0xFF06B6D4) : AppColors.success)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isWfo ? 'WFO' : 'WFH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isWfo ? const Color(0xFF06B6D4) : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _fmtHours(hours),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtHours(double h) {
    final whole = h.truncate();
    final mins = ((h - whole) * 60).round();
    return '$whole:${mins.toString().padLeft(2, '0')}';
  }
}

// ── Add / Edit entry bottom sheet ──────────────────────────────────────────

class _TimesheetEntryForm extends StatefulWidget {
  final DateTime weekStart;
  final int? periodId;
  final Map<String, dynamic>? existing;

  const _TimesheetEntryForm({
    required this.weekStart,
    required this.periodId,
    this.existing,
  });

  @override
  State<_TimesheetEntryForm> createState() => _TimesheetEntryFormState();
}

class _TimesheetEntryFormState extends State<_TimesheetEntryForm> {
  final _hoursController = TextEditingController();
  final _commentsController = TextEditingController();
  final _hoursFocus = FocusNode();

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _tasks = [];

  int? _projectId;
  int? _taskId;
  late DateTime _date;
  String _workLocation = 'wfo';
  bool _saving = false;
  bool _loadingTasks = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _date = ex != null && ex['date'] != null
        ? DateTime.parse(ex['date'])
        : _defaultEntryDate();
    if (ex != null) {
      _projectId = ex['project_id'] as int?;
      _taskId = ex['task_id'] as int?;
      _workLocation = ((ex['work_location'] as String?) ?? 'wfo').toLowerCase();
      final h = (ex['hours'] as num?)?.toDouble() ?? 0;
      _hoursController.text = h == 0 ? '' : _decimalToHHMM(h);
      _commentsController.text = (ex['comments'] as String?) ?? '';
    }
    // Normalise "8" -> "08:00", "945" -> "09:45" when the field loses focus.
    _hoursFocus.addListener(() {
      if (!_hoursFocus.hasFocus && _hoursController.text.trim().isNotEmpty) {
        _hoursController.text = _normalizeHours(_hoursController.text);
      }
    });
    _loadProjects();
  }

  /// Default a new entry to *today* when today falls inside the week being
  /// viewed; otherwise fall back to the first day of that week. This stops the
  /// form always landing on Monday and forcing a manual date change.
  DateTime _defaultEntryDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = widget.weekStart.add(const Duration(days: 6));
    if (!today.isBefore(widget.weekStart) && !today.isAfter(weekEnd)) {
      return today;
    }
    return widget.weekStart;
  }

  Future<void> _loadProjects() async {
    try {
      final p = await ApiService.getTimesheetProjects();
      if (!mounted) return;
      setState(() {
        _projects = p.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      if (_projectId != null) _loadTasks(_projectId!);
    } catch (_) {}
  }

  Future<void> _loadTasks(int projectId) async {
    setState(() => _loadingTasks = true);
    try {
      final t = await ApiService.getTimesheetTasks(projectId: projectId);
      if (!mounted) return;
      setState(() {
        _tasks = t.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (!_tasks.any((x) => x['id'] == _taskId)) _taskId = null;
        _loadingTasks = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTasks = false);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _commentsController.dispose();
    _hoursFocus.dispose();
    super.dispose();
  }

  String? _nameOfProject(int? id) =>
      _projects.firstWhere((p) => p['id'] == id, orElse: () => {})['name'] as String?;
  String? _nameOfTask(int? id) =>
      _tasks.firstWhere((t) => t['id'] == id, orElse: () => {})['name'] as String?;

  Future<void> _save({bool addAnother = false}) async {
    if (_projectId == null) {
      showErrorSnackbar(context, 'Please select a project');
      return;
    }
    final hours = _hoursToDecimal(_hoursController.text);
    if (hours <= 0 || hours > 24) {
      showErrorSnackbar(context, 'Enter valid hours (00:00 – 24:00)');
      return;
    }
    if (_commentsController.text.trim().isEmpty) {
      showErrorSnackbar(context, 'Please enter comments');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await ApiService.updateTimesheetEntry({
          'id': widget.existing!['id'],
          'hours': hours,
          'project_id': _projectId,
          'task_id': _taskId,
          'work_location': _workLocation,
          'comments': _commentsController.text.trim(),
        });
      } else {
        await ApiService.createTimesheetEntry({
          'date': _date.toIso8601String().split('T')[0],
          'hours': hours,
          'project_id': _projectId,
          'task_id': _taskId,
          'work_location': _workLocation,
          'comments': _commentsController.text.trim(),
          if (widget.periodId != null) 'period_id': widget.periodId,
        });
      }
      if (!mounted) return;
      Navigator.pop(context, addAnother ? 'again' : 'saved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackbar(
        context,
        'Failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final weekEnd = widget.weekStart.add(const Duration(days: 6));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit Activity/Task' : 'Add Activity/Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              if (!_isEditing) ...[
                const FormLabel('Day', required: true),
                formLabelGap,
                FormDateField(
                  value: formatDate(_date),
                  hasValue: true,
                  onTap: () async {
                    final picked = await pickDate(
                      context,
                      initial: _date,
                      firstDate: widget.weekStart,
                      lastDate: weekEnd,
                      accentColor: AppColors.primary,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                formFieldGap,
              ],

              const FormLabel('Project', required: true),
              formLabelGap,
              FormDropdown(
                value: _nameOfProject(_projectId),
                hint: 'Select Project',
                items: _projects
                    .map((p) => p['name']?.toString() ?? '')
                    .where((s) => s.isNotEmpty)
                    .toList(),
                onChanged: (name) {
                  final p = _projects.firstWhere(
                    (x) => x['name'] == name,
                    orElse: () => {},
                  );
                  setState(() {
                    _projectId = p['id'] as int?;
                    _taskId = null;
                    _tasks = [];
                  });
                  if (_projectId != null) _loadTasks(_projectId!);
                },
              ),
              formFieldGap,

              const FormLabel('Activity / Task'),
              formLabelGap,
              FormDropdown(
                value: _nameOfTask(_taskId),
                hint: _loadingTasks
                    ? 'Loading…'
                    : (_projectId == null
                          ? 'Select a project first'
                          : 'Select Activity'),
                items: _tasks
                    .map((t) => t['name']?.toString() ?? '')
                    .where((s) => s.isNotEmpty)
                    .toList(),
                onChanged: (name) {
                  final t = _tasks.firstWhere(
                    (x) => x['name'] == name,
                    orElse: () => {},
                  );
                  setState(() => _taskId = t['id'] as int?);
                },
              ),
              formFieldGap,

              const FormLabel('Hours', required: true),
              formLabelGap,
              FormInput(
                controller: _hoursController,
                focusNode: _hoursFocus,
                hint: 'HH:MM  (e.g. 8 → 08:00, 945 → 09:45)',
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [_HoursInputFormatter()],
              ),
              formFieldGap,

              const FormLabel('Work Location'),
              formLabelGap,
              _buildLocationToggle(isDark),
              formFieldGap,

              const FormLabel('Comments', required: true),
              formLabelGap,
              FormInput(
                controller: _commentsController,
                hint: 'Describe what you worked on',
                maxLines: 2,
              ),
              formSectionGap,

              if (!_isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _save(addAnother: true),
                    icon: const Icon(Icons.playlist_add, size: 20),
                    label: const Text(
                      'Save & Add Another',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              FormActionButtons(
                isSubmitting: _saving,
                onSubmit: _save,
                buttonColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationToggle(bool isDark) {
    Widget seg(String value, String label, IconData icon, Color color) {
      final selected = _workLocation == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _workLocation = value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.15)
                  : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? color
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.2)),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: selected ? color : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? color
                        : (isDark ? Colors.white54 : Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('wfo', 'Office (WFO)', Icons.business_rounded, const Color(0xFF06B6D4)),
        const SizedBox(width: 10),
        seg('wfh', 'Home (WFH)', Icons.home_rounded, AppColors.success),
      ],
    );
  }
}

// ── Hours field helpers (HH:MM time entry, web-style) ───────────────────────

/// Live input formatter: keeps digits only (max 4) and inserts a ':' before the
/// last two digits once there are 3+ digits.  "9" → "9", "945" → "9:45",
/// "1230" → "12:30".  Final zero-padding happens on blur via [_normalizeHours].
class _HoursInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    String out;
    if (digits.length <= 2) {
      out = digits;
    } else {
      out = '${digits.substring(0, digits.length - 2)}:'
          '${digits.substring(digits.length - 2)}';
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

/// "8" → "08:00", "12" → "12:00", "945" → "09:45", "12:30" → "12:30".
String _normalizeHours(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  String hrsStr;
  String minsStr;
  if (digits.length <= 2) {
    hrsStr = digits;
    minsStr = '00';
  } else {
    minsStr = digits.substring(digits.length - 2);
    hrsStr = digits.substring(0, digits.length - 2);
  }
  var h = int.tryParse(hrsStr) ?? 0;
  var m = int.tryParse(minsStr) ?? 0;
  if (m > 59) m = 59;
  if (h > 24) h = 24;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// "09:45" → 9.75 (decimal hours for the backend).
double _hoursToDecimal(String input) {
  final n = _normalizeHours(input);
  if (n.isEmpty) return 0;
  final parts = n.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return h + m / 60.0;
}

/// 9.75 → "09:45" (decimal hours from backend → display).
String _decimalToHHMM(double h) {
  final hrs = h.truncate();
  final mins = ((h - hrs) * 60).round();
  return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
}
