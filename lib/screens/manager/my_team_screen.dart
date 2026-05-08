import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../utils/responsive.dart';
import '../../widgets/neu_card.dart';
import 'employee_activity_screen.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getTeamMembers();
      if (!mounted) return;
      setState(() {
        _members = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _members;
    final q = _search.toLowerCase();
    return _members.where((m) {
      return (m['name'] ?? '').toString().toLowerCase().contains(q) ||
          (m['department'] ?? '').toString().toLowerCase().contains(q) ||
          (m['designation'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'on_leave':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'on_leave':
        return 'On Leave';
      default:
        return 'Absent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBg
          : theme.scaffoldBackgroundColor,
      appBar: adaptiveAppBar(
        context: context,
        title: 'Workforce',
        showBackButton: true,
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search by name, department...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No team members found',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final m = _filtered[index];
                      final name = m['name'] ?? '';
                      final status = m['today_status'] ?? 'absent';
                      final initials = name
                          .split(' ')
                          .map((w) => w.isNotEmpty ? w[0] : '')
                          .take(2)
                          .join()
                          .toUpperCase();
                      final color = [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.success,
                        AppColors.orange,
                        AppColors.pink,
                        AppColors.warning,
                      ][index % 6];

                      return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EmployeeActivityScreen(
                                    employeeId: m['id'] as int,
                                    name: name,
                                    initials: initials,
                                    color: color,
                                  ),
                                ),
                              );
                            },
                            child: NeuCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: color.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if ((m['designation'] ?? '')
                                                .toString()
                                                .isNotEmpty ||
                                            (m['department'] ?? '')
                                                .toString()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            [m['designation'], m['department']]
                                                .where(
                                                  (s) =>
                                                      s != null &&
                                                      s.toString().isNotEmpty,
                                                )
                                                .join(' · '),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey.shade600,
                                                ),
                                          ),
                                        ],
                                        if (m['reporting_manager'] != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Reports to: ${m['reporting_manager']}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        status,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: (index * 40).ms,
                          )
                          .slideX(
                            begin: 0.05,
                            end: 0,
                            duration: 300.ms,
                            delay: (index * 40).ms,
                          );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
