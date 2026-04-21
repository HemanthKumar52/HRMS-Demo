import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/adaptive_colors.dart';
import '../utils/platform_adaptive.dart';

// ─── Adaptive List Section ───────────────────────────────────────────────

/// iOS: CupertinoListSection.insetGrouped with native styling.
/// Android: Column with card-like background and rounded corners.
class AdaptiveListSection extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const AdaptiveListSection({
    super.key,
    this.header,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoListSection.insetGrouped(
        header: header != null ? Text(header!) : null,
        children: children,
      );
    }

    // Android: styled column
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              header!.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdaptiveColors.secondaryText(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AdaptiveColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _insertSeparators(context, children),
          ),
        ),
      ],
    );
  }

  List<Widget> _insertSeparators(BuildContext context, List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 16,
            color: AdaptiveColors.separator(context),
          ),
        );
      }
    }
    return result;
  }
}

// ─── Adaptive List Tile ───��──────────────────────────────────────────────

/// iOS: CupertinoListTile with native chevron and styling.
/// Android: Material-style row with custom styling.
class AdaptiveListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing:
            trailing ??
            (onTap != null ? const CupertinoListTileChevron() : null),
        onTap: onTap,
      );
    }

    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AdaptiveColors.primaryText(context),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: AdaptiveColors.secondaryText(context),
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: AdaptiveColors.tertiaryText(context),
                )
              : null),
      onTap: onTap,
    );
  }
}

// ─── Adaptive Toggle Tile ────────────────────────────────────────────────

/// A list tile with a switch/toggle.
/// iOS: CupertinoSwitch. Android: Switch.adaptive.
class AdaptiveToggleTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdaptiveToggleTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) {
      return CupertinoListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
        ),
      );
    }

    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AdaptiveColors.primaryText(context),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: AdaptiveColors.secondaryText(context),
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
