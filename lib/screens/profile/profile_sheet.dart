import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../providers/app_provider.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import '../directory/directory_screen.dart';
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
              const SizedBox(height: 28),

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
                  icon: Icons.group_outlined,
                  label: 'My Team',
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
              // Analytics removed per manager feedback
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
