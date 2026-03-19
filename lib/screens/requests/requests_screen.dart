import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
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
import '../../widgets/ppulse_footer.dart';

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
    'Asset Requests',
  ];

  // Request types for the "Requests" tab
  final List<Map<String, dynamic>> _requestTypes = [
    {'type': 'Leave', 'title': 'Apply Leave', 'icon': Icons.event_busy_rounded, 'color': AppColors.primary},
    {'type': 'Claims', 'title': 'Submit Claim', 'icon': Icons.receipt_long_rounded, 'color': AppColors.success},
    {'type': 'Tickets', 'title': 'Raise Ticket', 'icon': Icons.confirmation_number_rounded, 'color': AppColors.orange},
    {'type': 'Shift', 'title': 'Shift Change', 'icon': Icons.swap_horiz_rounded, 'color': AppColors.secondary},
    {'type': 'Work Type', 'title': 'Work Type Request', 'icon': Icons.home_work_rounded, 'color': AppColors.pink},
    {'type': 'Attendance', 'title': 'Attendance Request', 'icon': Icons.fingerprint_rounded, 'color': AppColors.warning},
    {'type': 'Asset', 'title': 'Asset Request', 'icon': Icons.devices_rounded, 'color': AppColors.neonPurple},
  ];

  // Employee requests (visible to Manager/HR in Requested tab)
  final List<Map<String, dynamic>> _employeeRequests = [
    {
      'id': 'REQ-101', 'type': 'Leave', 'title': 'Casual Leave', 'status': 'Pending',
      'icon': Icons.beach_access_rounded, 'color': AppColors.primary,
      'employeeName': 'Priya Sharma', 'subtitle': 'Mar 22 - Mar 23, 2026',
      'appliedDate': '17 Mar 2026, 09:15 AM', 'description': 'Family function attendance.',
    },
    {
      'id': 'REQ-102', 'type': 'Claims', 'title': 'Travel Reimbursement', 'status': 'Accepted',
      'icon': Icons.receipt_long_rounded, 'color': AppColors.success,
      'employeeName': 'Rahul Verma', 'subtitle': '₹12,500',
      'appliedDate': '15 Mar 2026, 02:30 PM', 'description': 'Client visit to Bangalore office.',
    },
    {
      'id': 'REQ-103', 'type': 'Tickets', 'title': 'VPN Access Issue', 'status': 'Pending',
      'icon': Icons.confirmation_number_rounded, 'color': AppColors.orange,
      'employeeName': 'Anita Desai', 'appliedDate': '16 Mar 2026, 11:00 AM',
      'description': 'Unable to connect to company VPN from home network.',
    },
    {
      'id': 'REQ-104', 'type': 'Shift Requests', 'title': 'Night Shift Swap', 'status': 'Rejected',
      'icon': Icons.swap_horiz_rounded, 'color': AppColors.pink,
      'employeeName': 'Karan Patel', 'appliedDate': '14 Mar 2026, 04:45 PM',
      'description': 'Requesting night shift swap for personal reasons.',
      'rejectionReason': 'Night shift is already at full capacity for the requested dates.',
    },
    {
      'id': 'REQ-105', 'type': 'Work Type Requests', 'title': 'Work From Home', 'status': 'Accepted',
      'icon': Icons.home_work_rounded, 'color': AppColors.secondary,
      'employeeName': 'Sneha Gupta', 'subtitle': 'Mar 20 - Mar 21, 2026',
      'appliedDate': '13 Mar 2026, 10:20 AM', 'description': 'Internet installation at new residence.',
    },
    {
      'id': 'REQ-106', 'type': 'Attendance Requests', 'title': 'Check-in Correction', 'status': 'Pending',
      'icon': Icons.fingerprint_rounded, 'color': AppColors.warning,
      'employeeName': 'Amit Singh', 'appliedDate': '17 Mar 2026, 08:30 AM',
      'description': 'Biometric did not register. Was present at office from 9 AM.',
    },
    {
      'id': 'REQ-107', 'type': 'Leave', 'title': 'Sick Leave', 'status': 'Accepted',
      'icon': Icons.local_hospital_rounded, 'color': AppColors.danger,
      'employeeName': 'Divya Nair', 'subtitle': 'Mar 18, 2026',
      'appliedDate': '18 Mar 2026, 07:45 AM', 'description': 'Fever and cold. Doctor advised rest.',
    },
    {
      'id': 'REQ-108', 'type': 'Claims', 'title': 'Office Supplies', 'status': 'Pending',
      'icon': Icons.receipt_long_rounded, 'color': AppColors.success,
      'employeeName': 'Rohan Mehta', 'subtitle': '₹3,200',
      'appliedDate': '16 Mar 2026, 03:15 PM', 'description': 'Purchased ergonomic keyboard and mouse.',
    },
    {
      'id': 'REQ-109', 'type': 'Asset Requests', 'title': 'Laptop Request', 'status': 'Pending',
      'icon': Icons.devices_rounded, 'color': AppColors.neonPurple,
      'employeeName': 'Tanvi Shah', 'appliedDate': '15 Mar 2026, 01:00 PM',
      'description': 'Current laptop has hardware issues. Requesting replacement.',
    },
    {
      'id': 'REQ-110', 'type': 'Tickets', 'title': 'Email Config Issue', 'status': 'Accepted',
      'icon': Icons.confirmation_number_rounded, 'color': AppColors.orange,
      'employeeName': 'Vikram Joshi', 'appliedDate': '12 Mar 2026, 09:50 AM',
      'description': 'Outlook not syncing emails on mobile device.',
    },
  ];

  // Manager/HR's own personal requests (My Requests tab)
  final List<Map<String, dynamic>> _myRequests = [
    {
      'id': 'REQ-001', 'type': 'Leave', 'title': 'Casual Leave', 'status': 'Pending',
      'icon': Icons.beach_access_rounded, 'color': AppColors.primary,
      'subtitle': 'Mar 25 - Mar 26, 2026',
      'appliedDate': '17 Mar 2026, 10:30 AM', 'description': 'Personal work.',
    },
    {
      'id': 'REQ-002', 'type': 'Claims', 'title': 'Travel Reimbursement', 'status': 'Accepted',
      'icon': Icons.receipt_long_rounded, 'color': AppColors.success,
      'subtitle': '₹24,000',
      'appliedDate': '10 Mar 2026, 11:00 AM', 'description': 'Client meeting travel expenses.',
    },
    {
      'id': 'REQ-003', 'type': 'Leave', 'title': 'Earned Leave', 'status': 'Accepted',
      'icon': Icons.beach_access_rounded, 'color': AppColors.primary,
      'subtitle': 'Apr 10 - Apr 14, 2026',
      'appliedDate': '05 Mar 2026, 09:00 AM', 'description': 'Annual family vacation.',
    },
  ];

  // Requested: user's own submitted requests (for Employee role)
  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'REQ-001', 'type': 'Leave', 'title': 'Casual Leave', 'status': 'Pending',
      'icon': Icons.beach_access_rounded, 'color': AppColors.primary,
      'subtitle': 'Mar 22 - Mar 23, 2026',
      'appliedDate': '17 Mar 2026, 09:15 AM', 'description': 'Family function attendance.',
    },
    {
      'id': 'REQ-002', 'type': 'Claims', 'title': 'Travel Reimbursement', 'status': 'Accepted',
      'icon': Icons.receipt_long_rounded, 'color': AppColors.success,
      'subtitle': '₹12,500',
      'appliedDate': '15 Mar 2026, 02:30 PM', 'description': 'Client visit to Bangalore office.',
    },
    {
      'id': 'REQ-003', 'type': 'Tickets', 'title': 'VPN Access Issue', 'status': 'Pending',
      'icon': Icons.confirmation_number_rounded, 'color': AppColors.orange,
      'appliedDate': '16 Mar 2026, 11:00 AM', 'description': 'Unable to connect to company VPN.',
    },
    {
      'id': 'REQ-004', 'type': 'Shift Requests', 'title': 'Night Shift Swap', 'status': 'Rejected',
      'icon': Icons.swap_horiz_rounded, 'color': AppColors.pink,
      'appliedDate': '14 Mar 2026, 04:45 PM', 'description': 'Requesting night shift swap.',
      'rejectionReason': 'Night shift is already at full capacity for the requested dates.',
    },
    {
      'id': 'REQ-005', 'type': 'Work Type Requests', 'title': 'Work From Home', 'status': 'Accepted',
      'icon': Icons.home_work_rounded, 'color': AppColors.secondary,
      'subtitle': 'Mar 20 - Mar 21, 2026',
      'appliedDate': '13 Mar 2026, 10:20 AM', 'description': 'Internet installation at new residence.',
    },
    {
      'id': 'REQ-006', 'type': 'Attendance Requests', 'title': 'Check-in Correction', 'status': 'Pending',
      'icon': Icons.fingerprint_rounded, 'color': AppColors.warning,
      'appliedDate': '17 Mar 2026, 08:30 AM', 'description': 'Biometric did not register.',
    },
    {
      'id': 'REQ-007', 'type': 'Leave', 'title': 'Sick Leave', 'status': 'Accepted',
      'icon': Icons.local_hospital_rounded, 'color': AppColors.danger,
      'subtitle': 'Mar 18, 2026',
      'appliedDate': '18 Mar 2026, 07:45 AM', 'description': 'Fever and cold.',
    },
    {
      'id': 'REQ-008', 'type': 'Claims', 'title': 'Office Supplies', 'status': 'Pending',
      'icon': Icons.receipt_long_rounded, 'color': AppColors.success,
      'subtitle': '₹3,200',
      'appliedDate': '16 Mar 2026, 03:15 PM', 'description': 'Purchased ergonomic keyboard.',
    },
    {
      'id': 'REQ-009', 'type': 'Asset Requests', 'title': 'Laptop Request', 'status': 'Pending',
      'icon': Icons.devices_rounded, 'color': AppColors.neonPurple,
      'appliedDate': '15 Mar 2026, 01:00 PM', 'description': 'Current laptop has hardware issues.',
    },
    {
      'id': 'REQ-010', 'type': 'Tickets', 'title': 'Email Config Issue', 'status': 'Accepted',
      'icon': Icons.confirmation_number_rounded, 'color': AppColors.orange,
      'appliedDate': '12 Mar 2026, 09:50 AM', 'description': 'Outlook not syncing emails.',
    },
    {
      'id': 'REQ-011', 'type': 'Leave', 'title': 'Earned Leave', 'status': 'Pending',
      'icon': Icons.beach_access_rounded, 'color': AppColors.primary,
      'subtitle': 'Apr 5 - Apr 7, 2026',
      'appliedDate': '11 Mar 2026, 10:00 AM', 'description': 'Family vacation.',
    },
    {
      'id': 'REQ-012', 'type': 'Work Type Requests', 'title': 'Hybrid Request', 'status': 'Pending',
      'icon': Icons.home_work_rounded, 'color': AppColors.secondary,
      'appliedDate': '17 Mar 2026, 11:30 AM', 'description': 'Requesting hybrid work mode.',
    },
  ];

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
                  width: 40, height: 4,
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
                spacing: 10, runSpacing: 10,
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
                          fontWeight: FontWeight.w600, fontSize: 13,
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
    final isManagerOrHr = provider.role == UserRole.manager || provider.role == UserRole.hr;

    // Tab order differs based on role
    // Manager/HR: Requested (0) | My Requests (1) | Requests (2)
    // Employee:   Requested (0) | Requests (1)
    final tabTitles = isManagerOrHr
        ? ['Requested', 'My Requests', 'Requests']
        : ['Requested', 'Requests'];

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
                Text(tabTitles[safeIndex], style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
                      _buildTab('Requested', Icons.history_rounded, 0, safeIndex, isDark, provider, count: _employeeRequests.length),
                      const SizedBox(width: 10),
                      _buildTab('My Requests', Icons.person_outline_rounded, 1, safeIndex, isDark, provider, count: _myRequests.length),
                      const SizedBox(width: 10),
                      _buildTab('Requests', Icons.add_circle_outline_rounded, 2, safeIndex, isDark, provider),
                    ]
                  : [
                      _buildTab('Requested', Icons.history_rounded, 0, safeIndex, isDark, provider, count: _requests.length),
                      const SizedBox(width: 10),
                      _buildTab('Requests', Icons.add_circle_outline_rounded, 1, safeIndex, isDark, provider),
                    ],
            ),
          ),

          // Content based on selected chip
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildTabContent(safeIndex, isManagerOrHr, textTheme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index, bool isManagerOrHr, TextTheme textTheme, bool isDark) {
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

  Widget _buildTab(String label, IconData icon, int index, int activeIndex, bool isDark, AppProvider provider, {int? count}) {
    final isActive = activeIndex == index;
    return GestureDetector(
      onTap: () => provider.setRequestsTabIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE4E8EE)),
          borderRadius: BorderRadius.circular(50),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : isDark
                  ? null
                  : [
                      BoxShadow(color: const Color(0xFFBEC3CE).withValues(alpha: 0.3), offset: const Offset(2, 2), blurRadius: 4),
                      const BoxShadow(color: Color(0xFFFDFFFF), offset: Offset(-2, -2), blurRadius: 4),
                    ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.12),
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
              if (index == filtered.length) return const PPulseFooter();
              final type = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NeuCard(
                  onTap: () => _onRequestTypeTap(type),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: (type['color'] as Color).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(type['icon'] as IconData, color: type['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(type['title'] as String, style: textTheme.titleMedium)),
                      Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 22),
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

  // ─── "Requested" tab for Employee: shows own submitted requests ─
  Widget _buildRequestedView(TextTheme textTheme, bool isDark) {
    final filtered = _filteredRequests;
    return Column(
      key: const ValueKey('requested-list'),
      children: [
        if (_activeFilter != 'All')
          _buildFilterIndicator(textTheme, '${filtered.length} results'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == filtered.length) return const PPulseFooter();
              final request = filtered[index];
              return _buildRequestListTile(request, textTheme, isDark, index, showEmployee: false);
            },
          ),
        ),
      ],
    );
  }

  // ─── "Requested" tab for Manager/HR: shows employee requests ────
  Widget _buildEmployeeRequestsView(TextTheme textTheme, bool isDark) {
    final filtered = _filteredEmployeeRequests;
    return Column(
      key: const ValueKey('employee-requests-list'),
      children: [
        if (_activeFilter != 'All')
          _buildFilterIndicator(textTheme, '${filtered.length} results'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == filtered.length) return const PPulseFooter();
              final request = filtered[index];
              return _buildRequestListTile(request, textTheme, isDark, index, showEmployee: true);
            },
          ),
        ),
      ],
    );
  }

  // ─── "My Requests" tab for Manager/HR: shows own requests ───────
  Widget _buildMyRequestsView(TextTheme textTheme, bool isDark) {
    final filtered = _filteredMyRequests;
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
                      Icon(Icons.inbox_rounded, size: 56, color: isDark ? AppColors.darkSubtext.withValues(alpha: 0.4) : AppColors.lightSubtext.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('No personal requests yet', style: textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == filtered.length) return const PPulseFooter();
                    final request = filtered[index];
                    return _buildRequestListTile(request, textTheme, isDark, index, showEmployee: false);
                  },
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
  Widget _buildRequestListTile(Map<String, dynamic> request, TextTheme textTheme, bool isDark, int index, {required bool showEmployee}) {
    final type = request['type'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RequestDetailScreen(requestData: request)),
        ).then((_) => setState(() {})),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (request['color'] as Color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(request['icon'] as IconData, color: request['color'] as Color, size: 20),
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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _buildTypeTag(type),
                      if (request['appliedDate'] != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          (request['appliedDate'] as String).split(',').first,
                          style: textTheme.bodySmall?.copyWith(fontSize: 10, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        ),
                      ],
                    ],
                  ),
                  if (showEmployee && request['employeeName'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                        const SizedBox(width: 4),
                        Text(request['employeeName'] as String, style: textTheme.bodySmall?.copyWith(fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, size: 20),
          ],
        ),
      ).animate().fadeIn(duration: 350.ms, delay: (index * 60).ms).slideX(begin: 0.05, end: 0, duration: 350.ms, delay: (index * 60).ms, curve: Curves.easeOut),
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
          Text(countText, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
