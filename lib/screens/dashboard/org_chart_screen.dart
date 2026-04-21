import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ── Enterprise Circular Org Chart ───────────────────────────────
// Handles unlimited hierarchy depth, 100s of employees.
// Data-driven: everything comes from /org-chart API (DB).
// Each ring = one level of depth. Lines connect parent → child.
// Colors assigned per depth level.
// Pinch-to-zoom + double-tap reset + tap node for detail.

class OrgChartScreen extends StatefulWidget {
  const OrgChartScreen({super.key});

  @override
  State<OrgChartScreen> createState() => _OrgChartScreenState();
}

class _OrgChartScreenState extends State<OrgChartScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rawRoots = [];
  final _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.get('/org-chart');
      _rawRoots = List<Map<String, dynamic>>.from(
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

  // ── Build flat ring structure from tree ────────────────────────
  // Each _FlatNode knows its ring, angle position, and parent index.
  _ChartData _buildChart() {
    if (_rawRoots.isEmpty) return _ChartData([], [], []);

    // Parse tree
    final roots = _rawRoots.map(_OrgNode.fromMap).toList();

    // BFS to flatten into rings
    final rings = <List<_OrgNode>>[];
    // Ring 0: single main root (pick the one with most children or first)
    roots.sort((a, b) => b.totalDescendants.compareTo(a.totalDescendants));
    final mainRoot = roots.first;
    rings.add([mainRoot]);

    // Ring 1: main root's children + other roots
    final ring1 = <_OrgNode>[...mainRoot.children];
    for (int i = 0; i < roots.length; i++) {
      if (roots[i] != mainRoot) ring1.add(roots[i]);
    }
    if (ring1.isNotEmpty) rings.add(ring1);

    // Subsequent rings: keep going until no more children
    var current = ring1;
    for (int depth = 2; depth <= 10; depth++) {
      final next = <_OrgNode>[];
      for (final p in current) {
        next.addAll(p.children);
      }
      if (next.isEmpty) break;
      rings.add(next);
      current = next;
    }

    // Compute radii dynamically
    const minNodeArc = 140.0;
    const minRingGap = 150.0;
    final radii = <double>[0];
    for (int r = 1; r < rings.length; r++) {
      final count = rings[r].length;
      final needed = (count * minNodeArc) / (2 * pi);
      final minR = radii[r - 1] + minRingGap;
      radii.add(max(needed, minR));
    }

    // Build flat positioned nodes
    final nodes = <_PositionedNode>[];
    // Center node
    nodes.add(
      _PositionedNode(
        node: mainRoot,
        ring: 0,
        angle: 0,
        x: 0,
        y: 0,
        color: _colorForRing(0, rings.length),
      ),
    );

    // Parent index tracking for line connections
    final parentIndices = <int, int>{}; // nodeGlobalIndex -> parentGlobalIndex

    for (int r = 1; r < rings.length; r++) {
      final count = rings[r].length;
      for (int i = 0; i < count; i++) {
        final angle = (2 * pi * i / count) - (pi / 2);
        final x = radii[r] * cos(angle);
        final y = radii[r] * sin(angle);
        final globalIdx = nodes.length;

        // Find parent in previous ring
        final parentRing = rings[r - 1];
        int parentGlobalStart = 0;
        for (int pr = 0; pr < r - 1; pr++) {
          parentGlobalStart += rings[pr].length;
        }

        // Match child to parent
        int parentIdx = 0;
        if (r == 1) {
          parentIdx = 0; // all ring 1 nodes connect to center
        } else {
          // Find which parent this child belongs to
          int childCounter = 0;
          for (int pi = 0; pi < parentRing.length; pi++) {
            final pChildCount = parentRing[pi].children.length;
            if (i < childCounter + pChildCount) {
              parentIdx = parentGlobalStart + pi;
              break;
            }
            childCounter += pChildCount;
          }
        }
        parentIndices[globalIdx] = parentIdx;

        nodes.add(
          _PositionedNode(
            node: rings[r][i],
            ring: r,
            angle: angle,
            x: x,
            y: y,
            color: _colorForRing(r, rings.length),
          ),
        );
      }
    }

    // Build lines
    final lines = <_ConnectionLine>[];
    for (final entry in parentIndices.entries) {
      final childIdx = entry.key;
      final parentIdx = entry.value;
      if (parentIdx < nodes.length && childIdx < nodes.length) {
        lines.add(
          _ConnectionLine(
            from: Offset(nodes[parentIdx].x, nodes[parentIdx].y),
            to: Offset(nodes[childIdx].x, nodes[childIdx].y),
            color: nodes[childIdx].color,
          ),
        );
      }
    }

    return _ChartData(nodes, lines, radii);
  }

  // Ring colors — enough for 8+ levels
  static const _levelColors = [
    Color(0xFF7C3AED), // C-Suite — purple
    Color(0xFF2563EB), // Directors — blue
    Color(0xFF059669), // Managers — green
    Color(0xFF0891B2), // Team Leads — cyan
    Color(0xFFD97706), // Senior — amber
    Color(0xFFDC2626), // Junior — red
    Color(0xFF7C3AED), // Intern — purple (cycle)
    Color(0xFF2563EB), // Others — blue (cycle)
  ];

  Color _colorForRing(int ring, int totalRings) {
    return _levelColors[ring % _levelColors.length];
  }

  // Smart ring labels based on whether nodes have children
  String _labelForRing(int ring, int totalRings, List<_PositionedNode> nodes) {
    if (ring == 0) return 'C-Suite';
    final ringNodes = nodes.where((n) => n.ring == ring).toList();
    final allLeaf = ringNodes.every((n) => n.node.children.isEmpty);
    final hasManagers = ringNodes.any((n) {
      final d = n.node.designation.toLowerCase();
      return d.contains('manager') ||
          d.contains('director') ||
          d.contains('head') ||
          d.contains('vp') ||
          d.contains('lead');
    });

    if (allLeaf) return 'Employees';
    if (ring == 1) {
      if (hasManagers) return 'Managers';
      return 'Directors';
    }
    if (ring == 2) return hasManagers ? 'Team Leads' : 'Managers';
    return 'Level ${ring + 1}';
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    HapticFeedback.lightImpact();
  }

  void _showNodeDetail(_OrgNode node) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage:
                  node.avatarUrl != null && node.avatarUrl!.isNotEmpty
                  ? NetworkImage(node.avatarUrl!)
                  : null,
              child: node.avatarUrl == null || node.avatarUrl!.isEmpty
                  ? Text(
                      node.initials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              node.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (node.designation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                node.designation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ],
            if (node.department.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.department,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (node.children.isNotEmpty)
              Text(
                '${node.children.length} direct report(s)',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Organisation Chart',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen_rounded),
            tooltip: 'Reset zoom',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _rawRoots.isEmpty
          ? const Center(child: Text('No organisation data'))
          : _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final chart = _buildChart();
    if (chart.nodes.isEmpty) return const Center(child: Text('No data'));

    final totalRings =
        chart.nodes.map((n) => n.ring).reduce((a, b) => a > b ? a : b) + 1;

    // Legend
    final legendItems = <Widget>[];
    for (int r = 0; r < totalRings; r++) {
      final count = chart.nodes.where((n) => n.ring == r).length;
      final label = _labelForRing(r, totalRings, chart.nodes);
      legendItems.add(
        _legendDot(_colorForRing(r, totalRings), '$label ($count)'),
      );
    }
    final totalCount = chart.nodes.length;

    // Canvas size
    final maxR = chart.radii.isNotEmpty ? chart.radii.last : 60.0;
    final canvasSize = (maxR + 160) * 2;
    final center = canvasSize / 2;

    return Column(
      children: [
        // Legend + total count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: legendItems,
              ),
              const SizedBox(height: 4),
              Text(
                '$totalCount employees',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // Chart
        Expanded(
          child: GestureDetector(
            onDoubleTap: _resetZoom,
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 0.08,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(800),
              child: SizedBox(
                width: canvasSize,
                height: canvasSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Connection lines
                    CustomPaint(
                      size: Size(canvasSize, canvasSize),
                      painter: _LinesPainter(
                        lines: chart.lines,
                        center: Offset(center, center),
                        isDark: isDark,
                      ),
                    ),

                    // Ring guide circles
                    for (int r = 1; r < chart.radii.length; r++)
                      Positioned(
                        left: center - chart.radii[r],
                        top: center - chart.radii[r],
                        child: IgnorePointer(
                          child: Container(
                            width: chart.radii[r] * 2,
                            height: chart.radii[r] * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _colorForRing(
                                  r,
                                  totalRings,
                                ).withValues(alpha: isDark ? 0.06 : 0.05),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Nodes
                    ...chart.nodes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final pn = entry.value;
                      final isCenter = pn.ring == 0;
                      final nodeSize = isCenter
                          ? 50.0
                          : (pn.ring == 1 ? 28.0 : 24.0);
                      final tagWidth = isCenter ? 130.0 : 110.0;
                      final widgetWidth = max(nodeSize * 2, tagWidth) + 10;

                      return Positioned(
                        left: center + pn.x - widgetWidth / 2,
                        top: center + pn.y - nodeSize - 5,
                        child:
                            GestureDetector(
                                  onTap: () => _showNodeDetail(pn.node),
                                  child: SizedBox(
                                    width: widgetWidth,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _NodeCircle(
                                          node: pn.node,
                                          size: nodeSize,
                                          color: pn.color,
                                          isCenter: isCenter,
                                        ),
                                        const SizedBox(height: 5),
                                        _NameTag(
                                          node: pn.node,
                                          color: pn.color,
                                          isDark: isDark,
                                          maxW: tagWidth,
                                          isCenter: isCenter,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  duration: 350.ms,
                                  delay: (pn.ring * 120 + idx * 20).ms,
                                )
                                .scale(
                                  begin: const Offset(0.5, 0.5),
                                  end: const Offset(1, 1),
                                  duration: 350.ms,
                                  delay: (pn.ring * 120 + idx * 20).ms,
                                ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
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

// ── Positioned data ─────────────────────────────────────────────
class _ChartData {
  final List<_PositionedNode> nodes;
  final List<_ConnectionLine> lines;
  final List<double> radii;
  const _ChartData(this.nodes, this.lines, this.radii);
}

class _PositionedNode {
  final _OrgNode node;
  final int ring;
  final double angle;
  final double x;
  final double y;
  final Color color;
  const _PositionedNode({
    required this.node,
    required this.ring,
    required this.angle,
    required this.x,
    required this.y,
    required this.color,
  });
}

class _ConnectionLine {
  final Offset from;
  final Offset to;
  final Color color;
  const _ConnectionLine({
    required this.from,
    required this.to,
    required this.color,
  });
}

// ── Node circle widget ──────────────────────────────────────────
class _NodeCircle extends StatelessWidget {
  final _OrgNode node;
  final double size;
  final Color color;
  final bool isCenter;

  const _NodeCircle({
    required this.node,
    required this.size,
    required this.color,
    required this.isCenter,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = node.avatarUrl != null && node.avatarUrl!.isNotEmpty;
    final diameter = size * 2;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCenter
            ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
            : null,
        color: isCenter ? null : color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isCenter ? 0.35 : 0.25),
            blurRadius: isCenter ? 20 : 8,
            spreadRadius: isCenter ? 3 : 1,
          ),
        ],
      ),
      child: hasAvatar
          ? CircleAvatar(
              radius: size - 2,
              backgroundImage: NetworkImage(node.avatarUrl!),
            )
          : Center(
              child: isCenter
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white,
                          size: size * 0.55,
                        ),
                        if (node.designation.isNotEmpty)
                          Text(
                            node.designation,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.16,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                      ],
                    )
                  : Text(
                      node.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.55,
                      ),
                    ),
            ),
    );
  }
}

// ── Name tag widget ─────────────────────────────────────────────
class _NameTag extends StatelessWidget {
  final _OrgNode node;
  final Color color;
  final bool isDark;
  final double maxW;
  final bool isCenter;

  const _NameTag({
    required this.node,
    required this.color,
    required this.isDark,
    required this.maxW,
    required this.isCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
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
              fontSize: isCenter ? 11 : 9,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (node.designation.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              node.designation,
              style: TextStyle(
                fontSize: isCenter ? 9 : 7,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (node.department.isNotEmpty) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                node.department,
                style: TextStyle(
                  fontSize: 7,
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

  int get totalDescendants {
    int count = children.length;
    for (final c in children) {
      count += c.totalDescendants;
    }
    return count;
  }

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
  final List<_ConnectionLine> lines;
  final Offset center;
  final bool isDark;

  const _LinesPainter({
    required this.lines,
    required this.center,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color.withValues(alpha: isDark ? 0.15 : 0.1)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final from = center + line.from;
      final to = center + line.to;
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
