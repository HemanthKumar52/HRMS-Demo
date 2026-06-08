import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import '../directory/directory_screen.dart';
import '../manager/analytics_screen.dart';
import '../manager/my_team_screen.dart';
import '../settings/settings_screen.dart';
import '../dashboard/org_chart_screen.dart';
import '../../animations/motion.dart';

void showProfileSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  if (isApplePlatform) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => const _ProfileSheet(),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfileSheet(),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2030) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Profile image with camera overlay
              Center(
                child: Stack(
                  children: [
                    _buildAvatar(provider, theme, 48),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Image picker coming soon'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // User name
              Center(
                child: Text(
                  provider.userName,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),

              // Designation
              Center(
                child: Text(
                  provider.designation,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 4),

              // Employee ID
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    provider.employeeId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Subscription plan tag (mirrors the web profile's "Growth · Active").
              _SubscriptionCard(isDark: isDark),

              const SizedBox(height: 16),

              // Menu items
              _MenuItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    Motion.pageRoute(const ProfileScreen()),
                  );
                },
              ),
              if (provider.role == UserRole.manager ||
                  provider.role == UserRole.hr ||
                  provider.role == UserRole.admin)
                _MenuItem(
                  icon: Icons.groups_outlined,
                  label: 'Workforce',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      Motion.pageRoute(const MyTeamScreen()),
                    );
                  },
                ),
              _MenuItem(
                icon: Icons.people_outline_rounded,
                label: 'Directory',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    Motion.pageRoute(const DirectoryScreen()),
                  );
                },
              ),
              if (provider.role == UserRole.admin)
                _MenuItem(
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      Motion.pageRoute(const AnalyticsScreen()),
                    );
                  },
                ),
              // Org Chart removed — accessible from dashboard
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    Motion.pageRoute(const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  provider.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    Motion.pageRoute(const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildAvatar(AppProvider provider, ThemeData theme, double radius) {
  final avatarUrl = provider.userProfile['avatar_url'] as String?;
  final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
  final initials = provider.userName
      .split(' ')
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join();

  if (hasAvatar) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(avatarUrl),
      onBackgroundImageError: (_, __) {},
      child: null,
    );
  }
  return CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
    child: Text(
      initials,
      style: theme.textTheme.headlineLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: radius * 0.6,
      ),
    ),
  );
}

/// Shows the company's current billing plan + status, like the web profile.
/// Silently renders nothing if there's no subscription or the call fails.
class _SubscriptionCard extends StatelessWidget {
  final bool isDark;
  const _SubscriptionCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getSubscription(),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null || data['has_subscription'] != true) {
          return const SizedBox.shrink();
        }
        final plan = (data['plan'] ?? '').toString();
        final status = (data['status'] ?? '').toString();
        final active = data['active'] == true;
        if (plan.isEmpty) return const SizedBox.shrink();

        final statusColor = active ? AppColors.success : Colors.orange;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.primary.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      AppColors.primary.withValues(alpha: 0.06),
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.24),
                      AppColors.primary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUBSCRIPTION',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    // Bordered pill, like the Comp Off tag on requests.
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemColor = color ?? theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (color ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: itemColor, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: itemColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  isApplePlatform
                      ? CupertinoIcons.chevron_forward
                      : Icons.chevron_right_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
