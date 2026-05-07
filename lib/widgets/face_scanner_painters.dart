import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rotating scanner arcs around a circle.
class ScannerArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  ScannerArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final angle = progress * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle,
      math.pi * 0.4,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle + math.pi,
      math.pi * 0.3,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle + math.pi * 0.6,
      math.pi * 0.2,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    final dotAngle = angle + math.pi * 0.4;
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      ),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(ScannerArcPainter old) => old.progress != progress;
}

/// Corner bracket markers — camera viewfinder style.
class CornerBracketPainter extends CustomPainter {
  final Color color;

  CornerBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const len = 20.0;
    const pad = 8.0;

    // Top-left
    canvas.drawLine(
      const Offset(pad, pad + len),
      const Offset(pad, pad),
      paint,
    );
    canvas.drawLine(
      const Offset(pad, pad),
      const Offset(pad + len, pad),
      paint,
    );
    // Top-right
    canvas.drawLine(
      Offset(size.width - pad - len, pad),
      Offset(size.width - pad, pad),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(size.width - pad, pad + len),
      paint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(pad, size.height - pad - len),
      Offset(pad, size.height - pad),
      paint,
    );
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(pad + len, size.height - pad),
      paint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(size.width - pad - len, size.height - pad),
      Offset(size.width - pad, size.height - pad),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - pad, size.height - pad),
      Offset(size.width - pad, size.height - pad - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerBracketPainter old) => false;
}

/// Horizontal sweep line that bounces inside a circle.
class SweepLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  SweepLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final t = (math.sin(progress * 2 * math.pi) + 1) / 2;
    final y = center.dy - radius + t * radius * 2;

    final dy = (y - center.dy).abs();
    if (dy >= radius) return;
    final halfChord = math.sqrt(radius * radius - dy * dy);

    canvas.drawLine(
      Offset(center.dx - halfChord, y),
      Offset(center.dx + halfChord, y),
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                color.withValues(alpha: 0.0),
                color.withValues(alpha: 0.6),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(
              Rect.fromLTRB(
                center.dx - halfChord,
                y - 1,
                center.dx + halfChord,
                y + 1,
              ),
            )
        ..strokeWidth = 2.0,
    );

    // Faded trail
    final trailPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.0),
              color.withValues(alpha: 0.12),
            ],
          ).createShader(
            Rect.fromLTRB(
              center.dx - halfChord,
              y - 30,
              center.dx + halfChord,
              y,
            ),
          );

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawRect(
      Rect.fromLTRB(center.dx - halfChord, y - 30, center.dx + halfChord, y),
      trailPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SweepLinePainter old) => old.progress != progress;
}

/// Pulsing glow ring builder.
class PulsingGlowRing extends StatelessWidget {
  final Animation<double> animation;
  final double diameter;
  final Color color;

  const PulsingGlowRing({
    super.key,
    required this.animation,
    required this.diameter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = 1.0 + animation.value * 0.06;
        final opacity = 0.15 + animation.value * 0.15;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: opacity * 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
