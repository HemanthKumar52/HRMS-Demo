import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

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
        (data['org_chart'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
      );
    } catch (e) {
      debugPrint('Org chart error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Organisation Chart'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadOrgChart,
              child: _roots.isEmpty
                  ? const Center(child: Text('No organisation data'))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: _roots.map((root) => _buildTree(root, isDark, 0)).toList(),
                        ),
                      ),
                    ),
            ),
    );
  }

  Widget _buildTree(Map<String, dynamic> node, bool isDark, int depth) {
    final children = List<Map<String, dynamic>>.from(
      (node['children'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? [],
    );
    final lineColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.3);

    return Column(
      children: [
        _buildNodeCard(node, isDark, depth),
        if (children.isNotEmpty) ...[
          // Vertical line down from parent
          Container(width: 2, height: 24, color: lineColor),
          // Horizontal line across children
          if (children.length > 1)
            Container(
              height: 2,
              width: children.length * 180.0,
              color: lineColor,
            ),
          // Children row with vertical connectors
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.asMap().entries.map((entry) {
              return SizedBox(
                width: 180,
                child: Column(
                  children: [
                    Container(width: 2, height: 16, color: lineColor),
                    _buildTree(entry.value, isDark, depth + 1),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms, delay: (depth * 100).ms);
  }

  Widget _buildNodeCard(Map<String, dynamic> node, bool isDark, int depth) {
    final name = node['name'] as String? ?? '';
    final designation = node['designation'] as String? ?? '';
    final department = node['department'] as String? ?? '';
    final avatarUrl = node['avatar_url'] as String?;
    final empId = node['employee_id'] as String? ?? '';
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

    final colors = [AppColors.primary, AppColors.secondary, AppColors.success, AppColors.orange, AppColors.pink];
    final accentColor = colors[depth % colors.length];

    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2030) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
            child: hasAvatar ? null : Text(initials,
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          // Name
          Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
            color: isDark ? Colors.white : Colors.black87),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          // Designation
          Text(designation.isNotEmpty ? designation : empId,
            style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (department.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(department, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: accentColor),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }
}
