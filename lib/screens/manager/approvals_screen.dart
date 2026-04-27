import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';
import '../../widgets/request_action_dialog.dart';
import '../../widgets/status_chip.dart';

/// Manager approvals screen — driven entirely from `/v1/requests?role=manager&status=pending&type=...`.
///
/// Each tab loads its own slice from the backend, supports pull-to-refresh, and
/// approves / rejects through the existing accept/reject endpoints.
class ApprovalsScreen extends StatefulWidget {
  /// Optional initial tab index (0=Leave, 1=Claims, 2=Tickets, 3=WorkType, 4=Attendance).
  final int initialTab;
  const ApprovalsScreen({super.key, this.initialTab = 0});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Approvals',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Tab Bar
          Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: NeuCard(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Leave'),
                      Tab(text: 'Claims'),
                      Tab(text: 'Tickets'),
                      Tab(text: 'Work Type'),
                      Tab(text: 'Regularization'),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 420.ms)
              .slideY(
                begin: 0.12,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 8),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _RequestsTab(typeFilter: 'Leave'),
                _RequestsTab(typeFilter: 'Claims'),
                _RequestsTab(typeFilter: 'Tickets'),
                _RequestsTab(typeFilter: 'Work Type Requests'),
                _RequestsTab(typeFilter: 'Attendance Requests'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

const _avatarPalette = [
  AppColors.primary,
  AppColors.secondary,
  AppColors.success,
  AppColors.orange,
  AppColors.pink,
  AppColors.warning,
];

Color _avatarColorFor(String key) {
  if (key.isEmpty) return AppColors.primary;
  final hash = key.codeUnits.fold<int>(0, (a, c) => a + c);
  return _avatarPalette[hash % _avatarPalette.length];
}

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final d = DateTime.parse(iso);
    return DateFormat('dd MMM yyyy').format(d);
  } catch (_) {
    return iso;
  }
}

String _formatDateRange(String? start, String? end) {
  if ((start == null || start.isEmpty) && (end == null || end.isEmpty))
    return '—';
  if (end == null || end.isEmpty || start == end) return _formatDate(start);
  return '${_formatDate(start)} – ${_formatDate(end)}';
}

String _formatTime(String? iso) {
  if (iso == null || iso.isEmpty) return '--:--';
  try {
    // Backend returns either HH:MM:SS or full ISO. Take the time portion.
    final s = iso.contains('T') ? iso.split('T').last : iso;
    final parts = s.split(':');
    if (parts.length < 2) return iso;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hh = ((h % 12) == 0 ? 12 : h % 12).toString().padLeft(2, '0');
    return '$hh:${m.toString().padLeft(2, '0')} $ampm';
  } catch (_) {
    return iso;
  }
}

// ---------------------------------------------------------------------------
// Generic per-tab loader
// ---------------------------------------------------------------------------
class _RequestsTab extends StatefulWidget {
  /// Backend `type` filter — Leave / Claims / Tickets / Work Type Requests /
  /// Attendance Requests / Shift Requests / Asset Requests.
  final String typeFilter;
  const _RequestsTab({required this.typeFilter});

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.getRequests(
        role: 'manager',
        status: 'pending',
        type: widget.typeFilter,
      );
      final list = List<Map<String, dynamic>>.from(
        resp['requests'] ?? const [],
      );
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Open the action dialog (mandatory reason for reject, optional comment for
  /// approve), then call the API. Optimistic removal with rollback on failure.
  Future<void> _act({
    required Map<String, dynamic> req,
    required bool approve,
  }) async {
    HapticFeedback.mediumImpact();
    final type = (req['type'] as String? ?? 'Request');
    final reason = await RequestActionDialog.show(
      context,
      approve: approve,
      requestType: _humanType(type),
    );
    if (reason == null) return; // user cancelled

    final id = int.tryParse(req['id']?.toString() ?? '');
    if (id == null) return;

    final empName = (req['employee']?['name'] ?? '').toString();
    final removedIndex = _items.indexOf(req);
    setState(() => _items.remove(req));

    try {
      if (approve) {
        await ApiService.acceptRequest(
          id,
          comment: reason.isEmpty ? null : reason,
        );
      } else {
        await ApiService.rejectRequest(id, reason: reason);
      }
      if (!mounted) return;
      _showSnack(
        '${empName.isEmpty ? 'Request' : '$empName\'s request'} ${approve ? 'approved' : 'rejected'}',
        approve ? AppColors.success : AppColors.danger,
      );
    } catch (e) {
      if (!mounted) return;
      // Roll back the optimistic removal.
      setState(() {
        if (removedIndex >= 0 && removedIndex <= _items.length) {
          _items.insert(removedIndex, req);
        } else {
          _items.add(req);
        }
      });
      _showSnack('Action failed: ${e.toString()}', AppColors.danger);
    }
  }

