// Round 4 admin sub-screens — Login telemetry + IP allowlist.
//
// • AdminAllowedIpsScreen     — CRUD admin-managed login allowlist
// • AdminLoginRecordsScreen   — read-only feed of every login attempt with
//                                lat/lng + reverse-geocoded location + device + IP

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';

// ──────────────────────────────────────────────────────────────────────────
// 1. ALLOWED IP — CRUD
// ──────────────────────────────────────────────────────────────────────────
class AdminAllowedIpsScreen extends StatefulWidget {
  const AdminAllowedIpsScreen({super.key});

  @override
  State<AdminAllowedIpsScreen> createState() => _AdminAllowedIpsScreenState();
}

class _AdminAllowedIpsScreenState extends State<AdminAllowedIpsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _callerIp = '';

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
      final r = await ApiService.getAdminAllowedIps();
      _items = List<Map<String, dynamic>>.from(r['items'] ?? const []);
      _callerIp = r['caller_ip']?.toString() ?? '';
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editor({Map<String, dynamic>? existing}) async {
    final result = await (isApplePlatform
        ? showCupertinoDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) =>
                _IpEditor(existing: existing, callerIp: _callerIp),
          )
        : showDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) =>
                _IpEditor(existing: existing, callerIp: _callerIp),
          ));
    if (result == null) return;
    try {
      if (existing == null) {
        await ApiService.createAdminAllowedIp(result);
      } else {
        await ApiService.updateAdminAllowedIp(
          (existing['id'] as num).toInt(),
          result,
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> r, bool active) async {
    try {
      await ApiService.updateAdminAllowedIp(
        (r['id'] as num).toInt(),
        {'is_active': active},
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final ok = await (isApplePlatform
        ? showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Remove allowlist entry?'),
              content: Text(
                '${r['label']} (${r['cidr']}) will no longer be permitted.',
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          )
        : showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove allowlist entry?'),
              content: Text(
                '${r['label']} (${r['cidr']}) will no longer be permitted.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ));
    if (ok != true) return;
    try {
      await ApiService.deleteAdminAllowedIp((r['id'] as num).toInt());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = _items
        .where((r) => (r['is_active'] ?? false) as bool)
        .length;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('IP Allowlist'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Status banner
                  NeuCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                                (activeCount > 0
                                        ? AppColors.success
                                        : AppColors.warning)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            activeCount > 0
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            color: activeCount > 0
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeCount > 0
                                    ? 'IP allowlist enforced'
                                    : 'Allowlist not enforced',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                activeCount > 0
                                    ? '$activeCount active rule(s) — only matching IPs can log in.'
                                    : 'No active rules. All IPs can log in. Add a rule to enforce.',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (_callerIp.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Your IP: $_callerIp',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'No allowlist entries yet — tap + to add one',
                        ),
                      ),
                    ),
                  for (final r in _items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeuCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: ((r['is_active'] ?? false) as bool)
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lan_rounded,
                                color: ((r['is_active'] ?? false) as bool)
                                    ? AppColors.success
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r['label']}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${r['cidr']}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: (r['is_active'] ?? false) as bool,
                              activeColor: AppColors.success,
                              onChanged: (v) => _toggleActive(r, v),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                              ),
                              onSelected: (action) {
                                if (action == 'edit') _editor(existing: r);
                                if (action == 'delete') _delete(r);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _editor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Rule'),
      ),
    );
  }
}

class _IpEditor extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String callerIp;
  const _IpEditor({this.existing, required this.callerIp});

  @override
  State<_IpEditor> createState() => _IpEditorState();
}

class _IpEditorState extends State<_IpEditor> {
  late final _label = TextEditingController(
    text: widget.existing?['label']?.toString() ?? '',
  );
  late final _cidr = TextEditingController(
    text: widget.existing?['cidr']?.toString() ?? '',
  );
  late bool _active = (widget.existing?['is_active'] as bool?) ?? true;

  @override
  void dispose() {
    _label.dispose();
    _cidr.dispose();
    super.dispose();
  }

  void _submit() {
    if (_cidr.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CIDR required')));
      return;
    }
    Navigator.pop(context, {
      'label': _label.text.trim(),
      'cidr': _cidr.text.trim(),
      'is_active': _active,
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.existing == null ? 'New allowlist rule' : 'Edit rule';

    final formFields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isApplePlatform)
          CupertinoTextField(
            controller: _label,
            placeholder: 'Label (e.g. Office WiFi)',
            padding: const EdgeInsets.all(12),
          )
        else
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Label (e.g. Office WiFi)',
            ),
          ),
        const SizedBox(height: 10),
        if (isApplePlatform)
          CupertinoTextField(
            controller: _cidr,
            placeholder: 'IP / CIDR  (e.g. 203.0.113.0/24)',
            keyboardType: TextInputType.url,
            padding: const EdgeInsets.all(12),
          )
        else
          TextField(
            controller: _cidr,
            decoration: const InputDecoration(
              labelText: 'IP / CIDR',
              hintText: '203.0.113.42  or  203.0.113.0/24',
            ),
            keyboardType: TextInputType.url,
          ),
        if (widget.callerIp.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: isApplePlatform
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        setState(() => _cidr.text = widget.callerIp),
                    child: Text(
                      'Use my current IP (${widget.callerIp})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: Text('Use my current IP (${widget.callerIp})'),
                    onPressed: () =>
                        setState(() => _cidr.text = widget.callerIp),
                  ),
          ),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          title: const Text('Active'),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
          contentPadding: EdgeInsets.zero,
        ),
        const Text(
          'WARNING: enabling enforcement will block any account that '
          'tries to log in from outside this allowlist.',
          style: TextStyle(color: AppColors.danger, fontSize: 12),
        ),
      ],
    );

    if (isApplePlatform) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: formFields,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: _submit,
            child: const Text('Submit'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: formFields),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 2. LOGIN RECORDS — read-only paginated feed
