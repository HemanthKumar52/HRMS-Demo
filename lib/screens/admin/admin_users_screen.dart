import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../utils/responsive.dart';
import '../../widgets/neu_card.dart';

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

  Future<void> _action(int userId, String action) async {
    try {
      await ApiService.adminUserAction(userId, action);
      if (!mounted) return;
      _snack('$action completed', AppColors.success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', AppColors.danger);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openActions(Map<String, dynamic> user) {
    final name = (user['name'] ?? '—').toString();
    final isActive = user['is_active'] == true;
    final userId = ((user['id'] ?? 0) as num).toInt();

    HapticFeedback.lightImpact();

    if (isApplePlatform) {
      showAdaptiveActionSheet(
        context: context,
        title: name,
        actions: [
          AdaptiveAction(
            label: isActive ? 'Disable Account' : 'Enable Account',
            isDestructive: isActive,
            onPressed: () => _action(userId, isActive ? 'disable' : 'enable'),
          ),
          AdaptiveAction(
            label: 'Force Logout',
            onPressed: () => _action(userId, 'force-logout'),
          ),
          AdaptiveAction(
            label: 'Send Password Reset',
            onPressed: () => _action(userId, 'reset-password'),
          ),
        ],
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: isActive ? Icons.lock_outline : Icons.lock_open_outlined,
              label: isActive ? 'Disable Account' : 'Enable Account',
              color: isActive ? AppColors.danger : AppColors.success,
              onTap: () {
                Navigator.pop(ctx);
                _action(userId, isActive ? 'disable' : 'enable');
              },
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              label: 'Force Logout',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(ctx);
                _action(userId, 'force-logout');
              },
            ),
            _ActionTile(
              icon: Icons.lock_reset_rounded,
              label: 'Send Password Reset',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                _action(userId, 'reset-password');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: [
              // Search + filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => _search = v,
                        onSubmitted: (_) => _load(),
                        decoration: InputDecoration(
                          hintText: 'Search employees...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
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
                    // Filter icon
                    PopupMenuButton<String>(
                      icon: Badge(
                        isLabelVisible: _roleFilter != 'All',
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.filter_list_rounded),
                      ),
                      onSelected: (v) {
                        setState(() => _roleFilter = v);
                        _load();
                      },
                      itemBuilder: (_) => _roles
                          .map(
                            (r) => PopupMenuItem(
                              value: r,
                              child: Row(
                                children: [
                                  if (_roleFilter == r)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    )
                                  else
                                    const SizedBox(width: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    r == 'All'
                                        ? 'All Roles'
                                        : r[0].toUpperCase() + r.substring(1),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _loading ? null : _load,
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _loading && _users.isEmpty
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
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final user = _users[i];
                            final name = (user['name'] ?? '—').toString();
                            final isOnline = user['is_online'] == true;

                            return GestureDetector(
                              onTap: () => _openActions(user),
                              child: NeuCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isOnline
                                            ? AppColors.success
                                            : Colors.grey.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
