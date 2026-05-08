import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/adaptive_colors.dart';
import '../../utils/platform_adaptive.dart';
import '../../utils/responsive.dart';
import '../../widgets/neu_card.dart';
import '../../providers/app_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildProfileAvatar(
    Map<String, dynamic> p,
    AppProvider provider,
    ThemeData theme,
    double radius,
  ) {
    final avatarUrl = p['avatar_url'] as String?;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final initials = provider.userName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();

    if (hasAvatar) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: theme.textTheme.headlineLarge?.copyWith(
          color: AppColors.primary,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _val(dynamic v, [String fallback = 'Not Provided']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = provider.userProfile;

    return Scaffold(
      appBar: adaptiveAppBar(
        context: context,
        title: 'My Profile',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchDashboardData(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: isApplePlatform
              ? const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : const AlwaysScrollableScrollPhysics(),
          child: ResponsiveCenter(
            maxWidth: 600,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              children: [
                // ── Profile Header ──
                Center(
                  child: Stack(
                    children: [
                      _buildProfileAvatar(p, provider, theme, 56),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(provider.userName, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  _val(p['designation'], provider.designation),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _val(p['employee_id'], provider.employeeId),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Quick info row
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _QuickInfo(
                        icon: Icons.wc_outlined,
                        label: 'Gender',
                        value: _val(p['gender']),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickInfo(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _val(p['email'], provider.email),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickInfo(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: _val(p['phone']),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickInfo(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: _val(p['role'], 'Employee'),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Tab Bar ──
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => setState(() {}),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Work Info'),
                      Tab(text: 'Personal'),
                      Tab(text: 'Emergency'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Tab Content ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildTabContent(p, theme, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    Map<String, dynamic> p,
    ThemeData theme,
    bool isDark,
  ) {
    switch (_tabController.index) {
      case 0:
        return _buildWorkInfo(p, theme, isDark);
      case 1:
        return _buildPersonalInfo(p, theme, isDark);
      case 2:
        return _buildEmergencyInfo(p, theme, isDark);
      default:
        return _buildWorkInfo(p, theme, isDark);
    }
  }

  Widget _buildWorkInfo(Map<String, dynamic> p, ThemeData theme, bool isDark) {
    final provider = context.read<AppProvider>();
    return NeuCard(
          key: const ValueKey('work'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _InfoGrid(
                children: [
                  _InfoItem(
                    icon: Icons.business_outlined,
                    label: 'Department',
                    value: _val(p['department'], provider.department),
                  ),
                  _InfoItem(
                    icon: Icons.work_outline_rounded,
                    label: 'Designation',
                    value: _val(p['designation'], provider.designation),
                  ),
                  _InfoItem(
                    icon: Icons.schedule_outlined,
                    label: 'Shift',
                    value: _val(p['shift']),
                  ),
                  _InfoItem(
                    icon: Icons.supervisor_account_outlined,
                    label: 'Reporting Manager',
                    value: p['reporting_manager'] != null
                        ? (p['reporting_manager']['name'] ?? 'Not assigned')
                        : 'Not assigned',
                  ),
                  _InfoItem(
                    icon: Icons.home_work_outlined,
                    label: 'Work Type',
                    value: _val(p['work_type']),
                  ),
                  _InfoItem(
                    icon: Icons.apartment_outlined,
                    label: 'Company',
                    value: _val(p['company']),
                  ),
                  _InfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date of Joining',
                    value: _val(p['date_of_joining']),
                  ),
                  _InfoItem(
                    icon: Icons.event_outlined,
                    label: 'Contract End',
                    value: _val(p['contract_end_date']),
                  ),
                  _InfoItem(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: _val(p['location']),
                  ),
                  _InfoItem(
                    icon: Icons.payments_outlined,
                    label: 'Basic Salary',
                    value: p['basic_salary'] != null
                        ? '\u20B9${p['basic_salary']}'
                        : 'Not Provided',
                  ),
                  _InfoItem(
                    icon: Icons.timer_outlined,
                    label: 'Salary/Hour',
                    value: p['salary_per_hour'] != null
                        ? '\u20B9${p['salary_per_hour']}'
                        : 'Not Provided',
                  ),
                  _InfoItem(
                    icon: Icons.trending_up_outlined,
                    label: 'Experience',
                    value: _val(p['experience']),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildPersonalInfo(
    Map<String, dynamic> p,
    ThemeData theme,
    bool isDark,
  ) {
    return NeuCard(
          key: const ValueKey('personal'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _InfoGrid(
                children: [
                  _InfoItem(
                    icon: Icons.cake_outlined,
                    label: 'Date of Birth',
                    value: _val(p['dob']),
                  ),
                  _InfoItem(
                    icon: Icons.school_outlined,
                    label: 'Qualification',
                    value: _val(p['qualification']),
                  ),
                  _InfoItem(
                    icon: Icons.favorite_outline,
                    label: 'Marital Status',
                    value: _val(p['marital_status']),
                  ),
                  _InfoItem(
                    icon: Icons.child_care_outlined,
                    label: 'Children',
                    value: _val(p['children'], 'None'),
                  ),
                  _InfoItem(
                    icon: Icons.wc_outlined,
                    label: 'Gender',
                    value: _val(p['gender']),
                  ),
                  _InfoItem(
                    icon: Icons.home_outlined,
                    label: 'Address',
                    value: _val(p['address']),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildEmergencyInfo(
    Map<String, dynamic> p,
    ThemeData theme,
    bool isDark,
  ) {
    return NeuCard(
          key: const ValueKey('emergency'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Contact',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _InfoGrid(
                children: [
                  _InfoItem(
                    icon: Icons.person_outline,
                    label: 'Contact Name',
                    value: _val(p['emergency_contact_name']),
                  ),
                  _InfoItem(
                    icon: Icons.phone_outlined,
                    label: 'Contact Number',
                    value: _val(p['emergency_contact']),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _QuickInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> children;
  const _InfoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 12),
              if (i + 1 < children.length)
                Expanded(child: children[i + 1])
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
