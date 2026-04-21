import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';

/// Timeline-style audit log — grouped by date (Today, Yesterday, older).
/// Tap any entry to see full details on a separate page.
/// Filter icon at top for action type filtering.
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  static const _pageSize = 50;
  bool _loading = true;
  String? _error;
  int _total = 0;
  int _offset = 0;
  String? _actionFilter;
  final List<Map<String, dynamic>> _items = [];
  Timer? _pollTimer;

  static const _filters = [
    'All',
    'request_approved',
    'request_rejected',
    'face_punch_in_succeeded',
    'face_punch_in_failed',
    'face_punch_in_mismatch',
    'timesheet_submitted',
    'login_success',
    'login_failed',
  ];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _offset == 0) _load(reset: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _offset = 0;
      }
    });
    try {
      final resp = await ApiService.getAdminAuditLogs(
        limit: _pageSize,
        offset: _offset,
        action: _actionFilter,
      );
      if (!mounted) return;
      setState(() {
        _total = (resp['total'] ?? 0) as int;
        _items.addAll(
          List<Map<String, dynamic>>.from(resp['items'] ?? const []),
        );
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

  Future<void> _loadMore() async {
    if (_loading || _items.length >= _total) return;
    _offset += _pageSize;
    await _load();
  }

  /// Group items by date label: Today, Yesterday, or formatted date.
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    for (final item in _items) {
      final ts = item['created_at']?.toString() ?? '';
      final dateStr = ts.length >= 10 ? ts.substring(0, 10) : '';
      String label;
      if (dateStr == today) {
        label = 'Today';
      } else if (dateStr == yesterday) {
        label = 'Yesterday';
      } else {
        try {
          label = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
        } catch (_) {
          label = dateStr;
        }
      }
      map.putIfAbsent(label, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top bar: filter + refresh
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Text(
                  '${_items.length} of $_total entries',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Badge(
                    isLabelVisible: _actionFilter != null,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.filter_list_rounded),
                  ),
                  onSelected: (v) {
                    setState(() => _actionFilter = v == 'All' ? null : v);
                    _load(reset: true);
                  },
                  itemBuilder: (_) => _filters
                      .map(
                        (f) => PopupMenuItem(
                          value: f,
                          child: Row(
                            children: [
                              if ((_actionFilter == null && f == 'All') ||
                                  _actionFilter == f)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                )
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              Text(_humanAction(f)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : () => _load(reset: true),
                ),
              ],
            ),
          ),

          // Timeline list
          Expanded(
            child: _items.isEmpty && _loading
                ? Center(
                    child: isApplePlatform
                        ? const CupertinoActivityIndicator(radius: 14)
                        : const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification &&
                          n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _load(reset: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _buildListItems(grouped).length,
                        itemBuilder: (ctx, i) => _buildListItems(grouped)[i],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListItems(
    Map<String, List<Map<String, dynamic>>> grouped,
  ) {
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      // Date header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            entry.key,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
      // Timeline items
      for (var i = 0; i < entry.value.length; i++) {
        final item = entry.value[i];
        final isLast = i == entry.value.length - 1;
        widgets.add(
          _TimelineItem(
            item: item,
            isLast: isLast,
            onTap: () => _openDetail(item),
          ),
        );
      }
    }
    // Load more indicator
    if (_items.length < _total) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: isApplePlatform
                ? const CupertinoActivityIndicator(radius: 14)
                : const CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }
    return widgets;
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _AuditDetailPage(item: item)),
    );
  }

  String _humanAction(String a) {
    switch (a) {
      case 'All':
        return 'All';
      case 'request_approved':
        return 'Approved';
      case 'request_rejected':
        return 'Rejected';
      case 'face_punch_in_succeeded':
        return 'Face OK';
      case 'face_punch_in_failed':
        return 'Face Fail';
      case 'face_punch_in_mismatch':
        return 'Face Mismatch';
      case 'timesheet_submitted':
        return 'Timesheet';
      case 'login_success':
        return 'Login OK';
      case 'login_failed':
        return 'Login Fail';
      default:
        return a.replaceAll('_', ' ');
    }
  }
}

// ── Timeline Item ───────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  final VoidCallback onTap;
  const _TimelineItem({
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = item['action']?.toString() ?? '';
    final actor = item['actor_name']?.toString() ?? '—';
    final target = item['target_name']?.toString() ?? '';
    final ts = item['created_at']?.toString() ?? '';
    final time = ts.length >= 16 ? ts.substring(11, 16) : '';

    final color = _actionColor(action);
    final icon = _actionIcon(action);

    return GestureDetector(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + dot
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _humanAction(action),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            actor,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (target.isNotEmpty)
                            Text(
                              '→ $target',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _humanAction(String a) {
    switch (a) {
      case 'request_approved':
        return 'Request Approved';
      case 'request_rejected':
        return 'Request Rejected';
      case 'face_punch_in_succeeded':
        return 'Face Check-in OK';
      case 'face_punch_in_failed':
        return 'Face Check-in Failed';
      case 'face_punch_in_mismatch':
        return 'Face Mismatch';
      case 'timesheet_submitted':
        return 'Timesheet Submitted';
      case 'login_success':
        return 'Login';
      case 'login_failed':
        return 'Login Failed';
      default:
        return a
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
            .join(' ');
    }
  }

  Color _actionColor(String a) {
    if (a.contains('approved') ||
        a.contains('succeeded') ||
        a.contains('success'))
      return AppColors.success;
    if (a.contains('rejected') ||
        a.contains('failed') ||
        a.contains('mismatch'))
      return AppColors.danger;
    if (a.contains('submitted')) return AppColors.warning;
    return AppColors.primary;
  }

  IconData _actionIcon(String a) {
    if (a.contains('approved')) return Icons.check_circle_outline;
    if (a.contains('rejected')) return Icons.cancel_outlined;
    if (a.contains('face')) return Icons.face;
    if (a.contains('login')) return Icons.login;
    if (a.contains('timesheet')) return Icons.assignment;
    return Icons.history;
  }
}

// ── Detail Page ─────────────────────────────────────────────────────────────

class _AuditDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AuditDetailPage({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final action = item['action']?.toString() ?? '';
    final actor = item['actor_name']?.toString() ?? '—';
    final actorRole = item['actor_role']?.toString() ?? '';
    final target = item['target_name']?.toString() ?? '—';
    final targetType = item['target_type']?.toString() ?? '';
    final ip = item['ip_address']?.toString() ?? '';
    final ua = item['user_agent']?.toString() ?? '';
    final ts = item['created_at']?.toString() ?? '';
    final payload = item['payload'];

    String prettyPayload = '';
    if (payload != null) {
      try {
        if (payload is Map || payload is List) {
          prettyPayload = const JsonEncoder.withIndent('  ').convert(payload);
        } else {
          prettyPayload = payload.toString();
        }
      } catch (_) {
        prettyPayload = payload.toString();
      }
    }

    String formattedTime = ts;
    try {
      final dt = DateTime.parse(ts).toLocal();
      formattedTime = DateFormat('EEEE, dd MMM yyyy · hh:mm:ss a').format(dt);
    } catch (_) {}

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Audit Detail',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Action badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _color(action).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                action.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: _color(action),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              formattedTime,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),

          _DetailSection(
            label: 'Actor',
            children: [
              _DetailRow(label: 'Name', value: actor),
              if (actorRole.isNotEmpty)
                _DetailRow(label: 'Role', value: actorRole),
            ],
          ),

          _DetailSection(
            label: 'Target',
            children: [
              _DetailRow(label: 'Name', value: target),
              if (targetType.isNotEmpty)
                _DetailRow(label: 'Type', value: targetType),
            ],
          ),

          _DetailSection(
            label: 'Network',
            children: [
              if (ip.isNotEmpty) _DetailRow(label: 'IP Address', value: ip),
              if (ua.isNotEmpty) _DetailRow(label: 'User Agent', value: ua),
            ],
          ),

          if (prettyPayload.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Payload',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: prettyPayload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payload copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF5F5F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                prettyPayload,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _color(String a) {
    if (a.contains('approved') ||
        a.contains('succeeded') ||
        a.contains('success'))
      return AppColors.success;
    if (a.contains('rejected') ||
        a.contains('failed') ||
        a.contains('mismatch'))
      return AppColors.danger;
    return AppColors.primary;
  }
}

class _DetailSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _DetailSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
