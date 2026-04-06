import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    // Fast press down
    _downController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleDown = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _downController, curve: Curves.easeOut),
    );

    // Slower release with overshoot
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
        _downController.forward().then((_) {
          _upController.forward(from: 0);
        });
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_downController, _upController]),
        builder: (context, child) {
          double scale;
          if (_downController.isAnimating || _downController.isCompleted && !_upController.isAnimating) {
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
      onTap: onTap,
      child: Container(
        decoration: NeuDecoration.glass(context, radius: radius),
        padding: padding,
        child: child,
      ),
    );
  }
}
