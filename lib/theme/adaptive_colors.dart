import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform_adaptive.dart';
import 'app_theme.dart';

/// Resolves colors based on platform and brightness.
/// On iOS: uses CupertinoColors dynamic resolution.
/// On Android: reads Theme.of(context).
class AdaptiveColors {
  AdaptiveColors._();

  static bool _isDark(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoTheme.of(context).brightness == Brightness.dark;
    }
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Scaffold / page background
  static Color background(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.systemGroupedBackground.resolveFrom(context);
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Card / elevated surface
  static Color cardBackground(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      );
    }
    return Theme.of(context).cardColor;
  }

  /// Primary text
  static Color primaryText(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.label.resolveFrom(context);
    }
    return _isDark(context) ? AppColors.darkText : AppColors.lightText;
  }

  /// Secondary / subtitle text
  static Color secondaryText(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.secondaryLabel.resolveFrom(context);
    }
    return _isDark(context) ? AppColors.darkSubtext : AppColors.lightSubtext;
  }

  /// Tertiary text
  static Color tertiaryText(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.tertiaryLabel.resolveFrom(context);
    }
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.grey.shade500;
  }

  /// Separator line color
  static Color separator(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.separator.resolveFrom(context);
    }
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade300;
  }

  /// Destructive / danger red
  static Color destructive(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.destructiveRed.resolveFrom(context);
    }
    return AppColors.danger;
  }

  /// System fill (for text field backgrounds etc.)
  static Color systemFill(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoColors.systemFill.resolveFrom(context);
    }
    return _isDark(context)
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
  }

  /// Nav bar background (translucent for glass effect)
  static Color barBackground(BuildContext context) {
    if (isApplePlatform) {
      final dark = _isDark(context);
      return dark
          ? const Color(0xFF1C1C1E).withValues(alpha: 0.94)
          : Colors.white.withValues(alpha: 0.94);
    }
    return _isDark(context) ? AppColors.darkBg : AppColors.lightBg;
  }

  /// Primary brand color
  static Color primary(BuildContext context) => AppColors.primary;
}
