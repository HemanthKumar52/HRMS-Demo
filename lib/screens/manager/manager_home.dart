import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../home/face_verification_dialog.dart';

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Home', 'Team', 'Attendance', 'Leave'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final myView = provider.isMyView;

    return Column(
      children: [
        // View Toggle: Manager / My View
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _buildViewToggle(isDark)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),
        const SizedBox(height: 8),
        if (!myView) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _buildTabBar(isDark)
                .animate()
                .fadeIn(duration: 400.ms, delay: 0.ms)
                .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    delay: 0.ms,
                    curve: Curves.easeOut),
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: myView
                ? _buildMyView(theme, isDark)
                : _buildTabContent(theme, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle(bool isDark) {
    final provider = context.watch<AppProvider>();
    final isMyView = provider.isMyView;
    return NeuCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setMyView(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isMyView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 18,
                      color: !isMyView
                          ? Colors.white
                          : isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Manager View',
                      style: TextStyle(
                        color: !isMyView
                            ? Colors.white
                            : isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => provider.setMyView(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isMyView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: isMyView
                          ? Colors.white
                          : isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'My View',
                      style: TextStyle(
                        color: isMyView
                            ? Colors.white
                            : isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MY VIEW - Employee-like personal view
  // ===========================================================================
  Widget _buildMyView(ThemeData theme, bool isDark) {
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Good ${_getGreeting()},',
            style: theme.textTheme.bodyMedium,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 2),
          Text(
            provider.userName.split(' ').first,
            style: theme.textTheme.headlineLarge,
          ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 80.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // Punch In/Out Card
          _buildPunchCard(provider, theme, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 160.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pastelBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('Leave Balance', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('14', style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.primary)),
                      Text('Days remaining', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pastelGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.trending_up, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(height: 12),
                      Text('Attendance', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('98%', style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.success)),
                      Text('This month', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // My Leave Summary
          NeuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.pastelPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('My Leave Summary', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildLeaveChip('Casual', 2, 8, AppColors.primary, isDark),
                    const SizedBox(width: 10),
                    _buildLeaveChip('Sick', 1, 6, AppColors.orange, isDark),
                    const SizedBox(width: 10),
                    _buildLeaveChip('Earned', 3, 10, AppColors.success, isDark),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // My Payslip
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.pastelGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Latest Payslip', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Feb 2026', style: TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net Pay', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('₹65,400', style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.success)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Gross', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('₹92,000', style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 0.704),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFD0D4DC),
                      valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Deductions: ₹26,600', style: theme.textTheme.bodySmall),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // My Attendance This Week
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.pastelBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('This Week', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),
                ..._buildWeekdayRows(theme, isDark),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 480.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),
          const SizedBox(height: 16),

          // Quick Actions
          Text('Quick Actions', style: theme.textTheme.titleMedium)
              .animate().fadeIn(duration: 400.ms, delay: 560.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 560.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMyQuickAction(Icons.event_busy, 'Apply Leave', AppColors.primary, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildMyQuickAction(Icons.receipt, 'Submit Claim', AppColors.success, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildMyQuickAction(Icons.confirmation_num, 'Raise Ticket', AppColors.orange, isDark)),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 640.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 640.ms, curve: Curves.easeOut),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPunchCard(AppProvider provider, ThemeData theme, bool isDark) {
    final isPunchedIn = provider.isPunchedIn;

    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPunchedIn ? AppColors.pastelGreen : AppColors.pastelRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPunchedIn ? Icons.timer : Icons.timer_off,
                  color: isPunchedIn ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Attendance', style: theme.textTheme.titleMedium),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPunchedIn
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPunchedIn ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isPunchedIn ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isPunchedIn && provider.punchInTime != null) ...[
            Text(
              DateFormat('hh:mm a').format(provider.punchInTime!),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('Punched in at', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (!isPunchedIn) {
                  showDialog(
                    context: context,
                    builder: (_) => const FaceVerificationDialog(),
                  );
                } else {
                  provider.togglePunch();
                }
              },
              icon: Icon(isPunchedIn ? Icons.logout : Icons.login),
              label: Text(
                isPunchedIn ? 'Punch Out' : 'Punch In',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPunchedIn ? AppColors.danger : AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveChip(String label, int used, int total, Color color, bool isDark) {
    final remaining = total - used;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$remaining', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: used / total),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('$used/$total used', style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekdayRows(ThemeData theme, bool isDark) {
    final weekData = [
      {'day': 'Monday', 'in': '09:00 AM', 'out': '06:15 PM', 'hours': '9h 15m', 'status': 'Present'},
      {'day': 'Tuesday', 'in': '08:55 AM', 'out': '06:30 PM', 'hours': '9h 35m', 'status': 'Present'},
      {'day': 'Wednesday', 'in': '09:02 AM', 'out': '06:00 PM', 'hours': '8h 58m', 'status': 'Present'},
      {'day': 'Thursday', 'in': '--:--', 'out': '--:--', 'hours': '--', 'status': 'Today'},
      {'day': 'Friday', 'in': '--:--', 'out': '--:--', 'hours': '--', 'status': 'Upcoming'},
    ];

    return weekData.map((d) {
      final isToday = d['status'] == 'Today';
      final isUpcoming = d['status'] == 'Upcoming';
      final statusColor = isToday ? AppColors.primary : isUpcoming ? AppColors.lightSubtext : AppColors.success;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                d['day']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(d['in']!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                  Text(d['out']!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                  Text(d['hours']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildMyQuickAction(IconData icon, String label, Color color, bool isDark) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label action opened'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: NeuCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildTabContent(ThemeData theme, bool isDark) {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab(theme, isDark);
      case 1:
        return _buildTeamTab(theme, isDark);
      case 2:
        return _buildAttendanceTab(theme, isDark);
      case 3:
        return _buildLeaveTab(theme, isDark);
      default:
        return _buildHomeTab(theme, isDark);
    }
  }

  // ===========================================================================
  // TAB 0 - HOME
  // ===========================================================================
  Widget _buildHomeTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 2x2 Stat Cards Grid
          _buildStatCardsGrid(theme)
              .animate()
              .fadeIn(duration: 400.ms, delay: (1 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (1 * 80).ms,
                  curve: Curves.easeOut),
          const SizedBox(height: 24),
          // Quick Actions
          _buildQuickActions(theme, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: (2 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (2 * 80).ms,
                  curve: Curves.easeOut),
          const SizedBox(height: 24),
          // Announcements Section
          _buildAnnouncementsSection(theme, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: (3 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (3 * 80).ms,
                  curve: Curves.easeOut),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1 - TEAM
  // ===========================================================================
  Widget _buildTeamTab(ThemeData theme, bool isDark) {
    final teamMembers = [
      _TeamMember('Arjun Patel', 'AP', 'Sr. Engineer', 'Present', AppColors.success),
      _TeamMember('Priya Sharma', 'PS', 'UI Designer', 'WFH', AppColors.primary),
      _TeamMember('Rahul Verma', 'RV', 'Backend Dev', 'Present', AppColors.success),
      _TeamMember('Sneha Gupta', 'SG', 'QA Lead', 'Leave', AppColors.warning),
      _TeamMember('Amit Kumar', 'AK', 'DevOps Engineer', 'Absent', AppColors.danger),
      _TeamMember('Neha Singh', 'NS', 'Product Manager', 'Present', AppColors.success),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Section Header
          Row(
            children: [
              Text(
                'My Direct Reports',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${teamMembers.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (1 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (1 * 80).ms,
                  curve: Curves.easeOut),
          const SizedBox(height: 16),
          // Team members list
          ...teamMembers.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeuCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        m.initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.designation,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: m.statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m.status,
                        style: TextStyle(
                          color: m.statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                      size: 22,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(
                      duration: 400.ms, delay: ((2 + i) * 80).ms)
                  .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      delay: ((2 + i) * 80).ms,
                      curve: Curves.easeOut),
            );
          }),
          const SizedBox(height: 12),
          // Team Attendance Rate
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Attendance Rate',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 0.92),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFD0D4DC),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.success),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                        Text(
                          '92%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 0.92),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFD0D4DC),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '92% of your team is present this week',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (8 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (8 * 80).ms,
                  curve: Curves.easeOut),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 - ATTENDANCE
  // ===========================================================================
  Widget _buildAttendanceTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Today's Summary Row
          Row(
            children: [
              _buildAttendanceMini('Present', '1,180', AppColors.success, isDark),
              const SizedBox(width: 10),
              _buildAttendanceMini('Absent', '18', AppColors.danger, isDark),
              const SizedBox(width: 10),
              _buildAttendanceMini('Late', '32', AppColors.warning, isDark),
              const SizedBox(width: 10),
              _buildAttendanceMini('WFH', '10', AppColors.primary, isDark),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (1 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (1 * 80).ms,
                  curve: Curves.easeOut),
          const SizedBox(height: 24),
          // Department Wise
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department Wise',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDeptRow('Engineering', 0.95, AppColors.primary, isDark),
                const SizedBox(height: 16),
                _buildDeptRow('Design', 0.88, AppColors.secondary, isDark),
                const SizedBox(height: 16),
                _buildDeptRow('Marketing', 0.92, AppColors.success, isDark),
                const SizedBox(height: 16),
                _buildDeptRow('HR', 1.0, AppColors.orange, isDark),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (2 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (2 * 80).ms,
                  curve: Curves.easeOut),
          const SizedBox(height: 20),
          // Recent Anomalies
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Recent Anomalies',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAnomalyItem(
                  'Ravi Menon',
                  'Late 4 times this week',
                  Icons.schedule,
                  AppColors.warning,
                  isDark,
                ),
                const Divider(height: 24),
                _buildAnomalyItem(
                  'Kavita Das',
                  'Absent without notice (2 days)',
                  Icons.person_off_outlined,
                  AppColors.danger,
                  isDark,
                ),
                const Divider(height: 24),
                _buildAnomalyItem(
                  'Sunil Reddy',
                  'Consecutive late check-ins since Mon',
                  Icons.trending_down_rounded,
                  AppColors.orange,
                  isDark,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (3 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (3 * 80).ms,
                  curve: Curves.easeOut),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3 - LEAVE
  // ===========================================================================
  Widget _buildLeaveTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Leave Overview
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildLeaveStatPill(
                          'Pending', '8', AppColors.warning, isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLeaveStatPill(
                          'Approved Today', '3', AppColors.success, isDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLeaveStatPill(
                          'Rejected', '1', AppColors.danger, isDark),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (1 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (1 * 80).ms,
                  curve: Curves.easeOut),
          const SizedBox(height: 20),
          // Upcoming Leaves This Week
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Leaves This Week',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 16),
                _buildUpcomingLeaveItem(
                    'Priya Sharma', 'Mar 12 - Mar 13', 'Casual Leave',
                    AppColors.primary, isDark),
                const Divider(height: 24),
                _buildUpcomingLeaveItem(
                    'Amit Kumar', 'Mar 13', 'Sick Leave',
                    AppColors.danger, isDark),
                const Divider(height: 24),
                _buildUpcomingLeaveItem(
                    'Sneha Gupta', 'Mar 14 - Mar 15', 'Personal Leave',
                    AppColors.secondary, isDark),
                const Divider(height: 24),
                _buildUpcomingLeaveItem(
                    'Rahul Verma', 'Mar 15', 'WFH',
                    AppColors.success, isDark),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (2 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (2 * 80).ms,
                  curve: Curves.easeOut),
          const SizedBox(height: 20),
          // Team Leave Balance
          NeuCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Team Leave Balance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Low Balance',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLeaveBalanceItem(
                    'Amit Kumar', 'AK', 2, 20, AppColors.danger, isDark),
                const Divider(height: 24),
                _buildLeaveBalanceItem(
                    'Kavita Das', 'KD', 3, 20, AppColors.warning, isDark),
                const Divider(height: 24),
                _buildLeaveBalanceItem(
                    'Ravi Menon', 'RM', 4, 20, AppColors.warning, isDark),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (3 * 80).ms)
              .slideY(
                  begin: 0.08,
                  end: 0,
                  duration: 400.ms,
                  delay: (3 * 80).ms,
                  curve: Curves.easeOut),
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED / HOME HELPERS
  // ===========================================================================

  Widget _buildTabBar(bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE4E8EE),
                borderRadius: BorderRadius.circular(25),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFD0D4DC),
                        width: 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ]
                    : isDark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(0xFFBEC3CE)
                                  .withValues(alpha: 0.4),
                              offset: const Offset(3, 3),
                              blurRadius: 6,
                            ),
                            const BoxShadow(
                              color: Color(0xFFFDFFFF),
                              offset: Offset(-3, -3),
                              blurRadius: 6,
                            ),
                          ],
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCardsGrid(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.groups_rounded,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.pastelBlue,
                value: '1,240',
                label: 'Total Employees',
                trend: '+0.5%',
                trendColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.success,
                iconBgColor: AppColors.pastelGreen,
                value: '1,180',
                label: 'Present Today',
                trend: '95.2%',
                trendColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.event_busy_rounded,
                iconColor: AppColors.warning,
                iconBgColor: AppColors.pastelYellow,
                value: '42',
                label: 'On Leave',
                trend: '-8%',
                trendColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.pending_actions_rounded,
                iconColor: AppColors.danger,
                iconBgColor: AppColors.pastelRed,
                value: '15',
                label: 'Pending Approvals',
                trend: 'Urgent',
                trendColor: AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
                Icons.check_circle_outline, 'Approve', AppColors.success, isDark),
            _buildQuickActionItem(
                Icons.calendar_month, 'Calendar', AppColors.primary, isDark),
            _buildQuickActionItem(
                Icons.bar_chart_rounded, 'Reports', AppColors.secondary, isDark),
            _buildQuickActionItem(
                Icons.campaign_outlined, 'Announce', AppColors.orange, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
      IconData icon, String label, Color color, bool isDark) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label action opened'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE4E8EE),
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFBEC3CE).withValues(alpha: 0.5),
                        offset: const Offset(4, 4),
                        blurRadius: 8,
                      ),
                      const BoxShadow(
                        color: Color(0xFFFDFFFF),
                        offset: Offset(-4, -4),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(ThemeData theme, bool isDark) {
    return NeuCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Announcements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Empty state
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 56,
                  color: isDark
                      ? AppColors.darkSubtext.withValues(alpha: 0.4)
                      : AppColors.lightSubtext.withValues(alpha: 0.35),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Records Found',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check back later for company updates',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkSubtext.withValues(alpha: 0.7)
                        : AppColors.lightSubtext,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ===========================================================================
  // ATTENDANCE TAB HELPERS
  // ===========================================================================

  Widget _buildAttendanceMini(
      String label, String value, Color color, bool isDark) {
    return Expanded(
      child: NeuCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptRow(
      String dept, double pct, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dept,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            Text(
              '${(pct * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFD0D4DC),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnomalyItem(
      String name, String desc, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LEAVE TAB HELPERS
  // ===========================================================================

  Widget _buildLeaveStatPill(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingLeaveItem(
      String name, String dates, String type, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dates,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            type,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveBalanceItem(String name, String initials, int remaining,
      int total, Color color, bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: remaining / total),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFD0D4DC),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '$remaining/$total',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data class for team members
// ---------------------------------------------------------------------------
class _TeamMember {
  final String name;
  final String initials;
  final String designation;
  final String status;
  final Color statusColor;

  _TeamMember(
      this.name, this.initials, this.designation, this.status, this.statusColor);
}

// ---------------------------------------------------------------------------
// Stat Card - Neomorphic
// ---------------------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String value;
  final String label;
  final String trend;
  final Color trendColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.value,
    required this.label,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                trend,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkText
                  : AppColors.lightText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSubtext
                  : AppColors.lightSubtext,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
