import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/cupertino_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.dark;

  AppThemeMode get themeMode => _themeMode;

  ThemeData get theme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.light();
      case AppThemeMode.dark:
        return AppTheme.dark();
    }
  }

  CupertinoThemeData get cupertinoTheme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return PPulseCupertinoTheme.light();
      case AppThemeMode.dark:
        return PPulseCupertinoTheme.dark();
    }
  }

  void setTheme(AppThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
