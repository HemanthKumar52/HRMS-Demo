import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shimmer skeleton loading placeholder.
/// Usage:
///   SkeletonBox(width: 100, height: 16)
///   SkeletonCircle(size: 48)
///   SkeletonCard() — full card placeholder
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1300.ms,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6),
        );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1300.ms,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6),
        );
  }
}

/// Full skeleton card that mimics a typical content card.
class SkeletonCard extends StatelessWidget {
  final int lines;
  final bool showCircle;

  const SkeletonCard({super.key, this.lines = 3, this.showCircle = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFE4E8EE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(4, 4), blurRadius: 8)]
            : [BoxShadow(color: const Color(0xFFBEC3CE).withValues(alpha: 0.4), offset: const Offset(4, 4), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCircle) ...[
            Row(
              children: [
                const SkeletonCircle(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 14),
                      const SizedBox(height: 8),
                      SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          for (int i = 0; i < lines; i++) ...[
            SkeletonBox(
              width: i == lines - 1 ? 160 : double.infinity,
              height: i == 0 ? 16 : 12,
            ),
            if (i < lines - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Full-screen skeleton for list views.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool showCircle;

  const SkeletonList({super.key, this.itemCount = 5, this.showCircle = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonCard(lines: 2, showCircle: showCircle)
              .animate()
              .fadeIn(duration: 300.ms, delay: (i * 80).ms),
        ),
      ),
    );
  }
}
