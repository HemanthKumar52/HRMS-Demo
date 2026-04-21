import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Dynamic Island-style interactive overlay.
/// - Mini state: pill showing icon + brief text
/// - Expanded state: full card with details and actions
/// - Tap to expand/collapse with spring animation
/// - Auto-collapse after 5 seconds
class DynamicIslandOverlay extends StatefulWidget {
  const DynamicIslandOverlay({super.key});

  @override
  State<DynamicIslandOverlay> createState() => _DynamicIslandOverlayState();
}

class _DynamicIslandOverlayState extends State<DynamicIslandOverlay>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
      // Auto-collapse after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _expanded) {
          setState(() => _expanded = false);
          _animController.reverse();
        }
      });
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.showDynamicIsland) {
          return const SizedBox.shrink();
        }

        final topPadding = MediaQuery.of(context).padding.top;

        return Positioned(
          top: topPadding + 8,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _expandAnim,
                builder: (context, child) {
                  final progress = _expandAnim.value;
                  final width = lerpDouble(200, 340, progress)!;
                  final height = lerpDouble(44, 120, progress)!;
                  final radius = lerpDouble(22, 24, progress)!;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: [
                            BoxShadow(
                              color: provider.dynamicIslandColor.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _expanded
                            ? _buildExpanded(provider)
                            : _buildMini(provider),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMini(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.dynamicIslandIcon,
            color: provider.dynamicIslandColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              provider.dynamicIslandMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.dynamicIslandIcon,
                color: provider.dynamicIslandColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.dynamicIslandMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (provider.isPunchedIn)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Session',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to collapse',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
