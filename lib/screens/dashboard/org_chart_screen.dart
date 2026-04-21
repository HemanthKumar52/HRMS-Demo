import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';

class OrgChartScreen extends StatefulWidget {
  const OrgChartScreen({super.key});

  @override
  State<OrgChartScreen> createState() => _OrgChartScreenState();
}

class _OrgChartScreenState extends State<OrgChartScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _roots = [];

  @override
  void initState() {
    super.initState();
    _loadOrgChart();
  }

  Future<void> _loadOrgChart() async {
    try {
      final data = await ApiService.get('/org-chart');
      _roots = List<Map<String, dynamic>>.from(
        (data['org_chart'] as List?)?.map(
              (e) => Map<String, dynamic>.from(e),
            ) ??
            [],
      );
    } catch (e) {
      debugPrint('Org chart error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Flatten tree into rings
  List<List<_OrgNode>> _buildRings() {
    if (_roots.isEmpty) return [];
    final rings = <List<_OrgNode>>[];

    // If multiple roots, pick the first as center and put rest in ring 1
    final mainRoot = _OrgNode.fromMap(_roots.first);
    rings.add([mainRoot]);

    // Ring 1 = main root's children + other roots
    final ring1 = <_OrgNode>[];
    ring1.addAll(mainRoot.children);
    for (int i = 1; i < _roots.length; i++) {
      ring1.add(_OrgNode.fromMap(_roots[i]));
    }
    if (ring1.isNotEmpty) rings.add(ring1);

    // Deeper rings
    var current = ring1;
    for (int d = 2; d <= 4; d++) {
      final next = <_OrgNode>[];
      for (final p in current) {
        next.addAll(p.children);
      }
      if (next.isEmpty) break;
      rings.add(next);
      current = next;
    }
    return rings;
  }

  static const _ringColors = [
    Color(0xFF7C3AED), // Admin — purple
    Color(0xFF2563EB), // Managers — blue
    Color(0xFF059669), // Leads — green
    Color(0xFF0891B2), // Employees — cyan
    Color(0xFFD97706), // Staff — amber
  ];

  static const _roleLabels = [
    'Admin',
    'Managers',
    'Team Leads',
    'Employees',
    'Staff',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rings = _buildRings();

    return Scaffold(
      appBar: adaptiveAppBar(
        context: context,
        title: 'Organisation Chart',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _roots.isEmpty
          ? const Center(child: Text('No organisation data'))
          : Column(
              children: [
                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      for (
                        int i = 0;
                        i < rings.length && i < _roleLabels.length;
                        i++
                      )
                        _legendItem(
                          _ringColors[i],
                          '${_roleLabels[i]} (${rings[i].length})',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Chart with auto-fit
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      return _CircularOrgChart(
                        rings: rings,
                        colors: _ringColors,
                        isDark: isDark,
                        viewportWidth: constraints.maxWidth,
                        viewportHeight: constraints.maxHeight,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Main chart widget with auto-fit ─────────────────────────────
class _CircularOrgChart extends StatefulWidget {
  final List<List<_OrgNode>> rings;
  final List<Color> colors;
  final bool isDark;
  final double viewportWidth;
  final double viewportHeight;

  const _CircularOrgChart({
    required this.rings,
    required this.colors,
    required this.isDark,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  @override
  State<_CircularOrgChart> createState() => _CircularOrgChartState();
}

class _CircularOrgChartState extends State<_CircularOrgChart> {
  late TransformationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToScreen());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitToScreen() {
    final chartSize = _computeCanvasSize();
    // Scale to fit viewport with padding
    final scaleX = (widget.viewportWidth - 20) / chartSize;
    final scaleY = (widget.viewportHeight - 20) / chartSize;
    final scale = min(scaleX, scaleY).clamp(0.15, 1.0);

    // Center the chart
    final dx = (widget.viewportWidth - chartSize * scale) / 2;
    final dy = (widget.viewportHeight - chartSize * scale) / 2;

    _controller.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  double _computeCanvasSize() {
    final radii = _computeRadii();
    final maxR = radii.isNotEmpty ? radii.last : 60.0;
    return (maxR + 100) * 2;
  }

  List<double> _computeRadii() {
    const nodeArc = 100.0; // min arc per node
    final radii = <double>[0.0];
    for (int r = 1; r < widget.rings.length; r++) {
      final count = widget.rings[r].length;
      final needed = (count * nodeArc) / (2 * pi);
      final minR = radii[r - 1] + 120;
      radii.add(max(needed, minR));
    }
    return radii;
  }

  @override
  Widget build(BuildContext context) {
    final radii = _computeRadii();
    final canvasSize = _computeCanvasSize();
    final center = canvasSize / 2;

    return InteractiveViewer(
      transformationController: _controller,
      minScale: 0.1,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(500),
      child: SizedBox(
        width: canvasSize,
        height: canvasSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Lines
            CustomPaint(
              size: Size(canvasSize, canvasSize),
              painter: _LinesPainter(
                rings: widget.rings,
                radii: radii,
                center: Offset(center, center),
                colors: widget.colors,
                isDark: widget.isDark,
              ),
            ),

            // Ring guides
            for (int r = 1; r < widget.rings.length; r++)
              Positioned(
                left: center - radii[r],
                top: center - radii[r],
                child: Container(
                  width: radii[r] * 2,
                  height: radii[r] * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.colors[r.clamp(0, widget.colors.length - 1)]
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),

            // Center node
            if (widget.rings.isNotEmpty)
              Positioned(
                left: center - 50,
                top: center - 50,
                child: _buildCenterNode(widget.rings[0].first).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
              ),

            // Ring nodes
            for (int r = 1; r < widget.rings.length; r++)
              ...widget.rings[r].asMap().entries.map((e) {
                final i = e.key;
                final node = e.value;
                final count = widget.rings[r].length;
                final angle = (2 * pi * i / count) - (pi / 2);
                final nr = r == 1 ? 24.0 : 20.0;

                final x = center + radii[r] * cos(angle);
                final y = center + radii[r] * sin(angle);
                final color =
                    widget.colors[r.clamp(0, widget.colors.length - 1)];

                return Positioned(
                  left: x - nr - 8,
                  top: y - nr - 8,
                  child: _buildRingNode(node, nr, color, r)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (r * 100 + i * 30).ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: 350.ms,
                        delay: (r * 100 + i * 30).ms,
                      ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNode(_OrgNode node) {
    final hasAvatar = node.avatarUrl != null && node.avatarUrl!.isNotEmpty;
    final color = widget.colors[0];
    return SizedBox(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: hasAvatar
                ? CircleAvatar(
                    radius: 38,
                    backgroundImage: NetworkImage(node.avatarUrl!),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 28),
                      Text(
                        node.designation.isNotEmpty
                            ? node.designation
                            : 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 6),
          _nameTag(node, color, large: true),
        ],
      ),
    );
  }

  Widget _buildRingNode(_OrgNode node, double r, Color color, int ring) {
    final hasAvatar = node.avatarUrl != null && node.avatarUrl!.isNotEmpty;
    return SizedBox(
      width: (r + 8) * 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: r * 2,
            height: r * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: hasAvatar
                ? CircleAvatar(
                    radius: r - 2,
                    backgroundImage: NetworkImage(node.avatarUrl!),
                  )
                : Center(
                    child: Text(
                      node.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: r > 22 ? 14 : 11,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          _nameTag(node, color, large: false),
        ],
      ),
    );
  }

  Widget _nameTag(_OrgNode node, Color color, {required bool large}) {
    return Container(
      constraints: BoxConstraints(maxWidth: large ? 100 : 80),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            node.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: large ? 10 : 8,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (node.designation.isNotEmpty)
            Text(
              node.designation,
              style: TextStyle(
                fontSize: large ? 8 : 7,
                color: widget.isDark ? Colors.white54 : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (node.department.isNotEmpty) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                node.department,
                style: TextStyle(
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Data model ──────────────────────────────────────────────────
class _OrgNode {
  final String name;
  final String designation;
  final String department;
  final String? avatarUrl;
  final String initials;
  final List<_OrgNode> children;

  const _OrgNode({
    required this.name,
    required this.designation,
    required this.department,
    this.avatarUrl,
    required this.initials,
    required this.children,
  });

  factory _OrgNode.fromMap(Map<String, dynamic> m) {
    final name = m['name'] as String? ?? '';
    final raw = (m['children'] as List?) ?? [];
    return _OrgNode(
      name: name,
      designation: m['designation'] as String? ?? '',
      department: m['department'] as String? ?? '',
      avatarUrl: m['avatar_url'] as String?,
      initials: name
          .split(' ')
          .map((e) => e.isNotEmpty ? e[0] : '')
          .take(2)
          .join()
          .toUpperCase(),
      children: raw
          .map((c) => _OrgNode.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}

// ── Lines painter ───────────────────────────────────────────────
class _LinesPainter extends CustomPainter {
  final List<List<_OrgNode>> rings;
  final List<double> radii;
  final Offset center;
  final List<Color> colors;
  final bool isDark;

  const _LinesPainter({
    required this.rings,
    required this.radii,
    required this.center,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 1; r < rings.length; r++) {
      final count = rings[r].length;
      final pCount = rings[r - 1].length;
      final color = colors[r.clamp(0, colors.length - 1)];
      final paint = Paint()
        ..color = color.withValues(alpha: isDark ? 0.18 : 0.12)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < count; i++) {
        final a = (2 * pi * i / count) - (pi / 2);
        final child = Offset(
          center.dx + radii[r] * cos(a),
          center.dy + radii[r] * sin(a),
        );

        final Offset parent;
        if (r == 1) {
          parent = center;
        } else {
          final pi2 = (i * pCount / count).floor().clamp(0, pCount - 1);
          final pa = (2 * pi * pi2 / pCount) - (pi / 2);
          parent = Offset(
            center.dx + radii[r - 1] * cos(pa),
            center.dy + radii[r - 1] * sin(pa),
          );
        }
        canvas.drawLine(parent, child, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
