import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/adaptive_colors.dart';
import '../theme/app_theme.dart';
import '../utils/platform_adaptive.dart';

class NeuCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool pressed;

  const NeuCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.pressed = false,
  });

  @override
  State<NeuCard> createState() => _NeuCardState();
}

class _NeuCardState extends State<NeuCard> with TickerProviderStateMixin {
  late AnimationController _downController;
  late AnimationController _upController;
  late Animation<double> _scaleDown;
  late Animation<double> _scaleUp;
  @override
  void initState() {
    super.initState();
    _downController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleDown = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _downController, curve: Curves.easeOut),
    );

    _upController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleUp = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _upController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _downController.dispose();
    _upController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isApplePlatform) return _buildIOSCard(context);
    return _buildAndroidCard(context);
  }

  Widget _buildIOSCard(BuildContext context) {
    final cardChild = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AdaptiveColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdaptiveColors.separator(context),
          width: 0.5,
        ),
      ),
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.onTap == null) return cardChild;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _downController.forward().then((_) {
          _upController.forward(from: 0);
        });
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_downController, _upController]),
        builder: (context, child) {
          double scale;
          if (_downController.isAnimating ||
              _downController.isCompleted && !_upController.isAnimating) {
            scale = _scaleDown.value;
          } else if (_upController.isAnimating) {
            scale = _scaleUp.value;
          } else {
            scale = 1.0;
          }
          return Transform.scale(scale: scale, child: child);
        },
        child: cardChild,
      ),
    );
  }

  Widget _buildAndroidCard(BuildContext context) {
    final cardChild = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: widget.pressed
          ? NeuDecoration.pressed(context, radius: widget.radius)
          : NeuDecoration.card(context, radius: widget.radius),
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.onTap == null) return cardChild;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _downController.forward().then((_) {
          _upController.forward(from: 0);
        });
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_downController, _upController]),
        builder: (context, child) {
          double scale;
          if (_downController.isAnimating ||
              _downController.isCompleted && !_upController.isAnimating) {
            scale = _scaleDown.value;
          } else if (_upController.isAnimating) {
            scale = _scaleUp.value;
          } else {
            scale = 1.0;
          }
          return Transform.scale(scale: scale, child: child);
        },
        child: cardChild,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        decoration: NeuDecoration.glass(context, radius: radius),
        padding: padding,
        child: child,
      ),
    );
  }
}
