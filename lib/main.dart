import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/requests/request_detail_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_lock_service.dart';
import 'services/live_activity_service.dart';
import 'services/notification_service.dart';
import 'utils/platform_adaptive.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
  } catch (_) {}
  try {
    await LiveActivityService.instance.init();
  } catch (_) {}
  NotificationService.instance.navigatorKey = navigatorKey;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PPulseApp());
}

class PPulseApp extends StatefulWidget {
  const PPulseApp({super.key});

  @override
  State<PPulseApp> createState() => _PPulseAppState();
}

class _PPulseAppState extends State<PPulseApp> with WidgetsBindingObserver {
  final _appProvider = AppProvider();
  DateTime? _pausedAt;
  static const _inactivityTimeout = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.onNotificationTap = () {
      _appProvider.navigateToRequested();
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkInactivityTimeout();
      _checkAppLock();
    }
  }

  void _checkInactivityTimeout() {
    if (_pausedAt == null || !_appProvider.isLoggedIn) return;
    final elapsed = DateTime.now().difference(_pausedAt!);
    if (elapsed > _inactivityTimeout) {
      // Session expired due to inactivity — require re-auth
      _appProvider.logout();
    }
    _pausedAt = null;
  }

  Future<void> _checkAppLock() async {
    final lockService = AppLockService.instance;
    if (!await lockService.isEnabled()) return;
    if (!_appProvider.isLoggedIn) return;

    final authenticated = await lockService.authenticate();
    if (!authenticated) {
      // If user fails authentication, show lock again or exit
      // For now, just re-prompt on next resume
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _appProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          if (isApplePlatform) {
            return _buildCupertinoApp(themeProvider);
          }
          return _buildMaterialApp(themeProvider);
        },
      ),
    );
  }

  Widget _buildCupertinoApp(ThemeProvider themeProvider) {
    return CupertinoApp(
      navigatorKey: navigatorKey,
      title: 'PPULSE',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.cupertinoTheme,
      // Material widgets (RefreshIndicator, Scaffold, TextField, etc.)
      // require MaterialLocalizations even inside CupertinoApp.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: const SplashScreen(),
      routes: {
        '/request-detail': (context) => const RequestDetailScreen(),
      },
    );
  }

  Widget _buildMaterialApp(ThemeProvider themeProvider) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PPULSE',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      home: const SplashScreen(),
      routes: {
        '/request-detail': (context) => const RequestDetailScreen(),
      },
      builder: (context, child) {
        return SafeArea(
          top: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
