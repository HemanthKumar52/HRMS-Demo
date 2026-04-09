import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

/// Returns true if the current platform is iOS or macOS
bool get isApplePlatform {
  try {
    return Platform.isIOS || Platform.isMacOS;
  } catch (_) {
    return false;
  }
}

/// Adaptive AppBar — returns a CupertinoNavigationBar-style on iOS,
/// Material AppBar on Android.
PreferredSizeWidget adaptiveAppBar({
  required BuildContext context,
  required String title,
  bool showBackButton = false,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (isApplePlatform) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: LiquidGlass(
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: NavigationToolbar(
              leading: leading ??
                  (showBackButton
                      ? CupertinoButton(
                          padding: const EdgeInsets.only(left: 8),
                          onPressed: () => Navigator.pop(context),
                          child: Icon(
                            CupertinoIcons.back,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        )
                      : null),
              middle: Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              trailing: actions != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    )
                  : null,
              centerMiddle: centerTitle,
            ),
          ),
        ),
      ),
    );
  }

  // Material AppBar for Android
  return AppBar(
    title: Text(title),
    centerTitle: centerTitle,
    backgroundColor: isDark ? AppColors.darkBg : Theme.of(context).scaffoldBackgroundColor,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: leading ??
        (showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null),
    titleTextStyle: TextStyle(
      color: isDark ? AppColors.darkText : AppColors.lightText,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    actions: actions,
  );
}

/// iOS-style glass bottom tab bar
class GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _GlassTabItem(CupertinoIcons.square_grid_2x2_fill, 'Dashboard'),
      _GlassTabItem(CupertinoIcons.doc_text_fill, 'Requests'),
      _GlassTabItem(CupertinoIcons.hand_raised_fill, 'Attendance'),
      _GlassTabItem(CupertinoIcons.creditcard_fill, 'Payroll'),
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: LiquidGlass(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isActive = currentIndex == index;
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onTap(index);
                  },
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[index].icon,
                          size: 24,
                          color: isActive
                              ? AppColors.primary
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.grey.shade500,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[index].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? AppColors.primary
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.grey.shade500,
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
    );
  }
}

class _GlassTabItem {
  final IconData icon;
  final String label;
  _GlassTabItem(this.icon, this.label);
}

/// Adaptive page route — iOS gets Cupertino slide, Android gets Material
PageRoute<T> adaptivePageRoute<T>({required Widget child}) {
  if (isApplePlatform) {
    return CupertinoPageRoute(builder: (_) => child);
  }
  return MaterialPageRoute(builder: (_) => child);
}
