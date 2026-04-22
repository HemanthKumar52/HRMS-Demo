import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/adaptive_colors.dart';
import '../theme/app_theme.dart';
import '../utils/platform_adaptive.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/dynamic_island.dart';
import '../widgets/feedback_popup.dart';
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
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppProvider>().fetchDashboardData();
    }
    if (state == AppLifecycleState.inactive && mounted) {
      FeedbackManager.maybeShowFeedback(context);
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

      if (_lastKnownUnread >= 0) {
        for (final n in notifications) {
          final id = n['id'];
          final isRead = n['read'] == true;
          if (!isRead && id != null && !_seenNotifIds.contains(id)) {
            NotificationService.instance.show(
              title: n['title'] as String? ?? 'New Notification',
              body: n['body'] as String? ?? '',
              payload: 'notification',
            );
          }
        }
      }

      _seenNotifIds = notifications.map((n) => n['id'] as int? ?? 0).toSet();
      _lastKnownUnread = unread;

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

  // ─── iOS Shell ──────────────────────────────────────────────────────────

  Widget _buildIOSShell(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    List<Widget> screens,
  ) {
    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      // ── Liquid Glass App Bar ──
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.7),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Good ${_getGreeting()},',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AdaptiveColors.secondaryText(context),
                                ),
                              ),
                              Text(
                                provider.userName.split(' ').first,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AdaptiveColors.primaryText(context),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildIOSNotificationButton(context, provider),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => showProfileSheet(context),
                          child: _buildProfileAvatar(provider, isDark, 34),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
      // ── Liquid Glass Bottom Nav ──
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.65),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) {
                    final isActive = provider.bottomNavIndex == index;
                    final icons = [
                      CupertinoIcons.square_grid_2x2_fill,
                      CupertinoIcons.doc_text_fill,
                      CupertinoIcons.hand_raised_fill,
                      CupertinoIcons.doc_text,
                    ];
                    final labels = [
                      'Dashboard',
                      'Requests',
                      'Attendance',
                      'Payslip',
                    ];
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        provider.setBottomNavIndex(index);
                      },
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[index],
                              size: 22,
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.grey.shade500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? AppColors.primary
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.4)
                                          : Colors.grey.shade500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSNotificationButton(
    BuildContext context,
    AppProvider provider,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () {
        HapticFeedback.lightImpact();
        _showNotifications(context);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            CupertinoIcons.bell,
            color: AdaptiveColors.primaryText(context),
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
                    color: AdaptiveColors.background(context),
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
    );
  }

  // ─── Android Shell ──────────────────────────────────────────────────────

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
          decoration: isDark
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
                Icons.notifications_outlined,
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

  // ─── Shared Helpers ─────────────────────────────────────────────────────

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
        boxShadow: isDark || isApplePlatform
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
    final provider = context.read<AppProvider>();
    final notifications = provider.notifications;

    if (isApplePlatform) {
      _showIOSNotifications(context, provider, notifications);
    } else {
      _showAndroidNotifications(context, provider, notifications);
    }
  }

  void _showIOSNotifications(
    BuildContext context,
    AppProvider provider,
    List<Map<String, dynamic>> notifications,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3.resolveFrom(context),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AdaptiveColors.primaryText(context),
                    ),
                  ),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      for (var n in provider.notifications) {
                        n['read'] = true;
                      }
                      provider.updateNotifications(provider.notifications, 0);
                      ApiService.markAllNotificationsRead().catchError((_) {});
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(fontSize: 15),
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
                            CupertinoIcons.bell_slash,
                            size: 48,
                            color: CupertinoColors.systemGrey3.resolveFrom(
                              context,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: AdaptiveColors.secondaryText(context),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) => _buildNotifItem(
                        context,
                        provider,
                        notifications[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAndroidNotifications(
    BuildContext context,
    AppProvider provider,
    List<Map<String, dynamic>> notifications,
  ) {
    final theme = Theme.of(context);
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
                      for (var n in provider.notifications) {
                        n['read'] = true;
                      }
                      provider.updateNotifications(provider.notifications, 0);
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
                        itemBuilder: (context, index) => _buildNotifItem(
                          context,
                          provider,
                          notifications[index],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem(
    BuildContext context,
    AppProvider provider,
    Map<String, dynamic> n,
  ) {
    final title = n['title'] as String? ?? '';
    final body = n['body'] as String? ?? '';
    final isRead = n['read'] == true;
    final timestamp = n['timestamp'] as String?;

    IconData icon = isApplePlatform
        ? CupertinoIcons.bell
        : Icons.notifications_outlined;
    Color color = AppColors.primary;
    if (title.toLowerCase().contains('approved')) {
      icon = isApplePlatform
          ? CupertinoIcons.checkmark_circle
          : Icons.check_circle;
      color = AppColors.success;
    } else if (title.toLowerCase().contains('rejected')) {
      icon = isApplePlatform ? CupertinoIcons.xmark_circle : Icons.cancel;
      color = AppColors.danger;
    } else if (title.toLowerCase().contains('submitted') ||
        title.toLowerCase().contains('new')) {
      icon = isApplePlatform
          ? CupertinoIcons.plus_circle
          : Icons.add_circle_outline;
      color = AppColors.orange;
    } else if (title.toLowerCase().contains('leave')) {
      icon = isApplePlatform ? CupertinoIcons.calendar : Icons.event_busy;
      color = AppColors.warning;
    } else if (title.toLowerCase().contains('claim')) {
      icon = isApplePlatform ? CupertinoIcons.doc_text : Icons.receipt_long;
      color = AppColors.secondary;
    }

    String timeAgo = '';
    if (timestamp != null) {
      try {
        final dt = DateTime.parse(timestamp);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else if (diff.inDays < 7) {
          timeAgo = '${diff.inDays}d ago';
        } else {
          timeAgo = '${dt.day}/${dt.month}';
        }
      } catch (_) {}
    }

    final notifId = n['id'];
    return GestureDetector(
      onTap: () {
        if (!isRead && notifId != null) {
          final id = notifId is int
              ? notifId
              : int.tryParse(notifId.toString()) ?? 0;
          provider.markNotificationRead(id);
        }
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.04)
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
                          color: AdaptiveColors.primaryText(context),
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
                  style: TextStyle(
                    color: AdaptiveColors.secondaryText(context),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: AdaptiveColors.tertiaryText(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
