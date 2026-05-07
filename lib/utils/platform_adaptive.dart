import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

/// Returns false — unified Material UI for both iOS and Android.
/// iOS-specific native SwiftUI UI is on the `ios-styled-2` branch.
bool get isApplePlatform => false;

// ─── Adaptive App Bar ────────────────────────────────────────────────────

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
              leading:
                  leading ??
                  (showBackButton
                      ? CupertinoButton(
                          padding: const EdgeInsets.only(left: 8),
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(
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
    backgroundColor: isDark
        ? AppColors.darkBg
        : Theme.of(context).scaffoldBackgroundColor,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading:
        leading ??
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

// ─── Adaptive Sliver Scaffold ────────────────────────────────────────────

/// iOS: CupertinoPageScaffold with CupertinoSliverNavigationBar (large title
/// that collapses on scroll) + optional pull-to-refresh.
/// Android: Material Scaffold + AppBar + RefreshIndicator.
///
/// [slivers] are placed after the nav bar and refresh control.
/// On Android, slivers are wrapped in a CustomScrollView inside the Scaffold.
class AdaptiveSliverScaffold extends StatelessWidget {
  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;
  final bool showBackButton;

  const AdaptiveSliverScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
    this.onRefresh,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) return _buildIOS(context);
    return _buildAndroid(context);
  }

  Widget _buildIOS(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            trailing: trailing,
            previousPageTitle: showBackButton ? '' : null,
            border: null,
            stretch: true,
          ),
          if (onRefresh != null)
            CupertinoSliverRefreshControl(onRefresh: onRefresh),
          ...slivers,
        ],
      ),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget body = CustomScrollView(
      slivers: slivers,
    );
    if (onRefresh != null) {
      body = RefreshIndicator(
        onRefresh: onRefresh!,
        child: body,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.darkBg
            : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.darkText : AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        actions: trailing != null ? [trailing!] : null,
      ),
      body: body,
    );
  }
}

// ─── Adaptive Static Scaffold ────────────────────────────────────────────

/// For non-scrollable screens or forms with fixed nav bar.
/// iOS: CupertinoPageScaffold with CupertinoNavigationBar.
/// Android: Material Scaffold with AppBar.
class AdaptiveStaticScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? trailing;
  final bool showBackButton;

  const AdaptiveStaticScaffold({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          trailing: trailing,
          previousPageTitle: showBackButton ? '' : null,
          border: null,
        ),
        child: SafeArea(
          top: false,
          child: body,
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.darkBg
            : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.darkText : AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        actions: trailing != null ? [trailing!] : null,
      ),
      body: body,
    );
  }
}

// ─── iOS-style Glass Bottom Tab Bar ──────────────────────────────────────

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
      _GlassTabItem(CupertinoIcons.creditcard_fill, 'Payslip'),
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
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
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

// ─── Adaptive Page Route ─────────────────────────────────────────────────

/// Adaptive page route — iOS gets Cupertino slide, Android gets Material
PageRoute<T> adaptivePageRoute<T>({required Widget child}) {
  if (isApplePlatform) {
    return CupertinoPageRoute(builder: (_) => child);
  }
  return MaterialPageRoute(builder: (_) => child);
}

// ─── Adaptive Action Sheet ───────────────────────────────────────────────

/// Shows a CupertinoActionSheet on iOS, showModalBottomSheet on Android.
Future<T?> showAdaptiveActionSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<AdaptiveAction> actions,
  String cancelLabel = 'Cancel',
}) {
  if (isApplePlatform) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        message: message != null ? Text(message) : null,
        actions: actions
            .map(
              (a) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  a.onPressed();
                },
                isDestructiveAction: a.isDestructive,
                child: Text(a.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(title, style: theme.textTheme.titleMedium),
              if (message != null) ...[
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              ...actions.map(
                (a) => ListTile(
                  title: Text(
                    a.label,
                    style: TextStyle(
                      color: a.isDestructive ? AppColors.danger : null,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    a.onPressed();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

/// An action for [showAdaptiveActionSheet].
class AdaptiveAction {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const AdaptiveAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });
}

// ─── Adaptive Dialog ─────────────────────────────────────────────────────

/// Shows a CupertinoAlertDialog on iOS, AlertDialog on Android.
Future<T?> showAdaptiveAlert<T>({
  required BuildContext context,
  required String title,
  String? content,
  String confirmLabel = 'OK',
  String? cancelLabel,
  VoidCallback? onConfirm,
  bool isDestructive = false,
}) {
  if (isApplePlatform) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: content != null ? Text(content) : null,
        actions: [
          if (cancelLabel != null)
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelLabel),
            ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelLabel),
          ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          child: Text(
            confirmLabel,
            style: TextStyle(color: isDestructive ? AppColors.danger : null),
          ),
        ),
      ],
    ),
  );
}
