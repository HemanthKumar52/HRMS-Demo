import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';
import 'apply_leave_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String _activeFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Leave',
    'Claims',
    'Tickets',
    'Shift Requests',
    'Work Type Requests',
    'Attendance Requests',
  ];

  // Request types for the "Requests" tab
  final List<Map<String, dynamic>> _requestTypes = [
    {
      'type': 'Leave',
      'title': 'Apply Leave',
      'subtitle': 'Request time off from work',
      'icon': Icons.event_busy_rounded,
      'color': AppColors.primary,
    },
    {
      'type': 'Claims',
      'title': 'Submit Claim',
      'subtitle': 'Expense reimbursement',
      'icon': Icons.receipt_long_rounded,
      'color': AppColors.success,
    },
    {
      'type': 'Tickets',
      'title': 'Raise Ticket',
      'subtitle': 'Report an issue or request',
      'icon': Icons.confirmation_number_rounded,
      'color': AppColors.orange,
    },
    {
      'type': 'Shift',
      'title': 'Shift Change',
      'subtitle': 'Request shift modification',
      'icon': Icons.swap_horiz_rounded,
      'color': AppColors.secondary,
    },
    {
      'type': 'Work Type',
      'title': 'Work Type Request',
      'subtitle': 'WFH / Office / Hybrid',
      'icon': Icons.home_work_rounded,
      'color': AppColors.pink,
    },
    {
      'type': 'Attendance',
      'title': 'Attendance Request',
      'subtitle': 'Correct check-in/out time',
      'icon': Icons.fingerprint_rounded,
      'color': AppColors.warning,
    },
  ];

  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'REQ-001',
      'type': 'Leave',
      'title': 'Casual Leave',
      'subtitle': 'Mar 10 - Mar 12, 2026',
      'status': 'Pending',
      'icon': Icons.beach_access_rounded,
      'color': AppColors.primary,
    },
    {
      'id': 'REQ-002',
      'type': 'Claims',
      'title': 'Travel Reimbursement',
      'subtitle': 'Amount: ₹34,500',
      'status': 'Approved',
      'icon': Icons.receipt_long_rounded,
      'color': AppColors.success,
    },
    {
      'id': 'REQ-003',
      'type': 'Tickets',
      'title': 'VPN Access Issue',
      'subtitle': 'IT Support - High Priority',
      'status': 'Pending',
      'icon': Icons.confirmation_number_rounded,
      'color': AppColors.orange,
    },
    {
      'id': 'REQ-004',
      'type': 'Shift Requests',
      'title': 'Night Shift Swap',
      'subtitle': 'Mar 15, 2026',
      'status': 'Rejected',
      'icon': Icons.swap_horiz_rounded,
      'color': AppColors.pink,
    },
    {
      'id': 'REQ-005',
      'type': 'Work Type Requests',
      'title': 'Work From Home',
      'subtitle': 'Mar 20 - Mar 22, 2026',
      'status': 'Approved',
      'icon': Icons.home_work_rounded,
      'color': AppColors.secondary,
    },
    {
      'id': 'REQ-006',
      'type': 'Attendance Requests',
      'title': 'Check-in Correction',
      'subtitle': 'Mar 5, 2026 - 09:15 AM',
      'status': 'Pending',
      'icon': Icons.fingerprint_rounded,
      'color': AppColors.warning,
    },
    {
      'id': 'REQ-007',
      'type': 'Leave',
      'title': 'Sick Leave',
      'subtitle': 'Feb 28, 2026',
      'status': 'Approved',
      'icon': Icons.local_hospital_rounded,
      'color': AppColors.danger,
    },
  ];

  List<Map<String, dynamic>> get _filteredRequests {
    if (_activeFilter == 'All') return _requests;
    return _requests.where((r) => r['type'] == _activeFilter).toList();
  }

  StatusChip _buildStatusChip(String status) {
    switch (status) {
      case 'Approved':
        return StatusChip.approved();
      case 'Rejected':
        return StatusChip.rejected();
      default:
        return StatusChip.pending();
    }
  }

  void _onRequestTypeTap(Map<String, dynamic> type) {
    if (type['type'] == 'Leave') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ApplyRequestScreen(
            type: type['title'] as String,
            icon: type['icon'] as IconData,
            color: type['color'] as Color,
          ),
        ),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: NeuDecoration.glass(context, radius: 28),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Filter Requests', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _filterOptions.map((filter) {
                  final isActive = _activeFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _activeFilter = filter);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isActive ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final chipIndex = provider.requestsTabIndex;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          if (chipIndex == 1)
            IconButton(
              icon: Badge(
                isLabelVisible: _activeFilter != 'All',
                smallSize: 8,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.filter_list_rounded),
              ),
              onPressed: _showFilterSheet,
            ),
        ],
      ),
      body: Column(
        children: [
          // Chip-style toggle: Requests / Requested
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE4E8EE),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFFBEC3CE).withValues(alpha: 0.4),
                          offset: const Offset(3, 3),
                          blurRadius: 6,
                        ),
                        const BoxShadow(
                          color: Color(0xFFFDFFFF),
                          offset: Offset(-3, -3),
                          blurRadius: 6,
                        ),
                      ],
              ),
              child: Row(
                children: [
                  _buildChipButton('Requests', Icons.add_circle_outline_rounded, 0, chipIndex, isDark, provider),
                  const SizedBox(width: 4),
                  _buildChipButton('Requested', Icons.history_rounded, 1, chipIndex, isDark, provider),
                ],
              ),
            ),
          ),

          // Content based on selected chip
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: chipIndex == 0
                  ? _buildRequestTypesView(textTheme, isDark)
                  : _buildRequestedView(textTheme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipButton(String label, IconData icon, int index, int activeIndex, bool isDark, AppProvider provider) {
    final isActive = activeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setRequestsTabIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── "Requests" tab: shows request type categories ──────────────
  Widget _buildRequestTypesView(TextTheme textTheme, bool isDark) {
    return ListView.builder(
      key: const ValueKey('requests-types'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _requestTypes.length,
      itemBuilder: (context, index) {
        final type = _requestTypes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeuCard(
            onTap: () => _onRequestTypeTap(type),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (type['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(type['icon'] as IconData, color: type['color'] as Color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type['title'] as String, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(type['subtitle'] as String, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 22),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms, delay: (index * 60).ms).slideX(begin: 0.05, end: 0, duration: 350.ms, delay: (index * 60).ms, curve: Curves.easeOut),
        );
      },
    );
  }

  // ─── "Requested" tab: shows submitted requests and their status ─
  Widget _buildRequestedView(TextTheme textTheme, bool isDark) {
    return Column(
      key: const ValueKey('requested-list'),
      children: [
        // Active filter indicator
        if (_activeFilter != 'All')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_activeFilter, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _activeFilter = 'All'),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text('${_filteredRequests.length} results', style: textTheme.bodySmall),
              ],
            ),
          ),

        // Request list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: _filteredRequests.length,
            itemBuilder: (context, index) {
              final request = _filteredRequests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeuCard(
                  onTap: () {
                    Navigator.pushNamed(context, '/request-detail', arguments: request);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (request['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(request['icon'] as IconData, color: request['color'] as Color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(request['title'] as String, style: textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                                _buildStatusChip(request['status'] as String),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(request['subtitle'] as String, style: textTheme.bodySmall),
                            const SizedBox(height: 2),
                            Text(request['id'] as String, style: textTheme.bodySmall?.copyWith(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: textTheme.bodyMedium?.color, size: 20),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: (index * 60).ms).slideX(begin: 0.05, end: 0, duration: 350.ms, delay: (index * 60).ms, curve: Curves.easeOut),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FABOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FABOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic Apply Request Screen (Claims, Tickets, Shifts, Work Type, Attendance)
// ---------------------------------------------------------------------------
class _ApplyRequestScreen extends StatefulWidget {
  final String type;
  final IconData icon;
  final Color color;

  const _ApplyRequestScreen({
    required this.type,
    required this.icon,
    required this.color,
  });

  @override
  State<_ApplyRequestScreen> createState() => _ApplyRequestScreenState();
}

class _ApplyRequestScreenState extends State<_ApplyRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a date'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.type} request submitted successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Apply ${widget.type}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeuCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New ${widget.type}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Fill in the details below to submit your request', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Title', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              NeuCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter ${widget.type.toLowerCase()} title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
                ),
              ),
              const SizedBox(height: 20),
              Text('Date', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: NeuCard(
                      onTap: () => _pickDate(true),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: widget.color),
                          const SizedBox(width: 8),
                          Text(_formatDate(_startDate), style: TextStyle(color: _startDate != null ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext), fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('to', style: theme.textTheme.bodySmall)),
                  Expanded(
                    child: NeuCard(
                      onTap: () => _pickDate(false),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: widget.color),
                          const SizedBox(width: 8),
                          Text(_formatDate(_endDate), style: TextStyle(color: _endDate != null ? (isDark ? AppColors.darkText : AppColors.lightText) : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext), fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Description', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              NeuCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide details about your ${widget.type.toLowerCase()} request...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Submit ${widget.type}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
