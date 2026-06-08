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
                            Icons.arrow_back_ios_new_rounded,
                            color: AdaptiveColors.primary(context),
                            size: 20,
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
      // Glassy floating nav with blue blob — matches the main app + Android.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.42)
                      : Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.75),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: List.generate(_labels.length, (i) {
                    final isActive = _index == i;
                    final inactiveColor = isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.45);
                    final itemColor = isActive
                        ? AppColors.primary
                        : inactiveColor;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onTap(i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: isActive
                              ? ShapeDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withValues(
                                        alpha: 0.34,
                                      ),
                                      AppColors.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                    ],
                                  ),
                                  shape: const StadiumBorder(),
                                  shadows: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                )
                              : null,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _cupertinoIcons[i],
                                  color: itemColor,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _labels[i],
                                  style: TextStyle(
                                    color: itemColor,
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
      // Glassy floating nav — matches the main app's bottom bar.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.42)
                      : Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.75),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: List.generate(_labels.length, (i) {
                    final isActive = _index == i;
                    final inactiveColor = isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.45);
                    final itemColor = isActive
                        ? AppColors.primary
                        : inactiveColor;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onTap(i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),
                          decoration: isActive
                              ? ShapeDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withValues(
                                        alpha: 0.34,
                                      ),
                                      AppColors.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                    ],
                                  ),
                                  shape: const StadiumBorder(),
                                  shadows: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                )
                              : null,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_icons[i], color: itemColor, size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  _labels[i],
                                  style: TextStyle(
                                    color: itemColor,
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  void _onTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }
}
