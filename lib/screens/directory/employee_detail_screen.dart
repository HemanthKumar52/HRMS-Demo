import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../utils/responsive.dart';
import '../../widgets/neu_card.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String name;
  final String initials;
  final Color color;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.name,
    required this.initials,
    required this.color,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getEmployee(widget.employeeId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
        title: widget.name,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
          ? Center(
              child: Text(
                'Could not load profile',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: isApplePlatform
                    ? const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      )
                    : const AlwaysScrollableScrollPhysics(),
                child: ResponsiveCenter(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    children: [
                      _buildHeader(theme, isDark),
                      const SizedBox(height: 20),
                      _buildWorkInfo(theme, isDark),
                      const SizedBox(height: 16),
                      _buildPersonalInfo(theme, isDark),
                      const SizedBox(height: 16),
                      _buildContactInfo(theme, isDark),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final d = _data!;
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: widget.color.withValues(alpha: 0.15),
          child: Text(
            widget.initials,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: widget.color,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          d['name'] ?? widget.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          d['designation'] ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            d['employee_id'] ?? '',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWorkInfo(ThemeData theme, bool isDark) {
    final d = _data!;
    final manager = d['reporting_manager'];
    return NeuCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _infoRow(
                Icons.business_rounded,
                'Department',
                d['department'] ?? 'N/A',
                isDark,
              ),
              _infoRow(
                Icons.work_outline_rounded,
                'Designation',
                d['designation'] ?? 'N/A',
                isDark,
              ),
              _infoRow(
                Icons.calendar_today_rounded,
                'Joined',
                d['date_of_joining'] ?? 'N/A',
                isDark,
              ),
              if (manager != null)
                _infoRow(
                  Icons.person_outline_rounded,
                  'Reports To',
                  manager['name'] ?? 'N/A',
                  isDark,
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildPersonalInfo(ThemeData theme, bool isDark) {
    final d = _data!;
    return NeuCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _infoRow(
                Icons.cake_rounded,
                'Date of Birth',
                d['dob'] ?? 'N/A',
                isDark,
              ),
              _infoRow(
                Icons.person_rounded,
                'Gender',
                d['gender'] ?? 'N/A',
                isDark,
              ),
              _infoRow(
                Icons.school_rounded,
                'Qualification',
                d['qualification'] ?? 'N/A',
                isDark,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildContactInfo(ThemeData theme, bool isDark) {
    final d = _data!;
    return NeuCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _infoRow(
                Icons.email_outlined,
                'Email',
                d['email'] ?? 'N/A',
                isDark,
              ),
              _infoRow(
                Icons.phone_outlined,
                'Phone',
                d['phone'] ?? 'N/A',
                isDark,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
