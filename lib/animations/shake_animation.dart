import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Horizontal shake animation for error feedback.
/// Usage:
///   ShakeAnimation(
///     controller: _shakeController,
///     child: TextFormField(...)
///   )
///   // Trigger: _shakeController.shake()
class ShakeAnimation extends StatelessWidget {
  final ShakeController controller;
  final Widget child;
  final double magnitude;

  const ShakeAnimation({
    super.key,
    required this.controller,
    required this.child,
    this.magnitude = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller._animController,
      builder: (context, child) {
        final sinValue = math.sin(
          controller._animController.value * math.pi * 4,
        );
        // Dampen oscillation as animation progresses
        final dampen = 1.0 - controller._animController.value;
        return Transform.translate(
          offset: Offset(sinValue * magnitude * dampen, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Controller for [ShakeAnimation].
/// Create with a TickerProvider, call [shake] to trigger.
class ShakeController {
  late final AnimationController _animController;

  ShakeController({required TickerProvider vsync}) {
    _animController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    );
  }

  void shake() {
    _animController.forward(from: 0);
  }

  void dispose() {
    _animController.dispose();
  }
}
