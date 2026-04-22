import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';

// ── Corporate Hierarchy Org Chart ─────────────────────────────────
// Proper corporate structure: CEO at center, then C-suite ring,
// Directors/Board ring, HR/Managers ring, Team Leads ring, Employees ring.
// Nodes classified by designation tier, not just BFS depth.
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

  // ── Designation tier classification ──────────────────────────────
  // Maps designation keywords to tier index:
  //   0 = CEO/MD/Founder (center)
  //   1 = C-suite (CTO, CFO, CPO, COO, CMO, CIO, CHRO)
  //   2 = Board/VP/Director
  //   3 = HR/System Admin/Senior Manager
  //   4 = Manager/Team Lead
  //   5 = Employee/Developer/Tester/Engineer/Designer/Analyst
  static int _tierForDesignation(String designation, int bfsDepth) {
    final d = designation.toLowerCase().trim();

    // Tier 0: CEO / Managing Director / Founder
    if (d.contains('ceo') ||
        d.contains('chief executive') ||
        d.contains('managing director') ||
        d.contains('founder') ||
        d.contains('president') ||
        d.contains('chairperson') ||
        d.contains('chairman')) {
      return 0;
    }

    // Tier 1: C-Suite
    if (d.startsWith('c') && d.length <= 4 && !d.contains(' '))
      return 1; // CTO, CFO, CPO, COO, CMO, CIO
    if (d.contains('chief ') ||
        d.contains('cto') ||
        d.contains('cfo') ||
        d.contains('cpo') ||
        d.contains('coo') ||
        d.contains('cmo') ||
        d.contains('cio') ||
        d.contains('chro') ||
        d.contains('cso')) {
      return 1;
    }

    // Tier 2: Board / VP / Director
    if (d.contains('board') ||
        d.contains('vice president') ||
        d.contains('vp ') ||
        d.endsWith(' vp') ||
        d == 'vp' ||
        d.contains('director') ||
        d.contains('head of') ||
        d.contains('avp')) {
      return 2;
    }

    // Tier 3: HR / System Admin / Senior Manager
    if (d.contains('hr ') ||
        d.startsWith('hr') ||
        d.contains('human resource') ||
        d.contains('system admin') ||
        d.contains('senior manager') ||
        d.contains('general manager') ||
        d.contains('gm') ||
        d.contains('admin')) {
      return 3;
    }

    // Tier 4: Manager / Team Lead / Lead
    if (d.contains('manager') ||
        d.contains('team lead') ||
        d.contains('tech lead') ||
        d.contains('lead') ||
        d.contains('supervisor') ||
        d.contains('coordinator')) {
      return 4;
    }

    // Tier 5: Employees — everyone else
    return 5;
  }

  // ── Build chart from tree data ────────────────────────────────
  _ChartData _buildChart() {
    if (_rawRoots.isEmpty) return const _ChartData([], [], []);

    final roots = _rawRoots.map(_OrgNode.fromMap).toList();

    // Flatten entire tree via BFS
    final allNodes = <_OrgNode>[];
    final parentMap = <_OrgNode, _OrgNode?>{}; // child -> parent
    void flattenBFS(List<_OrgNode> nodes, _OrgNode? parent, int depth) {
      for (final node in nodes) {
        node.bfsDepth = depth;
        allNodes.add(node);
        parentMap[node] = parent;
        flattenBFS(node.children, node, depth + 1);
      }
    }

    flattenBFS(roots, null, 0);

    // Classify each node into a tier based on designation
    for (final node in allNodes) {
      node.tier = _tierForDesignation(node.designation, node.bfsDepth);
    }

    // If no CEO found, promote the root with most descendants to tier 0
    if (!allNodes.any((n) => n.tier == 0)) {
      roots.sort((a, b) => b.totalDescendants.compareTo(a.totalDescendants));
      roots.first.tier = 0;
    }

    // Group nodes by tier
    final tierMap = <int, List<_OrgNode>>{};
    for (final node in allNodes) {
      tierMap.putIfAbsent(node.tier, () => []).add(node);
    }

    // Build ordered rings (skip empty tiers)
    final activeTiers = tierMap.keys.toList()..sort();
    final rings = <List<_OrgNode>>[];
    final tierToRing = <int, int>{};
    for (final tier in activeTiers) {
      tierToRing[tier] = rings.length;
      rings.add(tierMap[tier]!);
    }

    // Compute radii
    const minNodeArc = 140.0;
    const minRingGap = 180.0;
    final radii = <double>[0.0]; // ring 0 is center
    for (int r = 1; r < rings.length; r++) {
      final count = rings[r].length;
      final needed = (count * minNodeArc) / (2 * pi);
      final minR = radii[r - 1] + minRingGap;
      radii.add(max(needed, minR));
    }

    // Position nodes
    final nodes = <_PositionedNode>[];
    final nodeIndexMap = <_OrgNode, int>{}; // node -> global index

    for (int r = 0; r < rings.length; r++) {
      final ring = rings[r];
      if (r == 0 && ring.length == 1) {
        // Center node
        final globalIdx = nodes.length;
        nodeIndexMap[ring[0]] = globalIdx;
        nodes.add(
          _PositionedNode(
            node: ring[0],
            ring: r,
            angle: 0,
            x: 0,
            y: 0,
            color: _tierColors[activeTiers[r] % _tierColors.length],
          ),
        );
      } else {
        final count = ring.length;
        for (int i = 0; i < count; i++) {
          final angle = (2 * pi * i / count) - (pi / 2);
          final x = radii[r] * cos(angle);
          final y = radii[r] * sin(angle);
          final globalIdx = nodes.length;
          nodeIndexMap[ring[i]] = globalIdx;
          nodes.add(
            _PositionedNode(
              node: ring[i],
              ring: r,
              angle: angle,
              x: x,
              y: y,
              color: _tierColors[activeTiers[r] % _tierColors.length],
            ),
          );
        }
      }
    }

    // Build connection lines from parent map
    final lines = <_ConnectionLine>[];
    for (final entry in parentMap.entries) {
      final child = entry.key;
      final parent = entry.value;
      if (parent == null) continue;
      final childIdx = nodeIndexMap[child];
      final parentIdx = nodeIndexMap[parent];
      if (childIdx != null && parentIdx != null) {
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

  // Tier colors — corporate hierarchy
  static const _tierColors = [
    Color(0xFFD4AF37), // CEO/Founder — gold
    Color(0xFF7C3AED), // C-Suite — purple
    Color(0xFF2563EB), // Directors/VP — blue
    Color(0xFF059669), // HR/Senior Mgmt — green
    Color(0xFF0891B2), // Manager/TL — cyan
    Color(0xFFE97451), // Employees — coral
  ];

  // Tier labels
  static const _tierLabels = [
    'CEO / Founder',
    'C-Suite',
    'Directors / VP',
    'HR / Senior Management',
    'Managers / Team Leads',
    'Employees',
  ];

  String _labelForRing(int ring, List<int> activeTiers) {
    if (ring < activeTiers.length) {
      final tier = activeTiers[ring];
      if (tier < _tierLabels.length) return _tierLabels[tier];
    }
    return 'Level ${ring + 1}';
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    HapticFeedback.lightImpact();
  }

  void _showNodeDetail(_OrgNode node) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tierColor = _tierColors[node.tier % _tierColors.length];

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
              backgroundColor: tierColor.withValues(alpha: 0.15),
              backgroundImage:
                  node.avatarUrl != null && node.avatarUrl!.isNotEmpty
                  ? NetworkImage(node.avatarUrl!)
                  : null,
              child: node.avatarUrl == null || node.avatarUrl!.isEmpty
                  ? Text(
                      node.initials,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: tierColor,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.designation,
                  style: TextStyle(
                    color: tierColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            if (node.department.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.department,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _tierLabels[node.tier % _tierLabels.length],
              style: TextStyle(
                fontSize: 11,
                color: tierColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (node.children.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${node.children.length} direct report(s)',
                style: theme.textTheme.bodySmall,
              ),
            ],
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
      appBar: adaptiveAppBar(
        context: context,
        title: 'Organisation Chart',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              isApplePlatform
                  ? CupertinoIcons.arrow_counterclockwise
                  : Icons.fit_screen_rounded,
            ),
            tooltip: 'Reset zoom',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: isApplePlatform
                  ? const CupertinoActivityIndicator(radius: 14)
                  : const CircularProgressIndicator(color: AppColors.primary),
            )
          : _rawRoots.isEmpty
          ? const Center(child: Text('No organisation data'))
          : _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    final chart = _buildChart();
    if (chart.nodes.isEmpty) return const Center(child: Text('No data'));

    // Get active tiers for legend
    final activeTierSet = <int>{};
    for (final n in chart.nodes) {
      activeTierSet.add(n.node.tier);
    }
    final activeTiers = activeTierSet.toList()..sort();

    // Legend
    final legendItems = <Widget>[];
    for (final tier in activeTiers) {
      final count = chart.nodes.where((n) => n.node.tier == tier).length;
      final label = tier < _tierLabels.length
          ? _tierLabels[tier]
          : 'Level ${tier + 1}';
      final color = _tierColors[tier % _tierColors.length];
      legendItems.add(_legendDot(color, '$label ($count)'));
    }

    // Canvas size
    final maxR = chart.radii.isNotEmpty ? chart.radii.last : 60.0;
    final canvasSize = (maxR + 200) * 2;
    final center = canvasSize / 2;

    return Column(
      children: [
        // Legend
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
                '${chart.nodes.length} employees',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // Chart — auto-fit to viewport on first render
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Auto-fit: scale so entire chart fits in viewport
              final viewW = constraints.maxWidth;
              final viewH = constraints.maxHeight;
              final scaleX = viewW / canvasSize;
              final scaleY = viewH / canvasSize;
              final fitScale = min(scaleX, scaleY) * 0.92;

              // Set initial transform to center and fit
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_transformCtrl.value == Matrix4.identity()) {
                  final dx = (viewW - canvasSize * fitScale) / 2;
                  final dy = (viewH - canvasSize * fitScale) / 2;
                  _transformCtrl.value = Matrix4.identity()
                    ..setEntry(0, 3, dx)
                    ..setEntry(1, 3, dy)
                    ..setEntry(0, 0, fitScale)
                    ..setEntry(1, 1, fitScale)
                    ..setEntry(2, 2, fitScale);
                }
              });

              return GestureDetector(
                onDoubleTap: () {
                  // Double-tap toggles between fit-all and 1:1
                  final dx = (viewW - canvasSize * fitScale) / 2;
                  final dy = (viewH - canvasSize * fitScale) / 2;
                  _transformCtrl.value = Matrix4.identity()
                    ..setEntry(0, 3, dx)
                    ..setEntry(1, 3, dy)
                    ..setEntry(0, 0, fitScale)
                    ..setEntry(1, 1, fitScale)
                    ..setEntry(2, 2, fitScale);
                  HapticFeedback.lightImpact();
                },
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  minScale: 0.02,
                  maxScale: 8.0,
                  boundaryMargin: const EdgeInsets.all(2000),
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

                        // Ring guide circles with tier labels
                        for (int r = 1; r < chart.radii.length; r++)
                          Positioned(
                            left: center - chart.radii[r],
                            top: center - chart.radii[r],
                            child: IgnorePointer(
                              child: SizedBox(
                                width: chart.radii[r] * 2,
                                height: chart.radii[r] * 2,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: chart.nodes
                                              .firstWhere(
                                                (n) => n.ring == r,
                                                orElse: () => chart.nodes.first,
                                              )
                                              .color
                                              .withValues(
                                                alpha: isDark ? 0.08 : 0.06,
                                              ),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    // Ring label at top
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.black.withValues(
                                                    alpha: 0.6,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.8,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _labelForRing(r, activeTiers),
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                              : (pn.node.tier <= 1 ? 30.0 : 24.0);
                          final tagWidth = isCenter ? 140.0 : 120.0;
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
              );
            },
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

// ── Data structures ────────────────────────────────────────────────
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

// ── Node circle widget ─────────────────────────────────────────────
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
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              )
            : null,
        color: isCenter ? null : color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isCenter ? 0.4 : 0.25),
            blurRadius: isCenter ? 24 : 8,
            spreadRadius: isCenter ? 4 : 1,
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
                          size: size * 0.5,
                        ),
                        if (node.designation.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              node.designation,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size * 0.14,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
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

// ── Name tag widget ────────────────────────────────────────────────
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

// ── Data model ─────────────────────────────────────────────────────
class _OrgNode {
  final String name;
  final String designation;
  final String department;
  final String? avatarUrl;
  final String initials;
  final List<_OrgNode> children;
  int tier; // assigned during chart building
  int bfsDepth; // BFS depth from root

  _OrgNode({
    required this.name,
    required this.designation,
    required this.department,
    this.avatarUrl,
    required this.initials,
    required this.children,
    this.tier = 5,
    this.bfsDepth = 0,
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

// ── Lines painter ──────────────────────────────────────────────────
class _LinesPainter extends CustomPainter {
  final List<_ConnectionLine> lines;
  final Offset center;
  final bool isDark;

  _LinesPainter({
    required this.lines,
    required this.center,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color.withValues(alpha: isDark ? 0.15 : 0.12)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final from = center + line.from;
      final to = center + line.to;

      // Curved bezier line
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final ctrl = Offset(
        mid.dx + (to.dy - from.dy) * 0.15,
        mid.dy - (to.dx - from.dx) * 0.15,
      );

      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) => lines != old.lines;
}
