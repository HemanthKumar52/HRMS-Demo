import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/dynamic_island.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'requests/requests_screen.dart';
import 'attendance/attendance_screen.dart';
import 'payslip/payslip_screen.dart';
import 'profile/profile_sheet.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Unified screens for all roles
    const screens = <Widget>[
      DashboardScreen(),
      RequestsScreen(),
      AttendanceScreen(),
      PayslipScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PPulse HRMS',
              style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              provider.role == UserRole.hr
                  ? 'HR PORTAL'
                  : provider.role == UserRole.manager
                      ? 'MANAGER PORTAL'
                      : 'EMPLOYEE PORTAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          // Notification bell with red dot badge
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => _showNotifications(context),
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
                    const Icon(Icons.notifications_outlined, size: 22),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1A1B2E) : const Color(0xFFE4E8EE),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => showProfileSheet(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
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
                child: Center(
                  child: Text(
                    provider.userName.isNotEmpty ? provider.userName[0] : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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

  void _showNotifications(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('All notifications marked as read'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Alerts
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Alerts', style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                      letterSpacing: 0.5,
                    )),
                  ),
                  _NotifItem(
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    title: 'Leave Approved',
                    subtitle: 'Your leave request for Mar 20 has been approved',
                    time: '2 min ago',
                  ),
                  _NotifItem(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    title: 'Low Leave Balance',
                    subtitle: 'You have only 2 casual leaves remaining',
                    time: '30 min ago',
                  ),
                  // Updates
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Text('Updates', style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    )),
                  ),
                  _NotifItem(
                    icon: Icons.schedule,
                    color: AppColors.warning,
                    title: 'Shift Updated',
                    subtitle: 'Your shift for next week has been updated',
                    time: '3 hours ago',
                  ),
                  _NotifItem(
                    icon: Icons.receipt_long,
                    color: AppColors.secondary,
                    title: 'Payslip Available',
                    subtitle: 'Your February payslip is ready to view',
                    time: 'Yesterday',
                  ),
                  // Announcements
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Text('Announcements', style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                      letterSpacing: 0.5,
                    )),
                  ),
                  _NotifItem(
                    icon: Icons.campaign,
                    color: AppColors.orange,
                    title: 'Company Town Hall',
                    subtitle: 'Scheduled for March 15, 2026 at 3:00 PM',
                    time: '1 hour ago',
                  ),
                  _NotifItem(
                    icon: Icons.policy_rounded,
                    color: AppColors.primary,
                    title: 'New Leave Policy Update',
                    subtitle: 'Effective from April 1, 2026',
                    time: '2 days ago',
                  ),
                  _NotifItem(
                    icon: Icons.assessment_rounded,
                    color: AppColors.secondary,
                    title: 'Quarterly Review Deadline',
                    subtitle: 'Submit reviews by March 25, 2026',
                    time: '3 days ago',
                  ),
                ],
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

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
