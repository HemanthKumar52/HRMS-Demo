import 'package:flutter/material.dart';

/// The official pPULSE brand mark (head + shoulders) from pPULSE_logo.svg
/// (645×600 viewBox), drawn with the brand gradient #6C3BAA → #C8B1E4.
/// Shared across splash, login, and loading screens so the logo is identical.
class PpulseLogo extends StatelessWidget {
  final double size;
  const PpulseLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    // Keep the art's aspect ratio (645 : 600).
    return SizedBox(
      width: size,
      height: size * 600 / 644.488,
      child: CustomPaint(painter: _PpulseLogoPainter()),
    );
  }
}

class _PpulseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 644.488;
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6C3BAA), Color(0xFFC8B1E4)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 600 * s));

    // Head
    canvas.drawCircle(Offset(319.374 * s, 162.953 * s), 162.953 * s, paint);

    // Shoulders / body
    final body = Path()
      ..moveTo(644.488 * s, 329.585 * s)
      ..cubicTo(
          644.488 * s, 478.931 * s, 523.419 * s, 600 * s, 374.074 * s, 600 * s)
      ..lineTo(270.415 * s, 600 * s)
      ..cubicTo(121.069 * s, 600 * s, 0, 478.931 * s, 0, 329.585 * s)
      ..cubicTo(0, 284.781 * s, 36.3205 * s, 248.461 * s, 81.1243 * s,
          248.461 * s)
      ..lineTo(563.364 * s, 248.461 * s)
      ..cubicTo(608.168 * s, 248.461 * s, 644.488 * s, 284.781 * s, 644.488 * s,
          329.585 * s)
      ..close();
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
