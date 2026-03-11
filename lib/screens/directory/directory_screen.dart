import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String _searchQuery = '';

  // Only show employee's specific team hierarchy:
  // Team members, Team Lead, Manager, HR, System Admin, CEO, CTO
  static final _employees = <_Employee>[
    // Leadership
    _Employee(
      name: 'Rajesh Iyer',
      designation: 'CEO',
      role: 'Leadership',
      email: 'rajesh.iyer@ppulse.io',
      initials: 'RI',
      color: AppColors.danger,
    ),
    _Employee(
      name: 'Sarah Chen',
      designation: 'CTO',
      role: 'Leadership',
      email: 'sarah.chen@ppulse.io',
      initials: 'SC',
      color: AppColors.orange,
    ),
    // System Admin
    _Employee(
      name: 'Amit Desai',
      designation: 'System Administrator',
      role: 'IT Admin',
      email: 'amit.desai@ppulse.io',
      initials: 'AD',
      color: AppColors.primaryDark,
    ),
    // HR
    _Employee(
      name: 'Deepika Joshi',
      designation: 'HR Business Partner',
      role: 'HR',
      email: 'deepika.joshi@ppulse.io',
      initials: 'DJ',
      color: AppColors.pink,
    ),
    // Manager
    _Employee(
      name: 'James Wilson',
      designation: 'Engineering Manager',
      role: 'Manager',
      email: 'james.wilson@ppulse.io',
      initials: 'JW',
      color: AppColors.secondary,
    ),
    // Team Lead
    _Employee(
      name: 'Priya Sharma',
      designation: 'Team Lead',
      role: 'Team Lead',
      email: 'priya.sharma@ppulse.io',
      initials: 'PS',
      color: AppColors.primary,
    ),
    // Team Members
    _Employee(
      name: 'Venkat Kumar',
      designation: 'Senior Software Engineer',
      role: 'Team Member',
      email: 'venkat.kumar@ppulse.io',
      initials: 'VK',
      color: AppColors.success,
    ),
    _Employee(
      name: 'Kavya Menon',
      designation: 'Software Engineer',
      role: 'Team Member',
      email: 'kavya.menon@ppulse.io',
      initials: 'KM',
      color: AppColors.primary,
    ),
    _Employee(
      name: 'Rohan Das',
      designation: 'DevOps Engineer',
      role: 'Team Member',
      email: 'rohan.das@ppulse.io',
      initials: 'RD',
      color: AppColors.orange,
    ),
  ];

  List<_Employee> get _filtered {
    return _employees.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
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
      appBar: AppBar(
        title: const Text('My Team'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Container(
              decoration: NeuDecoration.card(context, radius: 16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search team members...',
                  hintStyle: theme.textTheme.bodyMedium,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: _filtered.isEmpty
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
                      return NeuCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  emp.color.withValues(alpha: 0.15),
                              child: Text(
                                emp.initials,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: emp.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp.name,
                                    style:
                                        theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    emp.designation,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _roleColor(emp.role)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          emp.role,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontSize: 10,
                                            color: _roleColor(emp.role),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.email_outlined,
                                        size: 12,
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.3)
                                            : Colors.black
                                                .withValues(alpha: 0.25),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          emp.email,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms, delay: (index * 60).ms).slideX(begin: 0.05, end: 0, duration: 350.ms, delay: (index * 60).ms, curve: Curves.easeOut);
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
  final String name;
  final String designation;
  final String role;
  final String email;
  final String initials;
  final Color color;

  const _Employee({
    required this.name,
    required this.designation,
    required this.role,
    required this.email,
    required this.initials,
    required this.color,
  });
}
