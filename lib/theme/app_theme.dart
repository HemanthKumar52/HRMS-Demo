import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode { light, dark }

class AppColors {
  // Light theme - neomorphic
  static const lightBg = Color(0xFFE4E8EE);
  static const lightCard = Color(0xFFE4E8EE);
  static const lightText = Color(0xFF1A1D2E);
  static const lightSubtext = Color(0xFF6B7280);

  // Dark theme
  static const darkBg = Color(0xFF0D0F1A);
  static const darkCard = Color(0xFF1A1D2E);
  static const darkText = Color(0xFFF0F0F5);
  static const darkSubtext = Color(0xFF9CA3AF);

  // Accent colors
  static const primary = Color(0xFF4F8EF7);
  static const primaryDark = Color(0xFF3B6FD4);
  static const secondary = Color(0xFF7C5CFC);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFEF4444);
  static const orange = Color(0xFFFF8C42);
  static const pink = Color(0xFFEC4899);

  // Pastel accents
  static const pastelGreen = Color(0xFFD1FAE5);
  static const pastelPurple = Color(0xFFE9D5FF);
  static const pastelOrange = Color(0xFFFFEDD5);
  static const pastelBlue = Color(0xFFDBEAFE);
  static const pastelRed = Color(0xFFFEE2E2);
  static const pastelYellow = Color(0xFFFEF3C7);

  // Keep neon colors as accent references (used in some widgets)
  static const neonBlue = Color(0xFF00D4FF);
  static const neonPurple = Color(0xFFBB86FC);
  static const neonGreen = Color(0xFF00FF88);
  static const neonPink = Color(0xFFFF0080);
}

class NeuDecoration {
  static BoxDecoration card(BuildContext context, {double radius = 20}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? theme.cardColor : const Color(0xFFE4E8EE),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(4, 4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                offset: const Offset(-4, -4),
                blurRadius: 8,
              ),
            ]
          : [
              BoxShadow(
                color: const Color(0xFFBEC3CE).withValues(alpha: 0.6),
                offset: const Offset(6, 6),
                blurRadius: 15,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Color(0xFFFDFFFF),
                offset: Offset(-6, -6),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
    );
  }

  static BoxDecoration pressed(BuildContext context, {double radius = 20}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? theme.cardColor : const Color(0xFFE0E4EA),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.03),
                offset: const Offset(-2, -2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ]
          : [
              BoxShadow(
                color: const Color(0xFFBEC3CE).withValues(alpha: 0.5),
                offset: const Offset(3, 3),
                blurRadius: 6,
              ),
              const BoxShadow(
                color: Color(0xFFFDFFFF),
                offset: Offset(-3, -3),
                blurRadius: 6,
              ),
            ],
    );
  }

  static BoxDecoration glass(BuildContext context, {double radius = 24}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightCard,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightBg,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.lightText),
          headlineMedium: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText),
          titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.lightText),
          titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.lightText),
          bodyLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.lightText),
          bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.lightSubtext),
          bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.lightSubtext),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.lightText),
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkCard,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText),
          headlineMedium: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText),
          titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText),
          titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText),
          bodyLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.darkText),
          bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.darkSubtext),
          bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.darkSubtext),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText),
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
