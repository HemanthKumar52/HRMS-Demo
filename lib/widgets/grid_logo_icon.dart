import 'dart:math';

import 'package:flutter/material.dart';

/// Curated vibrant palette for the dashboard grid mark.
List<Color> shuffledGridColors() {
  final palette = <Color>[
    const Color(0xFF4F8EF7), // blue
    const Color(0xFF34D399), // green
    const Color(0xFFFBBF24), // amber
    const Color(0xFFEC4899), // pink
    const Color(0xFF7C5CFC), // purple
    const Color(0xFFFF8C42), // orange
    const Color(0xFF22D3EE), // cyan
    const Color(0xFFEF4444), // red
  ]..shuffle(Random());
  return palette.take(4).toList();
}

/// A 2×2 grid (4-square) dashboard mark. Normally it renders monochrome
/// ([monoColor]) like any other nav icon. Each time [colorTrigger] changes
/// (i.e. the user taps it), the four squares animate into four DIFFERENT
/// colors — like the web dashboard icon recoloring on refresh — then settle
/// back to monochrome.
class GridLogoIcon extends StatefulWidget {
  final double size;
  final Color monoColor;
  final int colorTrigger;

  const GridLogoIcon({
    super.key,
    this.size = 24,
    required this.monoColor,
    this.colorTrigger = 0,
  });

  @override
  State<GridLogoIcon> createState() => _GridLogoIconState();
}

class _GridLogoIconState extends State<GridLogoIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<Color> _palette = shuffledGridColors();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant GridLogoIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.colorTrigger != oldWidget.colorTrigger) {
      // Fresh colors each tap (like a web refresh), fill in, hold, revert.
      _palette = shuffledGridColors();
      _controller.forward(from: 0).then((_) async {
        await Future.delayed(const Duration(milliseconds: 450));
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.size * 0.16;
    final sq = (widget.size - gap) / 2;
    final radius = sq * 0.30;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);

        Widget cell(int i) {
          final color = Color.lerp(widget.monoColor, _palette[i], t)!;
          return Container(
            width: sq,
            height: sq,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius),
            ),
          );
        }

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [cell(0), SizedBox(width: gap), cell(1)],
              ),
              SizedBox(height: gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [cell(2), SizedBox(width: gap), cell(3)],
              ),
            ],
          ),
        );
      },
    );
  }
}
