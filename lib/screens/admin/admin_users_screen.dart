import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

/// Admin "Users" tab — list of every employee with role + status filters and
/// per-row actions (enable / disable / promote / demote / force-reset / force-logout).
///
/// Backed by `GET /v1/admin/users` and several POST endpoints under
/// `/v1/admin/users/{id}/...`. Admin-only.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  String _search = '';
  String _roleFilter = 'All';

  static const _roles = ['All', 'admin', 'hr', 'manager', 'employee'];

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
      final resp = await ApiService.getAdminUsers(
        search: _search.isEmpty ? null : _search,
        role: _roleFilter == 'All' ? null : _roleFilter,
      );
      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(resp['items'] ?? const []);
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

  Future<void> _action(
    int userId,
    String action, {
    Map<String, dynamic>? body,
  }) async {
    try {
      await ApiService.adminUserAction(userId, action, body: body);
      if (!mounted) return;
      _showSnack('$action completed', AppColors.success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed: $e', AppColors.danger);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => _search = v,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Search by name / email / badge id…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loading ? null : _load,
                  ),
                ],
              ),
            ),
            // Role chips.
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _roles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final r = _roles[i];
                  return ChoiceChip(
                    label: Text(
                      r == 'All' ? 'All' : r[0].toUpperCase() + r.substring(1),
                    ),
                    selected: _roleFilter == r,
                    onSelected: (_) {
                      setState(() => _roleFilter = r);
                      _load();
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              child: _loading && _users.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _UserRow(
                          row: _users[i],
                          onAction: (action, [body]) => _action(
                            ((_users[i]['id'] ?? 0) as num).toInt(),
                            action,
                            body: body,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final Future<void> Function(String action, [Map<String, dynamic>? body])
  onAction;

  const _UserRow({required this.row, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (row['name'] ?? '—').toString();
    final email = (row['email'] ?? '').toString();
    final role = (row['role'] ?? 'employee').toString();
    final isActive = row['is_active'] == true;
    final badge = (row['badge_id'] ?? '').toString();

    return NeuCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: _roleColor(role),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(text: role, color: _roleColor(role)),
                        _Pill(
                          text: isActive ? 'active' : 'disabled',
                          color: isActive
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        if (badge.isNotEmpty)
                          _Pill(text: badge, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) async {
                  if (v == 'enable') {
                    await onAction('enable');
                  } else if (v == 'disable') {
                    await onAction('disable');
                  } else if (v == 'force_logout') {
                    await onAction('force-logout');
                  } else if (v == 'force_reset') {
                    await onAction('reset-password');
                  } else if (v == 'promote_hr') {
                    await onAction('promote', {'role': 'hr'});
                  } else if (v == 'promote_admin') {
                    await onAction('promote', {'role': 'admin'});
                  } else if (v == 'demote_employee') {
                    await onAction('promote', {'role': 'employee'});
                  }
                },
                itemBuilder: (_) => [
                  if (isActive)
                    const PopupMenuItem(
                      value: 'disable',
                      child: ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('Disable account'),
                        dense: true,
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'enable',
                      child: ListTile(
                        leading: Icon(Icons.lock_open_outlined),
                        title: Text('Enable account'),
                        dense: true,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'force_logout',
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded),
                      title: Text('Force logout'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'force_reset',
                    child: ListTile(
                      leading: Icon(Icons.lock_reset_rounded),
                      title: Text('Send password reset'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuDivider(),
                  if (role != 'admin')
                    const PopupMenuItem(
                      value: 'promote_admin',
                      child: ListTile(
                        leading: Icon(Icons.shield_outlined),
                        title: Text('Promote to admin'),
                        dense: true,
                      ),
                    ),
                  if (role != 'hr')
                    const PopupMenuItem(
                      value: 'promote_hr',
                      child: ListTile(
                        leading: Icon(Icons.workspace_premium_outlined),
                        title: Text('Promote to HR'),
                        dense: true,
                      ),
                    ),
                  if (role != 'employee')
                    const PopupMenuItem(
                      value: 'demote_employee',
                      child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Demote to employee'),
                        dense: true,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(String r) {
    switch (r) {
      case 'admin':
        return AppColors.danger;
      case 'hr':
        return AppColors.warning;
      case 'manager':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
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
              'Could not load users',
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
