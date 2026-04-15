import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/platform_adaptive.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/dynamic_island.dart';
import '../theme/app_theme.dart';
// Admin screens are now accessed via AdminPanelScreen from the dashboard.
import 'attendance/attendance_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'payslip/payslip_screen.dart';
import 'profile/profile_sheet.dart';
import 'requests/requests_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  Timer? _pollTimer;
  int _lastKnownUnread = -1;
  Set<int> _seenNotifIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sync attendance + notifications on every app open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchDashboardData();
    });
    _checkForNewNotifications();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkForNewNotifications(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground, refresh attendance status
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppProvider>().fetchDashboardData();
    }
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      final unread = (data['unread_count'] ?? 0) as int;
      final notifications = List<Map<String, dynamic>>.from(
        ((data['notifications'] as List?) ?? []).map(
          (n) => Map<String, dynamic>.from(n),
        ),
      );

      // Fire local push for any NEW unread notifications we haven't seen
      if (_lastKnownUnread >= 0) {
        for (final n in notifications) {
          final id = n['id'];
          final isRead = n['read'] == true;
          if (!isRead && id != null && !_seenNotifIds.contains(id)) {
            // This is a new unread notification — fire push
            NotificationService.instance.show(
              title: n['title'] as String? ?? 'New Notification',
              body: n['body'] as String? ?? '',
              payload: 'notification',
            );
          }
        }
      }

      // Track all notification IDs we've seen
      _seenNotifIds = notifications.map((n) => n['id'] as int? ?? 0).toSet();
      _lastKnownUnread = unread;

      // Update provider
      if (mounted) {
        context.read<AppProvider>().updateNotifications(notifications, unread);
      }
    } catch (e) {
      debugPrint('NOTIF_POLL ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Everyone — including admin — sees the same employee shell.
    // Admin tools are accessible via the "Admin Panel" card on the dashboard.
    const screens = <Widget>[
      DashboardScreen(),
      RequestsScreen(),
      AttendanceScreen(),
      PayslipScreen(),
    ];

    if (isApplePlatform) {
      return _buildIOSShell(context, provider, isDark, screens);
    }
    return _buildAndroidShell(context, provider, isDark, screens);
  }

  Widget _buildIOSShell(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    List<Widget> screens,
  ) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Good ${_getGreeting()},',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
            Text(
              provider.userName.split(' ').first,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.lightImpact();
              _showNotifications(context);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  size: 22,
                ),
                if (provider.unreadNotifications > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBg : AppColors.lightBg,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${provider.unreadNotifications > 9 ? '9+' : provider.unreadNotifications}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => showProfileSheet(context),
              child: _buildProfileAvatar(provider, isDark, 36),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: provider.bottomNavIndex.clamp(0, screens.length - 1),
            children: screens,
          ),
          const DynamicIslandOverlay(),
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: provider.bottomNavIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          provider.setBottomNavIndex(index);
        },
        activeColor: AppColors.primary,
        inactiveColor: CupertinoColors.systemGrey,
        backgroundColor: isDark
            ? AppColors.darkBg.withValues(alpha: 0.9)
            : AppColors.lightBg.withValues(alpha: 0.9),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text_fill),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.hand_raised_fill),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.creditcard_fill),
            label: 'Payroll',
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidShell(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    List<Widget> screens,
  ) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Good ${_getGreeting()},',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
            Text(
              provider.userName.split(' ').first,
              style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          _buildNotificationButton(provider, isDark),
          // Profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => showProfileSheet(context),
              child: _buildProfileAvatar(provider, isDark, 38),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: provider.bottomNavIndex.clamp(0, screens.length - 1),
            children: screens,
          ),
          const FloatingBottomNav(),
          const DynamicIslandOverlay(),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(AppProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showNotifications(context);
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: isDark || isApplePlatform
              ? null
              : BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE4E8EE),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBEC3CE).withValues(alpha: 0.5),
                      offset: const Offset(3, 3),
                      blurRadius: 6,
                    ),
                    const BoxShadow(
                      color: Color(0xFFFDFFFF),
                      offset: Offset(-2, -2),
                      blurRadius: 6,
                    ),
                  ],
                ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isApplePlatform
                    ? CupertinoIcons.bell
                    : Icons.notifications_outlined,
                size: 22,
              ),
              if (provider.unreadNotifications > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1A1B2E)
                            : const Color(0xFFE4E8EE),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${provider.unreadNotifications > 9 ? '9+' : provider.unreadNotifications}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(AppProvider provider, bool isDark, double size) {
    final avatarUrl = provider.userProfile['avatar_url'] as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasAvatar
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD4A574), Color(0xFFA0785A)],
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFBEC3CE).withValues(alpha: 0.5),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                ),
                const BoxShadow(
                  color: Color(0xFFFDFFFF),
                  offset: Offset(-2, -2),
                  blurRadius: 6,
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarInitial(provider, size),
            )
          : _avatarInitial(provider, size),
    );
  }

  Widget _avatarInitial(AppProvider provider, double size) {
    return Center(
      child: Text(
        provider.userName.isNotEmpty ? provider.userName[0] : 'U',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.47,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _showNotifications(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();
    final notifications = provider.notifications;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Notifications', style: theme.textTheme.titleLarge),
                  if (provider.unreadNotifications > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.unreadNotifications}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Update local state first so UI updates immediately
                      for (var n in provider.notifications) {
                        n['read'] = true;
                      }
                      provider.updateNotifications(provider.notifications, 0);
                      // Then call API in background
                      ApiService.markAllNotificationsRead().catchError((_) {});
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white38
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchDashboardData(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          final title = n['title'] as String? ?? '';
                          final body = n['body'] as String? ?? '';
                          final isRead = n['read'] == true;
                          final timestamp = n['timestamp'] as String?;

                          IconData icon = Icons.notifications_outlined;
                          Color color = AppColors.primary;
                          if (title.toLowerCase().contains('approved')) {
                            icon = Icons.check_circle;
                            color = AppColors.success;
                          } else if (title.toLowerCase().contains('rejected')) {
                            icon = Icons.cancel;
                            color = AppColors.danger;
                          } else if (title.toLowerCase().contains(
                                'submitted',
                              ) ||
                              title.toLowerCase().contains('new')) {
                            icon = Icons.add_circle_outline;
                            color = AppColors.orange;
                          } else if (title.toLowerCase().contains('leave')) {
                            icon = Icons.event_busy;
                            color = AppColors.warning;
                          } else if (title.toLowerCase().contains('claim')) {
                            icon = Icons.receipt_long;
                            color = AppColors.secondary;
                          }

                          String timeAgo = '';
                          if (timestamp != null) {
                            try {
                              final dt = DateTime.parse(timestamp);
                              final diff = DateTime.now().difference(dt);
                              if (diff.inMinutes < 1)
                                timeAgo = 'Just now';
                              else if (diff.inMinutes < 60)
                                timeAgo = '${diff.inMinutes}m ago';
                              else if (diff.inHours < 24)
                                timeAgo = '${diff.inHours}h ago';
                              else if (diff.inDays < 7)
                                timeAgo = '${diff.inDays}d ago';
                              else
                                timeAgo = '${dt.day}/${dt.month}';
                            } catch (_) {}
                          }

                          final notifId = n['id'];
                          return GestureDetector(
                            onTap: () {
                              // Mark as read
                              if (!isRead && notifId != null) {
                                final id = notifId is int
                                    ? notifId
                                    : int.tryParse(notifId.toString()) ?? 0;
                                provider.markNotificationRead(id);
                              }
                              // Close bottom sheet and go to Requests tab
                              Navigator.pop(context);
                              provider.setBottomNavIndex(1);
                              provider.setRequestsTabIndex(0);
                            },
                            child: _NotifItem(
                              icon: icon,
                              color: color,
                              title: title,
                              subtitle: body,
                              time: timeAgo,
                              isUnread: !isRead,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.primary.withValues(alpha: 0.04))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isUnread
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.1))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
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
                        title,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