// ──────────────────────────────────────────────────────────────────────────
class AdminLoginRecordsScreen extends StatefulWidget {
  const AdminLoginRecordsScreen({super.key});

  @override
  State<AdminLoginRecordsScreen> createState() =>
      _AdminLoginRecordsScreenState();
}

class _AdminLoginRecordsScreenState extends State<AdminLoginRecordsScreen> {
  static const _pageSize = 50;
  bool _loading = true;
  String? _error;
  int _total = 0;
  int _offset = 0;
  final List<Map<String, dynamic>> _items = [];
  Timer? _pollTimer;

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
      final r = await ApiService.getAdminLoginRecords(
        limit: _pageSize,
        offset: _offset,
      );
      _total = (r['total'] ?? 0) as int;
      _items.addAll(List<Map<String, dynamic>>.from(r['items'] ?? const []));
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Login Records'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : () => _load(reset: true),
          ),
        ],
      ),
      body: _items.isEmpty && _loading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _load(reset: true),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification &&
                      n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                      _items.length < _total &&
                      !_loading) {
                    _offset += _pageSize;
                    _load();
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == _items.length) {
                      if (_items.length >= _total) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    final r = _items[i];
                    return _LoginRow(row: r);
                  },
                ),
              ),
            ),
    );
  }
}

class _LoginRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _LoginRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ts = row['created_at']?.toString();
    String when = '';
    if (ts != null) {
      try {
        when = DateFormat(
          'dd MMM, hh:mm a',
        ).format(DateTime.parse(ts).toLocal());
      } catch (_) {
        when = ts;
      }
    }
    final hasLoc = row['lat'] != null && row['lng'] != null;
    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ((row['success'] ?? true) as bool)
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              ((row['success'] ?? true) as bool)
                  ? Icons.login_rounded
                  : Icons.do_disturb_alt_rounded,
              color: ((row['success'] ?? true) as bool)
                  ? AppColors.success
                  : AppColors.danger,
              size: 20,
            ),
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
                        row['user_name']?.toString() ?? 'unknown',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(when, style: theme.textTheme.bodySmall),
                  ],
                ),
                if ((row['role'] ?? '').toString().isNotEmpty)
                  Text(
                    'role: ${row['role']}',
                    style: theme.textTheme.bodySmall,
                  ),
                if (row['ip_address'] != null)
                  Text(
                    'ip: ${row['ip_address']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (hasLoc)
                  Text(
                    '${(row['lat'] as num).toStringAsFixed(4)}, ${(row['lng'] as num).toStringAsFixed(4)}'
                    "${row['location_name'] != null && row['location_name'].toString().isNotEmpty ? '  ·  ${row['location_name']}' : ''}",
                    style: theme.textTheme.bodySmall,
                  ),
                if ((row['device_info'] ?? '').toString().isNotEmpty)
                  Text(
                    'device: ${row['device_info']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
