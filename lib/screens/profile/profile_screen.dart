import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neu_card.dart';
import '../../providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          children: [
            // Profile avatar with edit button
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      provider.userName
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join(),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Image picker coming soon'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name and designation
            Text(
              provider.userName,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              provider.designation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                provider.employeeId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Personal Info section
            _SectionHeader(title: 'Personal Information'),
            const SizedBox(height: 12),
            NeuCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    value: provider.userName,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'venkat.kumar@ppulse.io',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: '+91 98765 43210',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Date of Birth',
                    value: '15 Aug 1995',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.wc_outlined,
                    label: 'Gender',
                    value: 'Male',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Work Info section
            _SectionHeader(title: 'Work Information'),
            const SizedBox(height: 12),
            NeuCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Employee ID',
                    value: provider.employeeId,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'Department',
                    value: provider.department,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.work_outline_rounded,
                    label: 'Designation',
                    value: provider.designation,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date of Joining',
                    value: '01 Mar 2024',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.supervisor_account_outlined,
                    label: 'Reporting Manager',
                    value: 'Priya Sharma',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
