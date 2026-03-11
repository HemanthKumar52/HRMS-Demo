import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      'subtitle': 'Amount: \$450.00',
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

  void _onFabTap(BuildContext context) {
    switch (_activeFilter) {
      case 'Leave':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()));
        break;
      case 'Claims':
        Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Claim', icon: Icons.receipt, color: AppColors.success)));
        break;
      case 'Tickets':
        Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Ticket', icon: Icons.confirmation_num, color: AppColors.orange)));
        break;
      case 'Shift Requests':
        Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Shift Change', icon: Icons.swap_horiz, color: AppColors.secondary)));
        break;
      case 'Work Type Requests':
        Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Work Type', icon: Icons.work, color: AppColors.pink)));
        break;
      case 'Attendance Requests':
        Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Attendance Request', icon: Icons.fingerprint, color: AppColors.warning)));
        break;
      default:
        _showQuickActionSheet(context);
    }
  }

  void _showQuickActionSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.55,
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Select Request Type', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Choose a category to apply', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              _FABOption(icon: Icons.event_busy, label: 'Apply Leave', subtitle: 'Request time off', color: AppColors.primary, onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()));
              }),
              _FABOption(icon: Icons.receipt, label: 'Submit Claim', subtitle: 'Expense reimbursement', color: AppColors.success, onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Claim', icon: Icons.receipt, color: AppColors.success)));
              }),
              _FABOption(icon: Icons.confirmation_num, label: 'Raise Ticket', subtitle: 'Report an issue', color: AppColors.orange, onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Ticket', icon: Icons.confirmation_num, color: AppColors.orange)));
              }),
              _FABOption(icon: Icons.swap_horiz, label: 'Shift Change', subtitle: 'Request shift change', color: AppColors.secondary, onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Shift Change', icon: Icons.swap_horiz, color: AppColors.secondary)));
              }),
              _FABOption(icon: Icons.work, label: 'Work Type', subtitle: 'WFH / Office / Hybrid', color: AppColors.pink, onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Work Type', icon: Icons.work, color: AppColors.pink)));
              }),
              _FABOption(icon: Icons.fingerprint, label: 'Attendance Request', subtitle: 'Correct check-in/out', color: AppColors.warning, onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplyRequestScreen(type: 'Attendance Request', icon: Icons.fingerprint, color: AppColors.warning)));
              }),
            ],
          ),
        ),
      ),
    );
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
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filter Requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          heroTag: 'requestFab',
          onPressed: () => _onFabTap(context),
          backgroundColor: AppColors.primary,
          elevation: 6,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: Column(
        children: [
          // Active filter indicator
          if (_activeFilter != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _activeFilter,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _activeFilter = 'All'),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredRequests.length} results',
                    style: textTheme.bodySmall,
                  ),
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
                      Navigator.pushNamed(context, '/request-detail',
                          arguments: request);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (request['color'] as Color)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            request['icon'] as IconData,
                            color: request['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      request['title'] as String,
                                      style: textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildStatusChip(
                                      request['status'] as String),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request['subtitle'] as String,
                                style: textTheme.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                request['id'] as String,
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: textTheme.bodyMedium?.color,
                          size: 20,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms, delay: (index * 60).ms).slideX(begin: 0.05, end: 0, duration: 350.ms, delay: (index * 60).ms, curve: Curves.easeOut),
                );
              },
            ),
          ),
        ],
      ),
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
                      Text(label,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 20),
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

  _ApplyRequestScreen({
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
              // Header
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
                          Text(
                            'New ${widget.type}',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the details below to submit your request',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title field
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

              // Date selection
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
                          Text(
                            _formatDate(_startDate),
                            style: TextStyle(
                              color: _startDate != null
                                  ? (isDark ? AppColors.darkText : AppColors.lightText)
                                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('to', style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    child: NeuCard(
                      onTap: () => _pickDate(false),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: widget.color),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(_endDate),
                            style: TextStyle(
                              color: _endDate != null
                                  ? (isDark ? AppColors.darkText : AppColors.lightText)
                                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
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

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Submit ${widget.type}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
