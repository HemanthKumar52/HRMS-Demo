import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated checkmark that draws itself with an optional scale bounce.
/// Usage:
///   AnimatedCheckmark(show: true, size: 48, color: AppColors.success)
class AnimatedCheckmark extends StatefulWidget {
  final bool show;
  final double size;
  final Color color;
  final Duration duration;
  final double strokeWidth;

  const AnimatedCheckmark({
    super.key,
    this.show = false,
    this.size = 48,
    this.color = const Color(0xFF34D399),
    this.duration = const Duration(milliseconds: 700),
    this.strokeWidth = 3.0,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _stroke;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _stroke = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCheckmark old) {
    super.didUpdateWidget(old);
    if (widget.show && !old.show) {
      _controller.forward(from: 0);
    } else if (!widget.show && old.show) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CheckPainter(
              progress: _stroke.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw circle
    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    // Draw check path
    if (progress > 0) {
      final path = Path();
      final p1 = Offset(size.width * 0.25, size.height * 0.5);
      final p2 = Offset(size.width * 0.42, size.height * 0.65);
      final p3 = Offset(size.width * 0.75, size.height * 0.35);

      // Total length of check
      final seg1 = (p2 - p1).distance;
      final seg2 = (p3 - p2).distance;
      final total = seg1 + seg2;
      final drawn = progress * total;

      path.moveTo(p1.dx, p1.dy);
      if (drawn <= seg1) {
        final t = drawn / seg1;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        path.lineTo(p2.dx, p2.dy);
        final t = (drawn - seg1) / seg2;
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }

      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}
