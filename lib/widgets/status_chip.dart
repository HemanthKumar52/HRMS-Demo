import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  factory StatusChip.approved() => const StatusChip(
        label: 'Approved',
        color: AppColors.success,
        icon: Icons.check_circle,
      );

  factory StatusChip.pending() => const StatusChip(
        label: 'Pending',
        color: AppColors.warning,
        icon: Icons.schedule,
      );

  factory StatusChip.rejected() => const StatusChip(
        label: 'Rejected',
        color: AppColors.danger,
        icon: Icons.cancel,
      );

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: c, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
