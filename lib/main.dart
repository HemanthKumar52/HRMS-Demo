import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/requests/request_detail_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/live_activity_service.dart';
import 'services/notification_service.dart';
import 'utils/platform_adaptive.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await LiveActivityService.instance.init();
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

class _PPulseAppState extends State<PPulseApp> {
  final _appProvider = AppProvider();

  @override
  void initState() {
    super.initState();
    NotificationService.instance.onNotificationTap = () {
      _appProvider.navigateToRequested();
    };
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
