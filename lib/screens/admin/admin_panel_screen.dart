import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/adaptive_colors.dart';
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

    if (isApplePlatform) {
      return _buildIOSLayout(context, isDark);
    }
    return _buildAndroidLayout(context, isDark);
  }

  Widget _buildIOSLayout(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          onPressed: () => Navigator.pop(context),
                          child: Icon(
                            CupertinoIcons.back,
                            color: AdaptiveColors.primary(context),
                            size: 22,
                          ),
                        ),
                        Text(
                          _labels[_index],
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
                ),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
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
                  children: List.generate(_labels.length, (i) {
                    final isActive = _index == i;
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _onTap(i),
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _cupertinoIcons[i],
                              size: 22,
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.grey.shade500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _labels[i],
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

  Widget _buildAndroidLayout(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _labels[_index],
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
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
