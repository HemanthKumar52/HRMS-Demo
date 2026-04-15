import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import 'admin_command_center_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';
import 'audit_logs_screen.dart';

/// Full-screen admin panel — opened from the dashboard when an admin
/// taps the "Admin Panel" card.
///
/// Mirrors the web-app pattern: the admin is still an employee who can
/// punch-in, apply for leave, etc.  This panel is the "switch to admin
/// view" equivalent, housing Organisation-wide tools in their own
/// tab navigator so the employee shell stays untouched.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _index = 0;

  static const _screens = <Widget>[
    AdminCommandCenterScreen(),
    AdminUsersScreen(),
    AuditLogsScreen(),
    AdminSettingsScreen(),
  ];

  static const _labels = ['Overview', 'Users', 'Audit', 'Settings'];

  static const _icons = <IconData>[
    Icons.shield_moon_outlined,
    Icons.group_outlined,
    Icons.history_edu_outlined,
    Icons.tune_rounded,
  ];

  static const _cupertinoIcons = <IconData>[
    CupertinoIcons.shield_lefthalf_fill,
    CupertinoIcons.person_2_fill,
    CupertinoIcons.doc_text_fill,
    CupertinoIcons.gear_alt_fill,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isApplePlatform ? CupertinoIcons.back : Icons.arrow_back,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: isApplePlatform
          ? CupertinoTabBar(
              currentIndex: _index,
              onTap: _onTap,
              activeColor: AppColors.primary,
              inactiveColor: CupertinoColors.systemGrey,
              backgroundColor: isDark
                  ? AppColors.darkBg.withValues(alpha: 0.9)
                  : AppColors.lightBg.withValues(alpha: 0.9),
              items: List.generate(
                _labels.length,
                (i) => BottomNavigationBarItem(
                  icon: Icon(_cupertinoIcons[i]),
                  label: _labels[i],
                ),
              ),
            )
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _onTap,
              backgroundColor: isDark
                  ? const Color(0xFF1E2030)
                  : const Color(0xFFE4E8EE),
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              destinations: List.generate(
                _labels.length,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i]),
                  selectedIcon: Icon(_icons[i], color: AppColors.primary),
                  label: _labels[i],
                ),
              ),
            ),
    );
  }

  void _onTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }
}
