import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data model for a single donut segment.
class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// A styled donut chart with tap-to-select segments.
class StyledDonutChart extends StatefulWidget {
  final List<DonutSegment> segments;
  final String? centerLabel;
  final double size;
  final double strokeWidth;
  final double gapDegrees;
  final Duration animationDuration;
  final Widget Function(double total)? centerBuilder;
  final bool showLegend;

  const StyledDonutChart({
    super.key,
    required this.segments,
    this.centerLabel,
    this.size = 200,
    this.strokeWidth = 28,
    this.gapDegrees = 6,
    this.animationDuration = const Duration(milliseconds: 900),
    this.centerBuilder,
    this.showLegend = true,
  });

  @override
  State<StyledDonutChart> createState() => _StyledDonutChartState();
}

class _StyledDonutChartState extends State<StyledDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapSegment(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - widget.strokeWidth) / 2;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Only register taps on the donut ring
    if (dist < radius - widget.strokeWidth / 2 ||
        dist > radius + widget.strokeWidth / 2) {
      setState(() => _selectedIndex = null);
      return;
    }

    // Calculate angle (0 = top, clockwise)
    var angle = math.atan2(dx, -dy) * 180 / math.pi;
    if (angle < 0) angle += 360;

    final total = widget.segments.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    final totalGap = widget.gapDegrees * widget.segments.length;
    final available = 360.0 - totalGap;
    double cumulative = 0;

    for (int i = 0; i < widget.segments.length; i++) {
      final sweep = (widget.segments[i].value / total) * available;
      final start = cumulative + widget.gapDegrees / 2;
      if (angle >= start && angle < start + sweep) {
        setState(() => _selectedIndex = _selectedIndex == i ? null : i);
        return;
      }
      cumulative += sweep + widget.gapDegrees;
    }
    setState(() => _selectedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.segments.fold<double>(0, (s, e) => s + e.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final selected = _selectedIndex != null
        ? widget.segments[_selectedIndex!]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: GestureDetector(
            onTapUp: (details) => _onTapSegment(
              details.localPosition,
              Size(widget.size, widget.size),
            ),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DonutPainter(
                      segments: widget.segments,
                      total: total,
                      progress: _animation.value,
                      strokeWidth: widget.strokeWidth,
                      gapDegrees: widget.gapDegrees,
                      selectedIndex: _selectedIndex,
                      trackColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    child: Center(
                      child: widget.centerBuilder != null
                          ? widget.centerBuilder!(total)
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: selected != null
                                  ? Column(
                                      key: ValueKey(_selectedIndex),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${selected.value.toInt()}',
                                          style: textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: selected.color,
                                              ),
                                        ),
                                        Text(
                                          selected.label,
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      key: const ValueKey('total'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          total.toInt().toString(),
                                          style: textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                        ),
                                        if (widget.centerLabel != null)
                                          Text(
                                            widget.centerLabel!,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black45,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                      ],
                                    ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: widget.segments.asMap().entries.map((entry) {
              final i = entry.key;
              final seg = entry.value;
              final isActive = _selectedIndex == i;
              return GestureDetector(
                onTap: () => setState(
                  () => _selectedIndex = _selectedIndex == i ? null : i,
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _selectedIndex == null || isActive ? 1.0 : 0.4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: seg.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${seg.label} (${seg.value.toInt()})',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double total;
  final double progress;
  final double strokeWidth;
  final double gapDegrees;
  final Color trackColor;
  final int? selectedIndex;

  _DonutPainter({
    required this.segments,
    required this.total,
    required this.progress,
    required this.strokeWidth,
    required this.gapDegrees,
    required this.trackColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0 || segments.isEmpty) return;

    final totalGap = gapDegrees * segments.length;
    final availableDegrees = 360.0 - totalGap;

    double startAngle = -90.0;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepDegrees = (segment.value / total) * availableDegrees;
      final animatedSweep = sweepDegrees * progress;

      if (animatedSweep <= 0) {
        startAngle += sweepDegrees + gapDegrees;
        continue;
      }

      final isSelected = selectedIndex == i;
      final dimmed = selectedIndex != null && !isSelected;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth + 6 : strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = dimmed
            ? segment.color.withValues(alpha: 0.25)
            : segment.color;

      canvas.drawArc(
        isSelected ? Rect.fromCircle(center: center, radius: radius) : rect,
        _degToRad(startAngle + gapDegrees / 2),
        _degToRad(animatedSweep),
        false,
        paint,
      );

      startAngle += sweepDegrees + gapDegrees;
    }
  }

  double _degToRad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress ||
      old.segments != segments ||
      old.total != total ||
      old.selectedIndex != selectedIndex;
}
