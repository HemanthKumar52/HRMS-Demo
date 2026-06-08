import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/adaptive_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/neu_card.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/request_action_dialog.dart';
import '../../widgets/status_chip.dart';
import 'apply_leave_screen.dart';
import 'submit_claim_screen.dart';
import 'raise_ticket_screen.dart';
import 'shift_change_screen.dart';
import 'work_type_request_screen.dart';
import 'attendance_request_screen.dart';
import 'asset_request_screen.dart';
import '../../animations/motion.dart';

/// Map a backend request type label to the per-type screen title.
String _humanRequestTitle(String type) {
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
      return type.isEmpty ? 'Request' : type;
  }
}

/// Requested employee's badge ID (e.g. "EMP002") for the header chip.
String? _employeeBadge(Map<String, dynamic> data) {
  final emp = data['employee'];
  if (emp is Map) {
    final id = emp['employee_id']?.toString();
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}

/// Per-type **sub**-type label shown in the Details Type row.
/// Leave  → leave_type ("Casual Leave", "Sick Leave", …)
/// Claims → category
/// Tickets → ticket_type or priority
/// Work Type → work_type
/// Shift → shift name
/// Attendance Requests → attendance_type
/// Falls back to the generic backend type label.
String _subTypeOf(Map<String, dynamic> data) {
  final md = data['metadata'] as Map<String, dynamic>? ?? {};
  final type = (data['type'] ?? '').toString();
  String? sub;
  switch (type) {
    case 'Leave':
      sub = md['leave_type']?.toString();
      break;
    case 'Claims':
      sub = md['category']?.toString();
      break;
    case 'Tickets':
      sub = (md['ticket_type']?.toString().isNotEmpty ?? false)
          ? md['ticket_type'].toString()
          : md['priority']?.toString();
      break;
    case 'Work Type Requests':
      sub = md['work_type']?.toString();
      break;
    case 'Shift Requests':
      sub = md['shift']?.toString();
      break;
    case 'Attendance Requests':
      sub = md['attendance_type']?.toString();
      break;
  }
  if (sub != null && sub.isNotEmpty) return sub;
  return type.isEmpty ? '-' : type;
}

/// Per-type icon for the Details Type row (so the icon also tells you what
/// kind of request you're looking at, not just the label).
IconData _typeIconFor(String type) {
  switch (type) {
    case 'Leave':
      return Icons.beach_access_rounded;
    case 'Comp Off':
    case 'Compensatory Leave':
      return Icons.more_time_rounded;
    case 'Claims':
      return Icons.receipt_long_rounded;
    case 'Tickets':
      return Icons.support_agent_rounded;
    case 'Work Type Requests':
      return Icons.home_work_rounded;
    case 'Shift Requests':
      return Icons.swap_horiz_rounded;
    case 'Attendance Requests':
      return Icons.access_time_rounded;
    case 'Asset Requests':
      return Icons.devices_rounded;
    default:
      return Icons.category_rounded;
  }
}

/// "1 day" / "3 days" — only present for leave requests.
String? _daysRequested(Map<String, dynamic> data) {
  final md = data['metadata'] as Map<String, dynamic>? ?? {};
  final raw = md['requested_days'];
  if (raw == null) return null;
  final d = (raw as num).toDouble();
  if (d <= 0) return null;
  if (d % 1 == 0) return '${d.toInt()} day${d > 1 ? 's' : ''}';
  return '$d days';
}

/// File path of an attachment if the request has one. Currently only Leave
/// requests carry an attachment field, but the helper degrades safely.
String? _attachmentPath(Map<String, dynamic> data) {
  final md = data['metadata'] as Map<String, dynamic>? ?? {};
  final raw = md['attachment'];
  if (raw == null) return null;
  final s = raw.toString().trim();
  return s.isEmpty ? null : s;
}

/// Build a human-readable duration string from the request's metadata.
/// Returns null if no date info is available or if the type has no duration.
String? _buildDuration(Map<String, dynamic> data) {
  final type = data['type']?.toString() ?? '';
  // Asset requests and tickets don't have a date range / duration.
  if (type == 'Asset Requests' || type == 'Tickets') return null;

  final md = data['metadata'] as Map<String, dynamic>? ?? {};
  final fmt = DateFormat('dd MMM yyyy');

  // Leave, Work Type, Shift — have start_date / end_date
  final startRaw = md['start_date'];
  final endRaw = md['end_date'];

  if (startRaw != null) {
    try {
      final start = DateTime.parse(startRaw.toString());
      final startStr = fmt.format(start);
      if (endRaw != null &&
          endRaw.toString().isNotEmpty &&
          endRaw != startRaw) {
        final end = DateTime.parse(endRaw.toString());
        final days = end.difference(start).inDays + 1;
        return '$startStr – ${fmt.format(end)} ($days day${days > 1 ? 's' : ''})';
      }
      final reqDays = md['requested_days'];
      if (reqDays != null) {
        final d = (reqDays as num).toDouble();
        return '$startStr (${d % 1 == 0 ? d.toInt() : d} day${d > 1 ? 's' : ''})';
      }
      return startStr;
    } catch (_) {
      return startRaw.toString();
    }
  }

  // Attendance Requests — date + from_time / to_time
  final attDate = md['date'];
  final from = md['from_time'];
  final to = md['to_time'];
  if (attDate != null) {
    try {
      final d = DateTime.parse(attDate.toString());
      final dateStr = fmt.format(d);
      if (from != null || to != null) {
        return '$dateStr (${from ?? '--:--'} – ${to ?? '--:--'})';
      }
      return dateStr;
    } catch (_) {
      return attDate.toString();
    }
  }
  if (from != null || to != null) {
    return '${from ?? '--:--'} – ${to ?? '--:--'}';
  }

  return null;
}

class RequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? requestData;

  const RequestDetailScreen({super.key, this.requestData});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _data = widget.requestData != null
        ? Map<String, dynamic>.from(widget.requestData!)
        : {
            'id': 'REQ-001',
            'type': 'Leave',
            'title': 'Casual Leave',
            'status': 'Pending',
          };
  }

  @override
  void dispose() {
    super.dispose();
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

  void _navigateToEditForm(BuildContext context, Map<String, dynamic> data) {
    final type = (data['type'] as String?) ?? '';
    Widget? screen;
    switch (type) {
      case 'Leave':
        screen = ApplyLeaveScreen(editData: data);
        break;
      case 'Claims':
        screen = SubmitClaimScreen(editData: data);
        break;
      case 'Tickets':
        screen = RaiseTicketScreen(editData: data);
        break;
      case 'Shift Requests':
        screen = ShiftChangeScreen(editData: data);
        break;
      case 'Work Type Requests':
        screen = WorkTypeRequestScreen(editData: data);
        break;
      case 'Attendance Requests':
        screen = AttendanceRequestScreen(editData: data);
        break;
      case 'Asset Requests':
        screen = AssetRequestScreen(editData: data);
        break;
    }
    if (screen != null) {
      Navigator.push(context, Motion.pageRoute(screen)).then((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _handleAction({required bool approve}) async {
    final type = (_data['type'] as String? ?? 'Request');
    final reason = await RequestActionDialog.show(
      context,
      approve: approve,
      requestType: type,
    );
    if (reason == null) return; // user cancelled

    final id = int.tryParse(_data['id']?.toString() ?? '');
    if (id == null) return;

    setState(() => _isProcessing = true);
    try {
      if (approve) {
        await ApiService.acceptRequest(
          id,
          type: type,
          comment: reason.isEmpty ? null : reason,
        );
      } else {
        await ApiService.rejectRequest(id, type: type, reason: reason);
      }
      if (!mounted) return;
      setState(() {
        _data['status'] = approve ? 'Accepted' : 'Rejected';
        if (!approve) _data['rejectionReason'] = reason;
        if (widget.requestData != null) {
          widget.requestData!['status'] = approve ? 'Accepted' : 'Rejected';
          if (!approve) widget.requestData!['rejectionReason'] = reason;
        }
        _isProcessing = false;
      });
      if (approve) {
        NotificationService.instance.showRequestAssigned(type);
      }
      if (approve) {
        showSuccessSnackbar(context, 'Request approved');
      } else {
        showErrorSnackbar(context, 'Request rejected');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      showErrorSnackbar(
        context,
        'Action failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final isManagerOrHr = provider.isManagerOrAbove;

    final data = _data;

    // If route arguments were used
    if (widget.requestData == null) {
      final routeData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (routeData != null) {
        _data = Map<String, dynamic>.from(routeData);
      }
    }

    final status = data['status'] as String? ?? 'Pending';
    final appliedDate =
        data['appliedDate'] as String? ??
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final employeeName = data['employeeName'] as String?;
    final isPending = status == 'Pending';

    // Manager/HR viewing an employee request (has employeeName)
    final isManagerViewingEmployee = isManagerOrHr && employeeName != null;

    final timeline =
        data['timeline'] as List<Map<String, dynamic>>? ??
        _buildDefaultTimeline(status, appliedDate, data);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: _humanRequestTitle((data['type'] as String?) ?? ''),
        showBackButton: true,
        actions: [
          // Only show edit icon for employee viewing their own pending request
          if (!isManagerViewingEmployee && isPending)
            isApplePlatform
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _navigateToEditForm(context, data),
                    child: const Icon(
                      CupertinoIcons.pencil,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => _navigateToEditForm(context, data),
                  ),
        ],
      ),
      body: SingleChildScrollView(
        physics: isApplePlatform
            ? const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              )
            : null,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: requested employee badge ID on the left,
                      // status pill on the right.
                      Row(
                        children: [
                          if (_employeeBadge(data) != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _employeeBadge(data)!,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Type icon + "Req Id:" label + the real backend-formatted ID
                      // (e.g. "LE-0032") derived from the underlying DB row.
                      Row(
                        children: [
                          if (data['icon'] != null &&
                              data['color'] != null) ...[
                            Hero(
                              tag: 'request_icon_${data['id']}_${data['type']}',
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (data['color'] as Color).withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  data['icon'] as IconData,
                                  color: data['color'] as Color,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'Req Id:',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    (data['request_id'] ??
                                            data['id'] ??
                                            'REQ-000')
                                        .toString(),
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 420.ms)
                .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 16),

            // Details Card
            NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (employeeName != null) ...[
                        _DetailRow(
                          icon: Icons.account_circle_rounded,
                          label: 'Employee',
                          value: employeeName,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _DetailRow(
                        icon: Icons.event_available_rounded,
                        label: 'Applied Date',
                        value: appliedDate,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: _typeIconFor(data['type'] as String? ?? ''),
                        label: 'Type',
                        value: _subTypeOf(data),
                      ),
                      if (_buildDuration(data) != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.date_range_rounded,
                          label: 'Duration',
                          value: _buildDuration(data)!,
                        ),
                      ],
                      // Days requested (leave only — pulled from metadata).
                      if (_daysRequested(data) != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.calendar_month_rounded,
                          label: 'Days Requested',
                          value: _daysRequested(data)!,
                        ),
                      ],
                      // Attachment row + preview if any.
                      if (_attachmentPath(data) != null) ...[
                        const SizedBox(height: 16),
                        Divider(
                          color: textTheme.bodySmall?.color?.withValues(
                            alpha: 0.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AttachmentPreview(path: _attachmentPath(data)!),
                      ],
                      if (data['description'] != null &&
                          (data['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(
                          color: textTheme.bodySmall?.color?.withValues(
                            alpha: 0.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Description',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textTheme.titleMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['description'] as String,
                          style: textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                      // CC list — read-only chips of users this request was CC'd to.
                      if ((data['cc'] is List) &&
                          (data['cc'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(
                          color: textTheme.bodySmall?.color?.withValues(
                            alpha: 0.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.alternate_email_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CC',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textTheme.titleMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final cc in (data['cc'] as List))
                              if (cc is Map)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.30,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    (cc['user_name'] ?? '#${cc['user_id']}')
                                        .toString(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 80.ms)
                .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: 80.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 16),

            // Rejection Reason Card (if rejected)
            if (status == 'Rejected' && data['rejectionReason'] != null) ...[
              NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1.2),
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Rejection Reason',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            data['rejectionReason'] as String,
                            style: textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 420.ms, delay: 120.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    delay: 120.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 16),
            ],

            // Approval Timeline Card
            NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval Timeline',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...timeline.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        final isDone = step['done'] as bool;
                        final isLast = index == timeline.length - 1;
                        final stepName = step['step'] as String;
                        final stepDate = step['date'] as String;
                        final stepTime = step['time'] as String? ?? '';
                        final isRejected = stepName.toLowerCase().contains(
                          'reject',
                        );

                        Color stepColor;
                        if (isRejected && isDone) {
                          stepColor = AppColors.danger;
                        } else if (isDone) {
                          stepColor = AppColors.success;
                        } else {
                          stepColor =
                              textTheme.bodySmall?.color?.withValues(
                                alpha: 0.3,
                              ) ??
                              Colors.grey;
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Column(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? stepColor
                                          : stepColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: isDone
                                          ? null
                                          : Border.all(
                                              color: stepColor,
                                              width: 2,
                                            ),
                                    ),
                                    child: isDone
                                        ? Icon(
                                            isRejected
                                                ? Icons.close_rounded
                                                : Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 44,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      color: isDone
                                          ? stepColor.withValues(alpha: 0.4)
                                          : stepColor.withValues(alpha: 0.15),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stepName,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: isDone
                                            ? (isRejected
                                                  ? AppColors.danger
                                                  : textTheme
                                                        .titleMedium
                                                        ?.color)
                                            : textTheme.bodySmall?.color,
                                        fontWeight: isDone
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    if (stepDate.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 13,
                                            color: isDone
                                                ? stepColor
                                                : (isDark
                                                      ? AppColors.darkSubtext
                                                      : AppColors.lightSubtext),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              stepTime.isNotEmpty
                                                  ? '$stepDate at $stepTime'
                                                  : stepDate,
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isDone
                                                        ? stepColor
                                                        : null,
                                                    fontWeight: isDone
                                                        ? FontWeight.w500
                                                        : FontWeight.w400,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (isRejected &&
                                        isDone &&
                                        step['reason'] != null) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.danger.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          step['reason'] as String,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 420.ms, delay: 160.ms)
                .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: 160.ms,
                  curve: Curves.easeOutCubic,
                ),

            // ── Actions Section ──────────────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 24),

              // Manager/HR viewing employee request: Approve / Reject
              if (isManagerViewingEmployee) ...[
                if (isApplePlatform)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            onPressed: _isProcessing
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    _handleAction(approve: false);
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  CupertinoIcons.xmark,
                                  size: 16,
                                  color: AppColors.danger,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Reject',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(14),
                            onPressed: _isProcessing
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    _handleAction(approve: true);
                                  },
                            child: _isProcessing
                                ? const CupertinoActivityIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        CupertinoIcons.checkmark_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Approve',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    _handleAction(approve: false);
                                  },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text(
                              'Reject',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: BorderSide(
                                color: AppColors.danger.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    _handleAction(approve: true);
                                  },
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              'Approve',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ]
              // Employee viewing own request: Cancel button
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: isApplePlatform
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final confirmed = await showAdaptiveConfirmDialog(
                              context: context,
                              title: 'Cancel Request?',
                              content:
                                  'Are you sure you want to cancel this request? This action cannot be undone.',
                              cancelText: 'No, Keep It',
                              confirmText: 'Yes, Cancel',
                              isDestructive: true,
                            );
                            if (confirmed == true && context.mounted) {
                              Navigator.pop(context);
                              showErrorSnackbar(context, 'Request cancelled');
                            }
                          },
                          child: const Text(
                            'Cancel Request',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showAdaptiveConfirmDialog(
                              context: context,
                              title: 'Cancel Request?',
                              content:
                                  'Are you sure you want to cancel this request? This action cannot be undone.',
                              cancelText: 'No, Keep It',
                              confirmText: 'Yes, Cancel',
                              isDestructive: true,
                            );
                            if (confirmed == true && context.mounted) {
                              Navigator.pop(context);
                              showErrorSnackbar(context, 'Request cancelled');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Cancel Request',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildDefaultTimeline(
    String status,
    String appliedDate,
    Map<String, dynamic> data,
  ) {
    final now = DateTime.now();
    final submittedDate = DateFormat('dd MMM yyyy').format(now);
    final submittedTime = DateFormat('hh:mm a').format(now);

    if (status == 'Accepted') {
      final approveDate = DateFormat(
        'dd MMM yyyy',
      ).format(now.subtract(const Duration(hours: 1)));
      final approveTime = DateFormat(
        'hh:mm a',
      ).format(now.subtract(const Duration(hours: 1)));
      return [
        {
          'step': 'Submitted',
          'date': submittedDate,
          'time': submittedTime,
          'done': true,
        },
        {
          'step': 'Approved',
          'date': approveDate,
          'time': approveTime,
          'done': true,
        },
      ];
    } else if (status == 'Rejected') {
      final rejectDate = DateFormat(
        'dd MMM yyyy',
      ).format(now.subtract(const Duration(hours: 1)));
      final rejectTime = DateFormat(
        'hh:mm a',
      ).format(now.subtract(const Duration(hours: 1)));
      return [
        {
          'step': 'Submitted',
          'date': submittedDate,
          'time': submittedTime,
          'done': true,
        },
        {
          'step': 'Rejected',
          'date': rejectDate,
          'time': rejectTime,
          'done': true,
          'reason':
              data['rejectionReason'] as String? ??
              'Request did not meet the criteria.',
        },
      ];
    } else {
      return [
        {
          'step': 'Submitted',
          'date': submittedDate,
          'time': submittedTime,
          'done': true,
        },
        {'step': 'Pending Approval', 'date': '', 'time': '', 'done': false},
      ];
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Preview / open-link tile for an uploaded attachment.
///
/// Shows an inline image thumbnail when the file is an image (jpg/png/webp),
/// otherwise shows a generic file chip with the filename. Tapping launches
/// the URL in the system browser/PDF viewer.
class _AttachmentPreview extends StatelessWidget {
  final String path;
  const _AttachmentPreview({required this.path});

  String get _filename => path.split('/').last;
  bool get _isImage {
    final lower = _filename.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  String get _fullUrl {
    // ApiService.baseUrl ends in `/v1`. Strip it for the media root.
    final base = ApiService.baseUrl.replaceAll(RegExp(r'/v1/?$'), '');
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '$base/media/$clean';
  }

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(_fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      showErrorSnackbar(context, 'Could not open: $_filename');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachment',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(12),
          child: _isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _fullUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fileChip(theme, isDark),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : _loadingChip(isDark),
                  ),
                )
              : _fileChip(theme, isDark),
        ),
      ],
    );
  }

  Widget _loadingChip(bool isDark) => Container(
    height: 180,
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: isApplePlatform
          ? const CupertinoActivityIndicator()
          : const CircularProgressIndicator(color: AppColors.primary),
    ),
  );

  Widget _fileChip(ThemeData theme, bool isDark) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.30),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
          ),
          child: const Icon(
            Icons.attach_file_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _filename,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(
          Icons.open_in_new_rounded,
          color: AppColors.primary,
          size: 18,
        ),
      ],
    ),
  );
}
