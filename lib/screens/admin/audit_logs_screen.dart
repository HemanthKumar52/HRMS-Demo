import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

/// Admin-only paginated audit log feed.
///
/// Lists every security-relevant event recorded by the backend (request
/// approve / reject, face check-in success / fail / mismatch, etc.) with
/// actor, target, IP, and a JSON payload preview.
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

  static const _actionFilters = <String>[
    'All',
    'request_approved',
    'request_rejected',
    'face_punch_in_succeeded',
    'face_punch_in_failed',
    'face_punch_in_mismatch',
  ];

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    // Background poll — refresh the first page silently every 30s.
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

  /// Open the audit-log CSV export URL in the system browser. Honors the
  /// active chip filter so the download matches what the user is viewing.
  Future<void> _exportCsv() async {
    final url = Uri.parse(
      ApiService.adminAuditLogsExportUrl(action: _actionFilter),
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _actionFilter == null
                ? 'Exporting all audit logs…'
                : 'Exporting "${_actionFilter!}" rows…',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open browser'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Inline action bar (no AppBar — parent Admin Panel has one).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: _actionFilter == null
                      ? 'Export all audit logs as CSV'
                      : 'Export "${_actionFilter!}" rows as CSV',
                  onPressed: _exportCsv,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loading ? null : () => _load(reset: true),
                ),
              ],
            ),
          ),
          // Action filter chips.
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _actionFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _actionFilters[i];
                final selected =
                    (f == 'All' && _actionFilter == null) || f == _actionFilter;
                return ChoiceChip(
                  label: Text(_humanAction(f)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _actionFilter = f == 'All' ? null : f);
                    _load(reset: true);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.18),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _items.isEmpty && _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                ? _ErrorView(
                    message: _error!,
                    onRetry: () => _load(reset: true),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _load(reset: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification &&
                            n.metrics.pixels >=
                                n.metrics.maxScrollExtent - 200) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          if (index == _items.length) {
                            if (_items.length >= _total) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_items.length} of $_total',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              );
                            }
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }
                          return _AuditRow(row: _items[index]);
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
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
    default:
      return a.replaceAll('_', ' ');
  }
}

Color _actionColor(String a) {
  switch (a) {
    case 'request_approved':
    case 'face_punch_in_succeeded':
      return AppColors.success;
    case 'request_rejected':
    case 'face_punch_in_failed':
    case 'face_punch_in_mismatch':
      return AppColors.danger;
    default:
      return AppColors.primary;
  }
}

IconData _actionIcon(String a) {
  switch (a) {
    case 'request_approved':
      return Icons.check_circle_rounded;
    case 'request_rejected':
      return Icons.cancel_rounded;
    case 'face_punch_in_succeeded':
      return Icons.verified_user_rounded;
    case 'face_punch_in_failed':
      return Icons.no_accounts_rounded;
    case 'face_punch_in_mismatch':
      return Icons.warning_amber_rounded;
    default:
      return Icons.history_edu_rounded;
  }
}

class _AuditRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _AuditRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = (row['action'] ?? '').toString();
    final color = _actionColor(action);
    final icon = _actionIcon(action);
    final actor = (row['actor_name'] ?? 'system').toString();
    final actorRole = (row['actor_role'] ?? '').toString();
    final target = (row['target_name'] ?? '').toString();
    final ts = row['created_at']?.toString();
    String when = '';
    if (ts != null && ts.isNotEmpty) {
      try {
        when = DateFormat(
          'dd MMM, hh:mm a',
        ).format(DateTime.parse(ts).toLocal());
      } catch (_) {
        when = ts;
      }
    }
    final payload = (row['payload'] ?? const {}) as Map;
    final payloadText = payload.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(' · ');

    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _humanAction(action),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(when, style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$actor${actorRole.isNotEmpty ? " · $actorRole" : ""}'
                  '${target.isNotEmpty ? " → $target" : ""}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (payloadText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payloadText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

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
              'Could not load audit logs',
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