  /// Convert a backend type label like "Work Type Requests" or "Attendance
  /// Requests" into a friendlier dialog title.
  String _humanType(String type) {
    switch (type) {
      case 'Leave':
        return 'Leave Request';
      case 'Claims':
        return 'Claim Request';
      case 'Tickets':
        return 'Ticket Request';
      case 'Work Type Requests':
        return 'Work Type Request';
      case 'Attendance Requests':
        return 'Regularization Request';
      case 'Shift Requests':
        return 'Shift Request';
      case 'Asset Requests':
        return 'Asset Request';
      default:
        return type;
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: isApplePlatform
              ? const CupertinoActivityIndicator(radius: 14)
              : const CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return _EmptyState(
        label: 'No pending ${widget.typeFilter.toLowerCase()} to review',
        onRefresh: _load,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: isApplePlatform
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final req = _items[index];
          final delay = ((index < 6 ? index : 6) * 80).ms;
          final card = _buildCard(req);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: card
                .animate()
                .fadeIn(duration: 420.ms, delay: delay)
                .slideY(
                  begin: 0.06,
                  end: 0,
                  duration: 420.ms,
                  delay: delay,
                  curve: Curves.easeOutCubic,
                ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    VoidCallback approve() =>
        () => _act(req: req, approve: true);
    VoidCallback reject() =>
        () => _act(req: req, approve: false);
    final type = (req['type'] ?? '').toString();
    switch (type) {
      case 'Leave':
        return _LeaveCard(
          request: req,
          onApprove: approve(),
          onReject: reject(),
        );
      case 'Claims':
        return _ClaimCard(
          request: req,
          onApprove: approve(),
          onReject: reject(),
        );
      case 'Tickets':
        return _TicketCard(
          request: req,
          onApprove: approve(),
          onReject: reject(),
        );
      case 'Work Type Requests':
        return _WorkTypeCard(
          request: req,
          onApprove: approve(),
          onReject: reject(),
        );
      case 'Attendance Requests':
        return _RegularizationCard(
          request: req,
          onApprove: approve(),
          onReject: reject(),
        );
      default:
        return _LeaveCard(
          request: req,
          onApprove: approve(),
          onReject: reject(),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final String label;
  final VoidCallback onRefresh;
  const _EmptyState({required this.label, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared header widgets
// ---------------------------------------------------------------------------
class _CardHeader extends StatelessWidget {
  final String employeeName;
  final Widget badge;
  final Widget trailing;

  const _CardHeader({
    required this.employeeName,
    required this.badge,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initialsOf(employeeName);
    final color = _avatarColorFor(employeeName);
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employeeName.isEmpty ? 'Unknown' : employeeName,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              badge,
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ApproveRejectButtons extends StatelessWidget {
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _ApproveRejectButtons({
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 18),
              label: const Text(
                'Approve',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Leave card
// ---------------------------------------------------------------------------
class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _LeaveCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  Color _typeColor(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('sick')) return AppColors.danger;
    if (lower.contains('earned')) return AppColors.success;
    if (lower.contains('casual')) return AppColors.primary;
    return AppColors.primary;
  }

  IconData _typeIcon(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('sick')) return Icons.local_hospital;
    if (lower.contains('earned')) return Icons.beach_access;
    return Icons.event_busy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emp = (request['employee'] ?? {}) as Map;
    final md = (request['metadata'] ?? {}) as Map;
    final leaveType = (md['leave_type'] ?? 'Leave').toString();
    final reason = (md['reason'] ?? request['description'] ?? '').toString();
    final dateRange = _formatDateRange(
      md['start_date']?.toString(),
      md['end_date']?.toString(),
    );
    final color = _typeColor(leaveType);

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            employeeName: (emp['name'] ?? '').toString(),
            badge: Row(
              children: [
                Icon(_typeIcon(leaveType), size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  'Leave Request',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            trailing: StatusChip.pending(),
          ),
          const SizedBox(height: 14),
          // Type chip (sick / casual / earned …).
          if (leaveType.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                leaveType,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (leaveType.isNotEmpty) const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(dateRange, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason.isEmpty ? 'No reason provided' : reason,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ApproveRejectButtons(onApprove: onApprove, onReject: onReject),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claim card
// ---------------------------------------------------------------------------
class _ClaimCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _ClaimCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emp = (request['employee'] ?? {}) as Map;
    final md = (request['metadata'] ?? {}) as Map;
    final category = (md['category'] ?? 'Claim').toString();
    final description = (md['description'] ?? request['description'] ?? '')
        .toString();
    final amount = md['amount'];
    final date = _formatDate(request['created_date']?.toString());

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            employeeName: (emp['name'] ?? '').toString(),
            badge: const Row(
              children: [
                Icon(Icons.receipt_long, size: 14, color: AppColors.orange),
                SizedBox(width: 4),
                Text(
                  'Claim Request',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            trailing: StatusChip.pending(),
          ),
          const SizedBox(height: 14),
          // Category chip (Travel, Food, …) — sourced from the linked ticket title.
          if (category.isNotEmpty && category != 'Claim')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (amount != null)
            Row(
              children: [
                const Icon(
                  Icons.currency_rupee,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  amount.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          const SizedBox(height: 8),
          if (description.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(description, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          const SizedBox(height: 16),
          _ApproveRejectButtons(onApprove: onApprove, onReject: onReject),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ticket card
// ---------------------------------------------------------------------------
class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _TicketCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
      case 'critical':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p.toLowerCase()) {
      case 'high':
      case 'critical':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emp = (request['employee'] ?? {}) as Map;
    final md = (request['metadata'] ?? {}) as Map;
    final title = (request['title'] ?? 'Ticket').toString();
    final description = (request['description'] ?? '').toString();
    final priority = (md['priority'] ?? 'Medium').toString();
    final ticketType = (md['ticket_type'] ?? '').toString();
    final date = _formatDate(request['created_date']?.toString());
    final color = _priorityColor(priority);
    final empName = (emp['name'] ?? '').toString();

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            employeeName: empName,
            badge: Row(
              children: [
                Icon(Icons.support_agent, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  'Ticket Request',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            trailing: StatusChip(
              label: priority,
              color: color,
              icon: _priorityIcon(priority),
            ),
          ),
          const SizedBox(height: 14),
          // Ticket title + type chip.
          if (title.isNotEmpty)
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (ticketType.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ticketType,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(date, style: theme.textTheme.bodySmall),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          _ApproveRejectButtons(onApprove: onApprove, onReject: onReject),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Work-type card
// ---------------------------------------------------------------------------
class _WorkTypeCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _WorkTypeCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emp = (request['employee'] ?? {}) as Map;
    final md = (request['metadata'] ?? {}) as Map;
    final workType = (md['work_type'] ?? 'Work From Home').toString();
    final currentType = (md['current_work_type'] ?? 'Office').toString();
    final reason = (md['reason'] ?? '').toString();
    final dateRange = _formatDateRange(
      md['start_date']?.toString(),
      md['end_date']?.toString(),
    );
    final isWfh = workType.toLowerCase().contains('home');
    final color = isWfh ? AppColors.primary : AppColors.secondary;
    final icon = isWfh ? Icons.home_work : Icons.swap_horiz;

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            employeeName: (emp['name'] ?? '').toString(),
            badge: Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  'Work Type Request',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            trailing: StatusChip.pending(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    currentType,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 16, color: color),
                ),
                Flexible(
                  child: Text(
                    workType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(dateRange, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          if (reason.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(reason, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          const SizedBox(height: 16),
          _ApproveRejectButtons(onApprove: onApprove, onReject: onReject),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Regularization card (AttendanceRequest)
// ---------------------------------------------------------------------------
class _RegularizationCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _RegularizationCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final emp = (request['employee'] ?? {}) as Map;
    final md = (request['metadata'] ?? {}) as Map;
    final date = _formatDate(
      md['date']?.toString() ?? request['created_date']?.toString(),
    );
    final fromTime = _formatTime(md['from_time']?.toString());
    final toTime = _formatTime(md['to_time']?.toString());
    final reason = (md['reason'] ?? request['description'] ?? '').toString();

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            employeeName: (emp['name'] ?? '').toString(),
            badge: const Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.secondary),
                SizedBox(width: 4),
                Text(
                  'Regularization Request',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            trailing: StatusChip.pending(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(date, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Punch In',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fromTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.shade300),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Punch Out',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (reason.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(reason, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          const SizedBox(height: 16),
          _ApproveRejectButtons(onApprove: onApprove, onReject: onReject),
        ],
      ),
    );
  }
}
