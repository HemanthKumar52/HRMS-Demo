import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/requests/request_detail_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
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
            title: 'PPulse HRMS',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            home: const SplashScreen(),
            routes: {
              '/request-detail': (context) => const RequestDetailScreen(),
            },
          );
        },
      ),
    );
  }
}
