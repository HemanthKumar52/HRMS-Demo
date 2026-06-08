import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'grid_logo_icon.dart';

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Same tabs for everyone — admin tools are accessed via the dashboard.
    final items = <_NavItem>[
      _NavItem(Icons.grid_view_rounded, 'Dashboard'),
      _NavItem(Icons.assignment_outlined, 'Requests'),
      _NavItem(Icons.fingerprint_rounded, 'Attendance'),
      _NavItem(Icons.description_outlined, 'Payslip'),
    ];

    return Positioned(
      bottom: 16,
      left: 20,
      right: 20,
      child:
          ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      // Instagram-style frosted glass — dark translucent in
                      // dark mode, white translucent in light mode.
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.42)
                          : Colors.white.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.85),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.12,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final isActive = provider.bottomNavIndex == index;
                        return Expanded(
                          child: _NavButton(
                            item: items[index],
                            isActive: isActive,
                            onTap: () => provider.setBottomNavIndex(index),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(
                begin: 0.3,
                end: 0,
                duration: 500.ms,
                delay: 200.ms,
                curve: Curves.easeOutCubic,
              ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  // Increments on each tap of the grid (Dashboard) item to flash its colors.
  int _gridColorTrigger = 0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(
            parent: _bounceController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void didUpdateWidget(_NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Blue active, neutral inactive.
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.45);
    final itemColor = widget.isActive ? AppColors.primary : inactiveColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (widget.item.isGrid) {
          setState(() => _gridColorTrigger++);
        }
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: widget.isActive
              ? ShapeDecoration(
                  // Glassy blue blob — stadium (fully rounded) with soft glow.
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.50),
                      AppColors.primary.withValues(alpha: 0.26),
                    ],
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 1.3,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
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
                widget.item.isGrid
                    // Plain monochrome grid normally; flashes 4 colors on tap.
                    ? GridLogoIcon(
                        size: 24,
                        monoColor: itemColor,
                        colorTrigger: _gridColorTrigger,
                      )
                    : Icon(widget.item.icon, color: itemColor, size: 24),
                const SizedBox(height: 4),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 11,
                    fontWeight: widget.isActive
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
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool isGrid;
  _NavItem(this.icon, this.label, {this.isGrid = false});
}
