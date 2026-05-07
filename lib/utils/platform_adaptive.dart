import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Always false on main — unified Material UI.
/// Native SwiftUI for iOS is on the `ios-styled-2` branch.
bool get isApplePlatform => false;

// ─── App Bar ────────────────────────────────────────────────────────────

PreferredSizeWidget adaptiveAppBar({
  required BuildContext context,
  required String title,
  bool showBackButton = false,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

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

// ─── Sliver Scaffold ────────────────────────────────────────────────────

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget body = CustomScrollView(slivers: slivers);
    if (onRefresh != null) {
      body = RefreshIndicator(onRefresh: onRefresh!, child: body);
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

// ─── Static Scaffold ────────────────────────────────────────────────────

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

// ─── Page Route ─────────────────────────────────────────────────────────

PageRoute<T> adaptivePageRoute<T>({required Widget child}) {
  return MaterialPageRoute(builder: (_) => child);
}

// ─── Action Sheet ───────────────────────────────────────────────────────

Future<T?> showAdaptiveActionSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<AdaptiveAction> actions,
  String cancelLabel = 'Cancel',
}) {
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

// ─── Alert Dialog ───────────────────────────────────────────────────────

Future<T?> showAdaptiveAlert<T>({
  required BuildContext context,
  required String title,
  String? content,
  String confirmLabel = 'OK',
  String? cancelLabel,
  VoidCallback? onConfirm,
  bool isDestructive = false,
}) {
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
