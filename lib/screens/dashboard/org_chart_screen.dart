import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';

// ── Pastel avatar colors (consistent per person) ──
const _avatarColors = [
  Color(0xFF4F8EF7), // blue
  Color(0xFF7C5CFC), // purple
  Color(0xFF34D399), // green
  Color(0xFFFF8C42), // orange
  Color(0xFFEC4899), // pink
  Color(0xFFEF4444), // red
  Color(0xFF06B6D4), // teal
  Color(0xFFF59E0B), // amber
];

class OrgChartScreen extends StatefulWidget {
  const OrgChartScreen({super.key});

  @override
  State<OrgChartScreen> createState() => _OrgChartScreenState();
}

class _OrgChartScreenState extends State<OrgChartScreen> {
  bool _isLoading = true;
  List<_OrgNode> _roots = [];
  int? _loggedInUserId;
  final Set<int> _expanded = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.get('/org-chart');
      final list = (data['org_chart'] as List?) ?? [];
      if (!mounted) return;
      final roots = list.map((e) => _OrgNode.fromJson(e)).toList();

      // Highlight the logged-in user.
      final userName = context.read<AppProvider>().userName;
      _OrgNode? me;
      void find(List<_OrgNode> ns) {
        for (final n in ns) {
          if (n.name == userName) me = n;
          find(n.children);
        }
      }

      find(roots);

      // Expand everything by default so the whole tree is visible.
      final expanded = <int>{};
      void collect(List<_OrgNode> ns) {
        for (final n in ns) {
          if (n.children.isNotEmpty) expanded.add(n.id);
          collect(n.children);
        }
      }

      collect(roots);

      setState(() {
        _roots = roots;
        _loggedInUserId = me?.id;
        _expanded
          ..clear()
          ..addAll(expanded);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _toggle(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Set<int> _allParentIds() {
    final ids = <int>{};
    void walk(List<_OrgNode> ns) {
      for (final n in ns) {
        if (n.children.isNotEmpty) ids.add(n.id);
        walk(n.children);
      }
    }

    walk(_roots);
    return ids;
  }

  void _expandAll() {
    HapticFeedback.selectionClick();
    setState(() => _expanded
      ..clear()
      ..addAll(_allParentIds()));
  }

  void _collapseAll() {
    HapticFeedback.selectionClick();
    // Keep the root(s) open so something is always visible.
    setState(() {
      _expanded
        ..clear()
        ..addAll(_roots.where((r) => r.children.isNotEmpty).map((r) => r.id));
    });
  }

  // Flatten the tree into the currently-visible rows.
  List<_FlatRow> _visibleRows() {
    final out = <_FlatRow>[];
    void walk(_OrgNode node, int depth, List<bool> ancestorHasNext) {
      out.add(_FlatRow(node, depth, List<bool>.from(ancestorHasNext)));
      if (_expanded.contains(node.id)) {
        for (var i = 0; i < node.children.length; i++) {
          final isLast = i == node.children.length - 1;
          walk(node.children[i], depth + 1, [...ancestorHasNext, !isLast]);
        }
      }
    }

    for (final r in _roots) {
      walk(r, 0, const []);
    }
    return out;
  }

  Color _avatarColor(int id) => _avatarColors[id % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rows = _visibleRows();
    final allExpanded = _expanded.length >= _allParentIds().length;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBg
          : theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Organisation Chart',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              allExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              size: 22,
            ),
            tooltip: allExpanded ? 'Collapse all' : 'Expand all',
            onPressed: allExpanded ? _collapseAll : _expandAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? const Center(child: Text('No org chart data'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
              itemCount: rows.length,
              itemBuilder: (context, i) =>
                  _buildRow(rows[i], isDark, theme),
            ),
    );
  }

  Widget _buildRow(_FlatRow row, bool isDark, ThemeData theme) {
    final node = row.node;
    final depth = row.depth;
    final isMe = node.id == _loggedInUserId;
    final hasChildren = node.children.isNotEmpty;
    final expanded = _expanded.contains(node.id);
    final color = _avatarColor(node.id);

    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: hasChildren ? () => _toggle(node.id) : null,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indentation guide lines for each ancestor level.
                for (var d = 0; d < depth; d++)
                  SizedBox(
                    width: 22,
                    child: Center(
                      child: Container(
                        width: 1.5,
                        // Hide the line for the last child's trailing levels
                        // so the tree doesn't show dangling verticals.
                        color: (d == depth - 1 || row.ancestorHasNext[d])
                            ? lineColor
                            : Colors.transparent,
                      ),
                    ),
                  ),

                // The person card.
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF06B6D4).withValues(
                              alpha: isDark ? 0.12 : 0.08,
                            )
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMe
                            ? const Color(0xFF06B6D4)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.grey.withValues(alpha: 0.14)),
                        width: isMe ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Expand / collapse chevron (or a dot for leaves).
                        SizedBox(
                          width: 24,
                          child: hasChildren
                              ? AnimatedRotation(
                                  turns: expanded ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey.shade600,
                                  ),
                                )
                              : Center(
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 4),

                        // Avatar.
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withValues(alpha: 0.16),
                          backgroundImage: node.avatarUrl.isNotEmpty
                              ? NetworkImage(node.avatarUrl)
                              : null,
                          child: node.avatarUrl.isEmpty
                              ? Text(
                                  node.initials,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Name + designation + department.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      node.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF06B6D4,
                                        ).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'You',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF06B6D4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (node.designation.isNotEmpty ||
                                  node.department.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    [
                                      if (node.designation.isNotEmpty)
                                        node.designation,
                                      if (node.department.isNotEmpty)
                                        node.department,
                                    ].join('  ·  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Direct-report count badge.
                        if (hasChildren) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  size: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${node.children.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Flattened visible row ──
class _FlatRow {
  final _OrgNode node;
  final int depth;

  /// For each ancestor depth, whether that ancestor has a following sibling
  /// (used to decide whether to draw the vertical guide line).
  final List<bool> ancestorHasNext;

  _FlatRow(this.node, this.depth, this.ancestorHasNext);
}

// ── Data Model ──
class _OrgNode {
  final int id;
  final String name;
  final String designation;
  final String department;
  final String avatarUrl;
  final List<_OrgNode> children;

  const _OrgNode({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.avatarUrl,
    required this.children,
  });

  factory _OrgNode.fromJson(Map<String, dynamic> json) {
    return _OrgNode(
      id: (json['id'] is int)
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      avatarUrl: json['avatar_url'] is String
          ? json['avatar_url'] as String
          : '',
      children: ((json['children'] as List?) ?? [])
          .map((c) => _OrgNode.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
