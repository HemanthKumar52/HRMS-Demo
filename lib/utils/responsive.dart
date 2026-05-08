import 'package:flutter/material.dart';

/// Device type based on screen width.
///
/// | Device              | Width Range | Type     |
/// |---------------------|-------------|----------|
/// | Phone 5-7"          | < 600       | phone    |
/// | Tablet 7-11"        | 600 - 1023  | tablet   |
/// | Tablet 11-15" / Mac | >= 1024     | desktop  |
enum DeviceType { phone, tablet, desktop }

class Responsive {
  Responsive._();

  static const double phoneMax = 600;
  static const double tabletMax = 1024;

  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < phoneMax) return DeviceType.phone;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isPhone(BuildContext context) =>
      deviceType(context) == DeviceType.phone;
  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;
  static bool isTabletOrDesktop(BuildContext context) => !isPhone(context);

  /// Responsive value based on device type.
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType(context)) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.phone:
        return phone;
    }
  }

  /// Horizontal padding.
  static double horizontalPadding(BuildContext context) =>
      value(context, phone: 16.0, tablet: 24.0, desktop: 40.0);

  /// Content max width — prevents ultra-wide stretching.
  static double maxContentWidth(BuildContext context) =>
      value(context, phone: double.infinity, tablet: 720.0, desktop: 960.0);

  /// Grid cross axis count.
  static int gridColumns(
    BuildContext context, {
    int phone = 1,
    int tablet = 2,
    int desktop = 3,
  }) => value(context, phone: phone, tablet: tablet, desktop: desktop);

  /// Font scale factor.
  static double fontScale(BuildContext context) =>
      value(context, phone: 1.0, tablet: 1.05, desktop: 1.1);

  /// Bottom nav height.
  static double bottomNavHeight(BuildContext context) =>
      value(context, phone: 70.0, tablet: 80.0, desktop: 80.0);

  /// Form max width.
  static double formMaxWidth(BuildContext context) =>
      value(context, phone: double.infinity, tablet: 600.0, desktop: 600.0);

  /// Whether to use split-view layout.
  static bool useSplitView(BuildContext context) => !isPhone(context);

  /// Minimum touch target.
  static double get minTouchTarget => 48.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// Responsive Widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Constrains child to max width and centers on larger screens.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final mw = maxWidth ?? Responsive.maxContentWidth(context);
    final pad =
        padding ??
        EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context));

    if (mw == double.infinity) {
      return Padding(padding: pad, child: child);
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mw),
        child: Padding(padding: pad, child: child),
      ),
    );
  }
}

/// Backward-compatible alias.
typedef ResponsiveContent = ResponsiveCenter;

/// Responsive grid that adapts columns based on screen width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? phoneColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.phoneColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final cols = Responsive.gridColumns(
      context,
      phone: phoneColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSpacing = spacing * (cols - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth.clamp(0, constraints.maxWidth),
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Master-detail layout: side-by-side on tablet/desktop, stacked on phone.
class ResponsiveMasterDetail extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final bool hasSelection;
  final double masterWidth;

  const ResponsiveMasterDetail({
    super.key,
    required this.master,
    this.detail,
    this.hasSelection = false,
    this.masterWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isPhone(context)) {
      return hasSelection && detail != null ? detail! : master;
    }
    return Row(
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              detail ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select an item',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}

/// Sidebar + content on tablet/desktop, full-screen content on phone.
class ResponsiveSidebar extends StatelessWidget {
  final Widget sidebar;
  final Widget content;
  final double sidebarWidth;

  const ResponsiveSidebar({
    super.key,
    required this.sidebar,
    required this.content,
    this.sidebarWidth = 280,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isPhone(context)) return content;
    return Row(
      children: [
        SizedBox(width: sidebarWidth, child: sidebar),
        const VerticalDivider(width: 1),
        Expanded(child: content),
      ],
    );
  }
}

/// Responsive scaffold with bottom nav on phone, navigation rail on tablet/desktop.
class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ResponsiveNavItem> items;
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.body,
    this.floatingActionButton,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isPhone(context)) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          height: 65,
          destinations: items
              .map(
                (i) => NavigationDestination(
                  icon: Icon(i.icon),
                  selectedIcon: Icon(i.selectedIcon ?? i.icon),
                  label: i.label,
                ),
              )
              .toList(),
        ),
      );
    }

    // Tablet/Desktop: navigation rail
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            extended: Responsive.isDesktop(context),
            minExtendedWidth: 200,
            labelType: Responsive.isDesktop(context)
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: items
                .map(
                  (i) => NavigationRailDestination(
                    icon: Icon(i.icon),
                    selectedIcon: Icon(i.selectedIcon ?? i.icon),
                    label: Text(i.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class ResponsiveNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  const ResponsiveNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// Responsive dialog — full-screen on phone, centered dialog on tablet/desktop.
Future<T?> showResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 500,
  double maxHeight = 600,
}) {
  if (Responsive.isPhone(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: builder(ctx),
      ),
    ),
  );
}
