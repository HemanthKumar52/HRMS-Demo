import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PPulseFooter extends StatelessWidget {
  const PPulseFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Center(
        child: Text(
          '\u00A9 2026 PPulse',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkSubtext.withValues(alpha: 0.4)
                : AppColors.lightSubtext.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
