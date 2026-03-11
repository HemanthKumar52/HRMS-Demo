import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import 'face_verification_dialog.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
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

              // Attendance Timer Card
              _AttendanceTimerCard(provider: provider).animate().fadeIn(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 160.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),

              // Statistics Row - Leave Balance & Work Stats
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
                            child: const Icon(Icons.event_available,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(height: 12),
                          Text('Leave Balance',
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text('12',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                          Text('Days remaining',
                              style: theme.textTheme.bodySmall),
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
                            child: const Icon(Icons.trending_up,
                                color: AppColors.success, size: 20),
                          ),
                          const SizedBox(height: 12),
                          Text('Attendance',
                              style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text('96%',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success)),
                          Text('This month',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 240.ms, curve: Curves.easeOut),
              const SizedBox(height: 14),

              // Leave Breakdown
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
                          child: const Icon(Icons.calendar_month,
                              color: AppColors.secondary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Leave Summary',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _LeaveTypeChip(
                          label: 'Casual',
                          used: 3,
                          total: 8,
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _LeaveTypeChip(
                          label: 'Sick',
                          used: 1,
                          total: 6,
                          color: AppColors.orange,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 10),
                        _LeaveTypeChip(
                          label: 'Earned',
                          used: 2,
                          total: 10,
                          color: AppColors.success,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 320.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),

              // Announcement Card
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.pastelOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.campaign_rounded,
                              color: AppColors.orange, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Announcements',
                            style: theme.textTheme.titleMedium),
                        const Spacer(),
                        const StatusDot(color: AppColors.danger),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AnnouncementItem(
                      title: 'Company Town Hall',
                      subtitle: 'March 15, 2026 at 3:00 PM',
                      icon: Icons.event,
                    ),
                    const Divider(height: 16),
                    _AnnouncementItem(
                      title: 'New Leave Policy Update',
                      subtitle: 'Effective from April 1, 2026',
                      icon: Icons.policy,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),

              // Org Structure Card - Redesigned
              NeuCard(
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
                          child: const Icon(Icons.account_tree_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Reporting Chain',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Vertical timeline-style org chart
                    _OrgChainItem(
                      name: 'Sarah Chen',
                      role: 'CTO',
                      color: AppColors.danger,
                      isFirst: true,
                    ),
                    _OrgChainConnector(),
                    _OrgChainItem(
                      name: 'James Wilson',
                      role: 'Engineering Manager',
                      color: AppColors.secondary,
                    ),
                    _OrgChainConnector(),
                    _OrgChainItem(
                      name: 'Priya Sharma',
                      role: 'Team Lead',
                      color: AppColors.primary,
                    ),
                    _OrgChainConnector(),
                    _OrgChainItem(
                      name: provider.userName,
                      role: provider.designation,
                      color: AppColors.success,
                      isYou: true,
                      isLast: true,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 480.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 480.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),

              // Quick Actions
              Text('Quick Actions', style: theme.textTheme.titleMedium).animate().fadeIn(duration: 400.ms, delay: 560.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 560.ms, curve: Curves.easeOut),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _QuickAction(
                      icon: Icons.event_busy,
                      label: 'Leave',
                      color: AppColors.primary),
                  _QuickAction(
                      icon: Icons.receipt,
                      label: 'Claims',
                      color: AppColors.success),
                  _QuickAction(
                      icon: Icons.confirmation_num,
                      label: 'Tickets',
                      color: AppColors.orange),
                  _QuickAction(
                      icon: Icons.swap_horiz,
                      label: 'Shift',
                      color: AppColors.secondary),
                  _QuickAction(
                      icon: Icons.work,
                      label: 'Work Type',
                      color: AppColors.pink),
                  _QuickAction(
                      icon: Icons.access_time,
                      label: 'Attendance',
                      color: AppColors.primaryDark),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 640.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 640.ms, curve: Curves.easeOut),
              const SizedBox(height: 20),

              // Recent Activity
              Text('Recent Activity', style: theme.textTheme.titleMedium).animate().fadeIn(duration: 400.ms, delay: 720.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 720.ms, curve: Curves.easeOut),
              const SizedBox(height: 12),
              NeuCard(
                child: Column(
                  children: [
                    _ActivityItem(
                      icon: Icons.check_circle,
                      color: AppColors.success,
                      title: 'Leave Approved',
                      subtitle: 'Casual leave on Mar 5 was approved',
                      time: '2 hours ago',
                    ),
                    Divider(
                      height: 20,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    _ActivityItem(
                      icon: Icons.login_rounded,
                      color: AppColors.primary,
                      title: 'Punch In',
                      subtitle: 'Punched in at 09:02 AM today',
                      time: '5 hours ago',
                    ),
                    Divider(
                      height: 20,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    _ActivityItem(
                      icon: Icons.receipt_long,
                      color: AppColors.orange,
                      title: 'Expense Submitted',
                      subtitle: 'Travel reimbursement - ₹34,500',
                      time: 'Yesterday',
                    ),
                    Divider(
                      height: 20,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    _ActivityItem(
                      icon: Icons.swap_horiz,
                      color: AppColors.secondary,
                      title: 'Shift Changed',
                      subtitle: 'Shift updated to Morning (9AM-6PM)',
                      time: '2 days ago',
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 800.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 800.ms, curve: Curves.easeOut),
              const SizedBox(height: 20),
            ],
          ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}


class _LeaveTypeChip extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final Color color;
  final bool isDark;

  const _LeaveTypeChip({
    required this.label,
    required this.used,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              '$remaining',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            // Progress bar
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
            Text(
              '$used/$total used',
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTimerCard extends StatelessWidget {
  final AppProvider provider;
  const _AttendanceTimerCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Text('Attendance', style: theme.textTheme.titleMedium),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPunchedIn ? AppColors.danger : AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AnnouncementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      ],
    );
  }
}

// Redesigned org chart - vertical chain style
class _OrgChainItem extends StatelessWidget {
  final String name;
  final String role;
  final Color color;
  final bool isYou;
  final bool isFirst;
  final bool isLast;

  const _OrgChainItem({
    required this.name,
    required this.role,
    required this.color,
    this.isYou = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isYou
            ? color.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
        border: isYou
            ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              name[0],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (isYou) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('You',
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(role,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgChainConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(time,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final Color color;
  const StatusDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
