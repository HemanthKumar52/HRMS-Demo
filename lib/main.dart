import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/requests/request_detail_screen.dart';
import 'services/live_activity_service.dart';
import 'services/notification_service.dart';

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
    // When any notification is tapped, navigate to Requested tab
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
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'PPULSE',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            // ── Localization (ready to activate) ──────────────────
            // Uncomment these 3 lines + import to enable multi-language:
            // localizationsDelegates: AppLocalizations.localizationsDelegates,
            // supportedLocales: AppLocalizations.supportedLocales,
            // locale: const Locale('en'), // or read from SharedPreferences
            home: const SplashScreen(),
            routes: {
              '/request-detail': (context) => const RequestDetailScreen(),
            },
            builder: (context, child) {
              // Global SafeArea ensures content never overlaps
              // notch, Dynamic Island, or home indicator on ANY device.
              return SafeArea(
                // Keep status bar area for AppBar screens — only
                // guard the bottom (home indicator / gesture bar).
                top: false,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
