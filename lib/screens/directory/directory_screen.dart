import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../animations/skeleton_loading.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/neu_card.dart';
import 'employee_detail_screen.dart';
import '../dashboard/org_chart_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String _searchQuery = '';
  List<_Employee> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _departmentColor(String department) {
    switch (department.toLowerCase()) {
      case 'engineering':
        return AppColors.primary;
      case 'hr':
      case 'human resources':
        return AppColors.pink;
      case 'it':
      case 'it admin':
        return AppColors.primaryDark;
      case 'management':
      case 'leadership':
        return AppColors.danger;
      case 'finance':
        return AppColors.success;
      case 'marketing':
        return AppColors.orange;
      case 'design':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await ApiService.getEmployees();
      if (!mounted) return;
      setState(() {
        _employees = data.map<_Employee>((e) {
          final id = (e['id'] is int)
              ? e['id'] as int
              : int.tryParse(e['id']?.toString() ?? '0') ?? 0;
          final name = e['name'] ?? '';
          final designation = e['designation'] ?? '';
          final department = e['department'] ?? '';
          final email = e['email'] ?? '';
          return _Employee(
            id: id,
            name: name,
            designation: designation,
            role: department,
            email: email,
            initials: _getInitials(name),
            color: _departmentColor(department),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<_Employee> get _filtered {
    return _employees.where((e) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.designation.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: adaptiveAppBar(
        context: context,
        title: 'Directory',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded, size: 22),
            tooltip: 'Organisation Chart',
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                adaptivePageRoute(child: const OrgChartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: isApplePlatform
                ? CupertinoSearchTextField(
                    placeholder: 'Search by name, email, department...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                  )
                : Container(
                    decoration: NeuDecoration.card(context, radius: 16),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, department...',
                        hintStyle: theme.textTheme.bodyMedium,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
          ),

          // Info text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your reporting team & key contacts',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Employee list
          Expanded(
            child: _isLoading
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SkeletonList(itemCount: 5, showCircle: true),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No team members found',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final emp = _filtered[index];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmployeeDetailScreen(
                                employeeId: emp.id,
                                name: emp.name,
                                initials: emp.initials,
                                color: emp.color,
                              ),
                            ),
                          );
                        },
                        child:
                            NeuCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: emp.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        child: Text(
                                          emp.initials,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: emp.color,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    emp.name,
                                                    style: theme
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                // Designation badge — right top corner
                                                if (emp.designation.isNotEmpty)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.08,
                                                                )
                                                          : Colors.grey
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      emp.designation,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (emp.role.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _roleColor(
                                                    emp.role,
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6,
                                                      ),
                                                ),
                                                child: Text(
                                                  emp.role,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontSize: 10,
                                                        color: _roleColor(
                                                          emp.role,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  duration: 350.ms,
                                  delay: (index * 60).ms,
                                )
                                .slideX(
                                  begin: 0.05,
                                  end: 0,
                                  duration: 350.ms,
                                  delay: (index * 60).ms,
                                  curve: Curves.easeOutCubic,
                                ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Leadership':
        return AppColors.danger;
      case 'IT Admin':
        return AppColors.primaryDark;
      case 'HR':
        return AppColors.pink;
      case 'Manager':
        return AppColors.secondary;
      case 'Team Lead':
        return AppColors.primary;
      case 'Team Member':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

class _Employee {
  final int id;
  final String name;
  final String designation;
  final String role;
  final String email;
  final String initials;
  final Color color;

  const _Employee({
    required this.id,
    required this.name,
    required this.designation,
    required this.role,
    required this.email,
    required this.initials,
    required this.color,
  });
}
