import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../animations/motion.dart';
import '../../animations/skeleton_loading.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/status_chip.dart';
import 'apply_leave_screen.dart';
import 'submit_claim_screen.dart';
import 'raise_ticket_screen.dart';
import 'shift_change_screen.dart';
import 'work_type_request_screen.dart';
import 'attendance_request_screen.dart';
import 'asset_request_screen.dart';
import 'request_detail_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  String _activeFilter = 'All';
  bool _isLoading = true;

  final List<String> _filterOptions = [
    'All',
    'Leave',
    'Claims',
    'Tickets',
    'Shift Requests',
    'Work Type Requests',
    'Attendance Requests',
    'Asset Requests',
  ];

  // Request types for the "Requests" tab
  final List<Map<String, dynamic>> _requestTypes = [
    {
      'type': 'Leave',
      'title': 'Apply Leave',
      'icon': Icons.event_busy_rounded,
      'color': AppColors.primary,
    },
    {
      'type': 'Claims',
      'title': 'Submit Claim',
      'icon': Icons.receipt_long_rounded,
      'color': AppColors.success,
    },
    {
      'type': 'Tickets',
      'title': 'Raise Ticket',
      'icon': Icons.confirmation_number_rounded,
      'color': AppColors.orange,
    },
    {
      'type': 'Shift',
      'title': 'Shift Change',
      'icon': Icons.swap_horiz_rounded,
      'color': AppColors.secondary,
    },
    {
      'type': 'Work Type',
      'title': 'Work Type Request',
      'icon': Icons.home_work_rounded,
      'color': AppColors.pink,
    },
    {
      'type': 'Attendance',
      'title': 'Attendance Request',
      'icon': Icons.fingerprint_rounded,
      'color': AppColors.warning,
    },
    {
      'type': 'Asset',
      'title': 'Asset Request',
      'icon': Icons.devices_rounded,
      'color': AppColors.neonPurple,
    },
  ];

  // Employee requests (visible to Manager/HR in Requested tab)
  List<Map<String, dynamic>> _employeeRequests = [];

  // Manager/HR's own personal requests (My Requests tab)
  List<Map<String, dynamic>> _myRequests = [];

  // Requested: user's own submitted requests (for Employee role)
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Leave':
        return Icons.beach_access_rounded;
      case 'Claims':
        return Icons.receipt_long_rounded;
      case 'Tickets':
        return Icons.confirmation_number_rounded;
      case 'Shift Requests':
        return Icons.swap_horiz_rounded;
      case 'Work Type Requests':
        return Icons.home_work_rounded;
      case 'Attendance Requests':
        return Icons.fingerprint_rounded;
      case 'Asset Requests':
        return Icons.devices_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'Leave':
        return AppColors.primary;
      case 'Claims':
        return AppColors.success;
      case 'Tickets':
        return AppColors.orange;
      case 'Shift Requests':
        return AppColors.pink;
      case 'Work Type Requests':
        return AppColors.secondary;
      case 'Attendance Requests':
        return AppColors.warning;
      case 'Asset Requests':
        return AppColors.neonPurple;
      default:
        return AppColors.primary;
    }
  }

  String _normalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
      case 'pending':
        return 'Pending';
      case 'approved':
      case 'accepted':
        return 'Accepted';
      case 'rejected':
      case 'denied':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Map<String, dynamic> _mapApiRequest(Map<String, dynamic> apiReq) {
    final type = apiReq['type'] as String? ?? '';
    final status = _normalizeStatus(apiReq['status'] as String? ?? '');
    final employeeName = apiReq['employee'] is Map
        ? (apiReq['employee'] as Map)['name'] as String?
        : null;
    return {
      'id': apiReq['id']?.toString() ?? '',
      // Forward the formatted Req ID (e.g. "LE-0032") so the detail screen
      // shows it instead of the raw DB primary key.
      'request_id': apiReq['request_id'] ?? '',
      'type': type,
      'title': apiReq['title'] ?? '',
      'status': status,
      'icon': _iconForType(type),
      'color': _colorForType(type),
      // Per-type metadata (days requested, attachment, dates, etc.) — used by
      // request_detail_screen for the "Days Requested" row, attachment preview,
      // and Duration computation.
      if (apiReq['metadata'] != null) 'metadata': apiReq['metadata'],
      if (apiReq['employee'] != null) 'employee': apiReq['employee'],
      if (employeeName != null) 'employeeName': employeeName,
      if (apiReq['subtitle'] != null) 'subtitle': apiReq['subtitle'],
      if (apiReq['applied_date'] != null) 'appliedDate': apiReq['applied_date'],
      if (apiReq['appliedDate'] != null) 'appliedDate': apiReq['appliedDate'],
      if (apiReq['description'] != null) 'description': apiReq['description'],
      if (apiReq['rejection_reason'] != null)
        'rejectionReason': apiReq['rejection_reason'],
      if (apiReq['rejectionReason'] != null)
        'rejectionReason': apiReq['rejectionReason'],
      'created_date': apiReq['created_date'] ?? '',
    };
  }

  Future<void> _loadRequests() async {
    try {
      // Fetch own requests (role=self)
      final selfData = await ApiService.getRequests(role: 'self');
      if (!mounted) return;
      final selfRaw = (selfData['requests'] as List?) ?? [];
      final selfMapped = selfRaw
          .map<Map<String, dynamic>>(
            (r) => _mapApiRequest(Map<String, dynamic>.from(r)),
          )
          .toList();

      // For manager/HR, also fetch team requests (role=all)
      var teamMapped = <Map<String, dynamic>>[];
      final provider = context.read<AppProvider>();
      if (provider.isManagerOrAbove) {
        try {
          final teamData = await ApiService.getRequests(role: 'all');
          if (!mounted) return;
          final teamRaw = (teamData['requests'] as List?) ?? [];
          teamMapped = teamRaw
              .map<Map<String, dynamic>>(
                (r) => _mapApiRequest(Map<String, dynamic>.from(r)),
              )
              .toList();
        } catch (_) {}
      }

      setState(() {
        _requests = selfMapped; // Employee's own submitted requests
        _myRequests = selfMapped; // Manager's own requests (My Requests tab)
        _employeeRequests =
            teamMapped; // Team requests for manager/HR (Requested tab)
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_activeFilter == 'All') return _requests;
    return _requests.where((r) => r['type'] == _activeFilter).toList();
  }

  List<Map<String, dynamic>> get _filteredEmployeeRequests {
    if (_activeFilter == 'All') return _employeeRequests;
    return _employeeRequests.where((r) => r['type'] == _activeFilter).toList();
  }

  List<Map<String, dynamic>> get _filteredMyRequests {
    if (_activeFilter == 'All') return _myRequests;
    return _myRequests.where((r) => r['type'] == _activeFilter).toList();
  }

  StatusChip _buildStatusChip(String status) {
    switch (status) {
      case 'Accepted':
        return StatusChip.accepted();
      case 'Rejected':
        return StatusChip.rejected();
      default:
        return StatusChip.pending();
    }
  }

  void _onRequestTypeTap(Map<String, dynamic> type) {
    Widget screen;
    switch (type['type']) {
      case 'Leave':
        screen = const ApplyLeaveScreen();
        break;
      case 'Claims':
        screen = const SubmitClaimScreen();
        break;
      case 'Tickets':
        screen = const RaiseTicketScreen();
        break;
      case 'Shift':
        screen = const ShiftChangeScreen();
        break;
      case 'Work Type':
        screen = const WorkTypeRequestScreen();
        break;
      case 'Attendance':
        screen = const AttendanceRequestScreen();
        break;
      case 'Asset':
        screen = const AssetRequestScreen();
        break;
      default:
        return;
    }
    Navigator.push(
      context,
      Motion.pageRoute(screen),
    ).then((_) => _loadRequests());
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
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
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
                        horizontal: 16,
                        vertical: 10,
                      ),
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

  // ─── Date grouping helpers (WhatsApp style) ─────────────────────
  String _dateGroupLabel(String dateStr) {
    if (dateStr.isEmpty) return 'Older';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      final diff = today.difference(dateOnly).inDays;

      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      if (diff < 7) return 'This Week';
      if (diff < 14) return 'Last Week';
      if (diff < 30) return 'This Month';
      if (diff < 60) return 'Last Month';
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return 'Older';
    }
  }

  /// Builds a flat list of widgets with date section headers inserted.
  List<Widget> _buildGroupedRequestWidgets(
    List<Map<String, dynamic>> requests,
    TextTheme textTheme,
    bool isDark, {
    required bool showEmployee,
  }) {
    if (requests.isEmpty) return [];

    final widgets = <Widget>[];
    String? lastGroup;
    int animIndex = 0;

    for (final request in requests) {
      final group = _dateGroupLabel(request['created_date'] as String? ?? '');
      if (group != lastGroup) {
        lastGroup = group;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: widgets.isEmpty ? 0 : 12,
              bottom: 8,
              left: 4,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(
        _buildRequestListTile(
          request,
          textTheme,
          isDark,
          animIndex,
          showEmployee: showEmployee,
        ),
      );
      animIndex++;
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final chipIndex = provider.requestsTabIndex;
    final isManagerOrHr = provider.isManagerOrAbove;

    // Tab order differs based on role
    // Manager/HR: Approvals (0) | Requested (1) | Request (2)
    // Employee:   Requested (0) | Request (1)
    final tabTitles = isManagerOrHr
        ? ['Approvals', 'Requested', 'Request']
        : ['Requested', 'Request'];

    final safeIndex = chipIndex.clamp(0, tabTitles.length - 1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Inline title row with filter icon
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
            child: Row(
              children: [
                Text(
                  tabTitles[safeIndex],
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Badge(
                    isLabelVisible: _activeFilter != 'All',
                    smallSize: 8,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.filter_list_rounded, size: 22),
                  ),
                  onPressed: _showFilterSheet,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Scrollable tab bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Row(
              children: isManagerOrHr
                  ? [
                      _buildTab(
                        'Approvals',
                        Icons.fact_check_rounded,
                        0,
                        safeIndex,
                        isDark,
                        provider,
                        count: _employeeRequests.length,
                      ),
                      const SizedBox(width: 10),
                      _buildTab(
                        'Requested',
                        Icons.history_rounded,
                        1,
                        safeIndex,
                        isDark,
                        provider,
                        count: _myRequests.length,
                      ),
                      const SizedBox(width: 10),
                      _buildTab(
                        'Request',
                        Icons.add_circle_outline_rounded,
                        2,
                        safeIndex,
                        isDark,
                        provider,
                      ),
                    ]
                  : [
                      _buildTab(
                        'Requested',
                        Icons.history_rounded,
                        0,
                        safeIndex,
                        isDark,
                        provider,
                        count: _requests.length,
                      ),
                      const SizedBox(width: 10),
                      _buildTab(
                        'Request',
                        Icons.add_circle_outline_rounded,
                        1,
                        safeIndex,
                        isDark,
                        provider,
                      ),
                    ],
            ),
          ),

          // Content based on selected chip (with pull-to-refresh)
          Expanded(
            child: _isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SkeletonList(itemCount: 5, showCircle: false),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRequests,
                    color: AppColors.primary,
                    displacement: 40,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _buildTabContent(
                        safeIndex,
                        isManagerOrHr,
                        textTheme,
                        isDark,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    int index,
    bool isManagerOrHr,
    TextTheme textTheme,
    bool isDark,
  ) {
    if (isManagerOrHr) {
      switch (index) {
        case 0:
          return _buildEmployeeRequestsView(textTheme, isDark);
        case 1:
          return _buildMyRequestsView(textTheme, isDark);
        case 2:
          return _buildRequestTypesView(textTheme, isDark);
        default:
          return _buildEmployeeRequestsView(textTheme, isDark);
      }
    } else {
      switch (index) {
        case 0:
          return _buildRequestedView(textTheme, isDark);
        case 1:
          return _buildRequestTypesView(textTheme, isDark);
        default:
          return _buildRequestedView(textTheme, isDark);
      }
    }
  }

  Widget _buildTab(
    String label,
    IconData icon,
    int index,
    int activeIndex,
    bool isDark,
    AppProvider provider, {
    int? count,
  }) {
    final isActive = activeIndex == index;
    return GestureDetector(
      onTap: () => provider.setRequestsTabIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE4E8EE)),
          borderRadius: BorderRadius.circular(50),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFBEC3CE).withValues(alpha: 0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  const BoxShadow(
                    color: Color(0xFFFDFFFF),
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? Colors.white
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── "Requests" tab: shows request type categories ──────────────
  Widget _buildRequestTypesView(TextTheme textTheme, bool isDark) {
    final filtered = _activeFilter == 'All'
        ? _requestTypes
        : _requestTypes.where((r) => r['type'] == _activeFilter).toList();

    return Column(
      key: const ValueKey('requests-types'),
      children: [
        if (_activeFilter != 'All')
          _buildFilterIndicator(textTheme, '${filtered.length} types'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == filtered.length) return const SizedBox(height: 12);
              final type = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    NeuCard(
                          onTap: () => _onRequestTypeTap(type),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (type['color'] as Color).withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  type['icon'] as IconData,
                                  color: type['color'] as Color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  type['title'] as String,
                                  style: textTheme.titleMedium,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? AppColors.darkSubtext
                                    : AppColors.lightSubtext,
                                size: 22,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: (index * 60).ms)
                        .slideX(
                          begin: 0.05,
                          end: 0,
                          duration: 350.ms,
                          delay: (index * 60).ms,
                          curve: Curves.easeOutCubic,
                        ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── "Requested" tab for Employee: shows own submitted requests ─
  Widget _buildRequestedView(TextTheme textTheme, bool isDark) {
    final filtered = _filteredRequests;
    final grouped = _buildGroupedRequestWidgets(
      filtered,
      textTheme,
      isDark,
      showEmployee: false,
    );
    return Column(
      key: const ValueKey('requested-list'),
      children: [
        if (_activeFilter != 'All')
          _buildFilterIndicator(textTheme, '${filtered.length} results'),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 56,
                        color: isDark
                            ? AppColors.darkSubtext.withValues(alpha: 0.4)
                            : AppColors.lightSubtext.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No requests yet',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [...grouped, const SizedBox(height: 12)],
                ),
        ),
      ],
    );
  }

  // ─── "Requested" tab for Manager/HR: shows employee requests ────
  Widget _buildEmployeeRequestsView(TextTheme textTheme, bool isDark) {
    final filtered = _filteredEmployeeRequests;
    final grouped = _buildGroupedRequestWidgets(
      filtered,
      textTheme,
      isDark,
      showEmployee: true,
    );
    return Column(
      key: const ValueKey('employee-requests-list'),
      children: [
        if (_activeFilter != 'All')
          _buildFilterIndicator(textTheme, '${filtered.length} results'),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 56,
                        color: isDark
                            ? AppColors.darkSubtext.withValues(alpha: 0.4)
                            : AppColors.lightSubtext.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No team requests',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [...grouped, const SizedBox(height: 12)],
                ),
        ),
      ],
    );
  }

  // ─── "My Requests" tab for Manager/HR: shows own requests ───────
  Widget _buildMyRequestsView(TextTheme textTheme, bool isDark) {
    final filtered = _filteredMyRequests;
    final grouped = _buildGroupedRequestWidgets(
      filtered,
      textTheme,
      isDark,
      showEmployee: false,
    );
    return Column(
      key: const ValueKey('my-requests-list'),
      children: [
        if (_activeFilter != 'All')
          _buildFilterIndicator(textTheme, '${filtered.length} results'),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 56,
                        color: isDark
                            ? AppColors.darkSubtext.withValues(alpha: 0.4)
                            : AppColors.lightSubtext.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No personal requests yet',
                        style: textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [...grouped, const SizedBox(height: 12)],
                ),
        ),
      ],
    );
  }

  Color _typeTagColor(String type) {
    switch (type) {
      case 'Leave':
        return AppColors.primary;
      case 'Claims':
        return AppColors.success;
      case 'Tickets':
        return AppColors.orange;
      case 'Shift Requests':
        return AppColors.pink;
      case 'Work Type Requests':
        return AppColors.secondary;
      case 'Attendance Requests':
        return AppColors.warning;
      case 'Asset Requests':
        return AppColors.neonPurple;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildTypeTag(String type) {
    final color = _typeTagColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Shared request list tile ───────────────────────────────────
  Widget _buildRequestListTile(
    Map<String, dynamic> request,
    TextTheme textTheme,
    bool isDark,
    int index, {
    required bool showEmployee,
  }) {
    final type = request['type'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child:
          NeuCard(
                onTap: () => Navigator.push(
                  context,
                  Motion.pageRoute(RequestDetailScreen(requestData: request)),
                ).then((_) => _loadRequests()),
                child: Row(
                  children: [
                    Hero(
                      tag: 'request_icon_${request['id']}_${request['type']}',
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (request['color'] as Color).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          request['icon'] as IconData,
                          color: request['color'] as Color,
                          size: 20,
                        ),
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
                              _buildStatusChip(request['status'] as String),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              _buildTypeTag(type),
                              if (request['appliedDate'] != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  (request['appliedDate'] as String)
                                      .split(',')
                                      .first,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkSubtext
                                        : AppColors.lightSubtext,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (showEmployee &&
                              request['employeeName'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.darkSubtext
                                      : AppColors.lightSubtext,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  request['employeeName'] as String,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                      size: 20,
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 350.ms, delay: (index * 60).ms)
              .slideX(
                begin: 0.05,
                end: 0,
                duration: 350.ms,
                delay: (index * 60).ms,
                curve: Curves.easeOutCubic,
              ),
    );
  }

  Widget _buildFilterIndicator(TextTheme textTheme, String countText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(countText, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
