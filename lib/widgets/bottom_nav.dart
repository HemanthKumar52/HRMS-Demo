import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isManager = provider.role == UserRole.manager;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isHr = provider.role == UserRole.hr;

    final items = isHr
        ? [
            _NavItem(Icons.dashboard_rounded, 'Dashboard'),
            _NavItem(Icons.people_alt_rounded, 'Employees'),
            _NavItem(Icons.schedule_rounded, 'Attendance'),
            _NavItem(Icons.receipt_long_rounded, 'Claims'),
          ]
        : isManager
            ? [
                _NavItem(Icons.grid_view_rounded, 'Dashboard'),
                _NavItem(Icons.description_outlined, 'Directory'),
                _NavItem(Icons.fact_check_rounded, 'Approvals'),
                _NavItem(Icons.analytics_outlined, 'Analytics'),
              ]
            : [
                _NavItem(Icons.home_rounded, 'Home'),
                _NavItem(Icons.description_outlined, 'Request'),
                _NavItem(Icons.access_time_rounded, 'Attendance'),
                _NavItem(Icons.receipt_long_rounded, 'Payslip'),
              ];

    return Positioned(
      bottom: 16,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2030) : const Color(0xFFE4E8EE),
          borderRadius: BorderRadius.circular(28),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFFBEC3CE).withValues(alpha: 0.6),
                    offset: const Offset(6, 6),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(
                    color: Color(0xFFFDFFFF),
                    offset: Offset(-6, -6),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isActive = provider.bottomNavIndex == index;
            return _NavButton(
              item: items[index],
              isActive: isActive,
              onTap: () => provider.setBottomNavIndex(index),
            );
          }),
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(
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

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
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
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: widget.isActive
              ? BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.item.icon,
                color: widget.isActive ? AppColors.primary : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: widget.isActive ? AppColors.primary : Colors.grey,
                  fontSize: 11,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
