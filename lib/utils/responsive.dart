import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'platform_adaptive.dart';

/// Device type based on screen width
enum DeviceType { phone, tablet, desktop }

/// Responsive utilities for adapting UI across device sizes
class Responsive {
  Responsive._();

  // Breakpoints
  static const double phoneMax = 600;
  static const double tabletMax = 1024;

  /// Get current device type
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneMax) return DeviceType.phone;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check device type
  static bool isPhone(BuildContext context) =>
      deviceType(context) == DeviceType.phone;
  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;

  /// Check for iPad specifically
  static bool isIPad(BuildContext context) {
    return isApplePlatform &&
        _isIOSDevice &&
        deviceType(context) == DeviceType.tablet;
  }

  /// Check for Android tablet
  static bool isAndroidTablet(BuildContext context) {
    try {
      return Platform.isAndroid && deviceType(context) == DeviceType.tablet;
    } catch (_) {
      return false;
    }
  }

  static bool get _isIOSDevice {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Responsive value based on device type
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

  /// Responsive padding
  static EdgeInsets padding(BuildContext context) {
    return value(
      context,
      phone: const EdgeInsets.symmetric(horizontal: 20),
      tablet: const EdgeInsets.symmetric(horizontal: 40),
      desktop: const EdgeInsets.symmetric(horizontal: 80),
    );
  }

  /// Content max width (for centering on large screens)
  static double maxContentWidth(BuildContext context) {
    return value(
      context,
      phone: double.infinity,
      tablet: 700.0,
      desktop: 900.0,
    );
  }

  /// Grid cross axis count
  static int gridColumns(
    BuildContext context, {
    int phoneCols = 3,
    int tabletCols = 4,
    int desktopCols = 6,
  }) {
    return value(
      context,
      phone: phoneCols,
      tablet: tabletCols,
      desktop: desktopCols,
    );
  }

  /// Font scale factor
  static double fontScale(BuildContext context) {
    return value(context, phone: 1.0, tablet: 1.1, desktop: 1.15);
  }

  /// Bottom nav height (accounts for different device sizes)
  static double bottomNavHeight(BuildContext context) {
    return value(context, phone: 70.0, tablet: 80.0, desktop: 80.0);
  }

  /// Form max width (constrains forms on tablets/desktop)
  static double formMaxWidth(BuildContext context) {
    return value(
      context,
      phone: double.infinity,
      tablet: 600.0,
      desktop: 600.0,
    );
  }

  /// Whether to use split-view layout (master-detail)
  static bool useSplitView(BuildContext context) {
    return !isPhone(context);
  }

  /// Minimum touch target size per HIG (44pt on iOS)
  static double get minTouchTarget => isApplePlatform ? 44.0 : 48.0;
}

/// A widget that constrains its child to a max width and centers it.
/// Useful for tablet/desktop layouts where content shouldn't stretch full width.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContent({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.maxContentWidth(context);

    if (maxWidth == double.infinity) {
      return padding != null ? Padding(padding: padding!, child: child) : child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
