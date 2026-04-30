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
  List<_OrgNode> _allRoots = [];
  _OrgNode? _viewRoot; // Currently displayed root
  int? _loggedInUserId;
  final List<_OrgNode> _navStack = []; // Breadcrumb for back navigation

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

      // Find logged-in user
      final userName = context.read<AppProvider>().userName;
      _OrgNode? loggedIn;
      _findNode(roots, userName, (node) => loggedIn = node);

      setState(() {
        _allRoots = roots;
        // Always start from root, highlight logged-in user
        _viewRoot = roots.isNotEmpty ? roots.first : null;
        _loggedInUserId = loggedIn?.id;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _findNode(
    List<_OrgNode> nodes,
    String name,
    void Function(_OrgNode) onFound,
  ) {
    for (final n in nodes) {
      if (n.name == name) {
        onFound(n);
        return;
      }
      _findNode(n.children, name, onFound);
    }
  }

  _OrgNode? _findParentOf(_OrgNode target, List<_OrgNode> nodes) {
    for (final n in nodes) {
      for (final c in n.children) {
        if (c.id == target.id) return n;
      }
      final result = _findParentOf(target, n.children);
      if (result != null) return result;
    }
    return null;
  }

  void _drillInto(_OrgNode node) {
    if (node.children.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _navStack.add(_viewRoot!);
      _viewRoot = node;
    });
  }

  void _goBack() {
    if (_navStack.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _viewRoot = _navStack.removeLast();
    });
  }

  void _goToRoot() {
    if (_allRoots.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _navStack.clear();
      _viewRoot = _allRoots.first;
    });
  }

  Color _avatarColor(int id) => _avatarColors[id % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFD1D5DB);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBg
          : theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Organisation Chart',
        showBackButton: true,
        actions: [
          if (_navStack.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 22),
              tooltip: 'Go to root',
              onPressed: _goToRoot,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _viewRoot == null
          ? const Center(child: Text('No org chart data'))
          : Column(
              children: [
                // Breadcrumb bar
                if (_navStack.isNotEmpty)
                  _BreadcrumbBar(
                    stack: _navStack,
                    current: _viewRoot!,
                    isDark: isDark,
                    onTap: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _viewRoot = _navStack[index];
                        _navStack.removeRange(index, _navStack.length);
                      });
                    },
                    onBack: _goBack,
                  ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Parent card (who this person reports to) ──
                        if (_navStack.isNotEmpty) ...[
                          _buildReportsToLabel(isDark),
                          const SizedBox(height: 8),
                          _OrgPersonCard(
                            node: _navStack.last,
                            isDark: isDark,
                            isMe: _navStack.last.id == _loggedInUserId,
                            isRoot: false,
                            avatarColor: _avatarColor(_navStack.last.id),
                            onTap: () => _goBack(),
                          ),
                          const SizedBox(height: 4),
                          // Connector line down
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Container(
                              width: 2,
                              height: 20,
                              color: lineColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // ── Current focused person ──
                        _OrgPersonCard(
                          node: _viewRoot!,
                          isDark: isDark,
                          isMe: _viewRoot!.id == _loggedInUserId,
                          isRoot: true,
                          avatarColor: _avatarColor(_viewRoot!.id),
                          onTap: null,
                        ),

                        // ── Direct reports with L-connectors ──
                        if (_viewRoot!.children.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildChildrenList(
                            _viewRoot!.children,
                            isDark,
                            lineColor,
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(left: 44, top: 20),
                            child: Text(
                              'No direct reports',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportsToLabel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        'Reports to',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildChildrenList(
    List<_OrgNode> children,
    bool isDark,
    Color lineColor,
  ) {
    return CustomPaint(
      painter: _LConnectorPainter(
        itemCount: children.length,
        lineColor: lineColor,
        itemHeight: 76, // card height + spacing
        startOffset: 0,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    // Horizontal connector stub
                    Container(
                      width: 24,
                      height: 2,
                      color: lineColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _OrgPersonCard(
                        node: children[i],
                        isDark: isDark,
                        isMe: children[i].id == _loggedInUserId,
                        isRoot: false,
                        avatarColor: _avatarColor(children[i].id),
                        onTap: children[i].children.isNotEmpty
                            ? () => _drillInto(children[i])
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── L-shaped connector painter ──

class _LConnectorPainter extends CustomPainter {
  final int itemCount;
  final Color lineColor;
  final double itemHeight;
  final double startOffset;

  _LConnectorPainter({
    required this.itemCount,
    required this.lineColor,
    required this.itemHeight,
    required this.startOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount == 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Vertical line from top to last item
    const x = 0.0;
    final lastItemY =
        startOffset + (itemCount - 1) * itemHeight + itemHeight / 2;

    canvas.drawLine(
      Offset(x, startOffset),
      Offset(x, lastItemY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LConnectorPainter old) =>
      old.itemCount != itemCount || old.lineColor != lineColor;
}

// ── Breadcrumb bar ──

class _BreadcrumbBar extends StatelessWidget {
  final List<_OrgNode> stack;
  final _OrgNode current;
  final bool isDark;
  final void Function(int) onTap;
  final VoidCallback onBack;

  const _BreadcrumbBar({
    required this.stack,
    required this.current,
    required this.isDark,
    required this.onTap,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < stack.length; i++) ...[
                    GestureDetector(
                      onTap: () => onTap(i),
                      child: Text(
                        stack[i].name.split(' ').first,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                  Text(
                    current.name.split(' ').first,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Person Card (Frappe-style) ──

class _OrgPersonCard extends StatelessWidget {
  final _OrgNode node;
  final bool isDark;
  final bool isMe;
  final bool isRoot;
  final Color avatarColor;
  final VoidCallback? onTap;

  const _OrgPersonCard({
    required this.node,
    required this.isDark,
    required this.isMe,
    required this.isRoot,
    required this.avatarColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Highlight colors
    final Color borderColor;
    final Color bgColor;

    if (isMe) {
      // Logged-in user — teal/green highlight
      borderColor = const Color(0xFF06B6D4);
      bgColor = isDark
          ? const Color(0xFF06B6D4).withValues(alpha: 0.08)
          : const Color(0xFF06B6D4).withValues(alpha: 0.04);
    } else if (isRoot) {
      // Current view root — primary blue highlight
      borderColor = AppColors.primary;
      bgColor = isDark
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.primary.withValues(alpha: 0.04);
    } else {
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.15);
      bgColor = isDark ? AppColors.darkCard : Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: (isMe || isRoot) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              backgroundImage: node.avatarUrl.isNotEmpty
                  ? NetworkImage(node.avatarUrl)
                  : null,
              child: node.avatarUrl.isEmpty
                  ? Text(
                      node.initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: avatarColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Name + designation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (node.designation.isNotEmpty)
                    Text(
                      node.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

            // Report count + drill arrow
            if (node.totalReports > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${node.totalReports}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ],
              ),

            if (onTap != null && node.children.isNotEmpty) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }
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
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  int get totalReports {
    int count = children.length;
    for (final c in children) {
      count += c.totalReports;
    }
    return count;
  }
}
