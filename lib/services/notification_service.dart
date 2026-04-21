import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notifId = 0;

  GlobalKey<NavigatorState>? navigatorKey;
  VoidCallback? onNotificationTap;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS: request permissions AND enable foreground presentation
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [],
    );

    final macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 13+: request notification permission
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      // Create notification channel explicitly
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'hrms_channel',
          'HRMS Notifications',
          description: 'Notifications for requests, approvals & alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }

    // iOS: request permission explicitly
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: false,
      );
    }

    _initialized = true;
    debugPrint('NOTIF_SERVICE: Initialized successfully');
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('NOTIF_TAP: payload=${response.payload}');
    onNotificationTap?.call();
  }

  /// Check if the user has disabled push notifications in app settings.
  Future<bool> _isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
    bool vibrate = true,
  }) async {
    // Respect the user's in-app notification preference
    if (!await _isNotificationEnabled()) {
      debugPrint('PUSH_NOTIF: Suppressed (user disabled) "$title"');
      return;
    }
    debugPrint('PUSH_NOTIF: Firing "$title" - "$body"');
    if (!_initialized) await init();

    // Android: max importance, heads-up, full screen intent for guaranteed visibility
    const androidDetails = AndroidNotificationDetails(
      'hrms_channel',
      'HRMS Notifications',
      channelDescription: 'Notifications for requests, approvals & alerts',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      showWhen: true,
      enableLights: true,
      ledColor: Color(0xFF6B3FA0),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'PPULSE',
      styleInformation: BigTextStyleInformation(
        '',
        contentTitle: null,
        summaryText: 'PPULSE',
      ),
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
    );

    // iOS: show alert, badge, sound even when app is in foreground
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const macDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macDetails,
    );

    try {
      await _plugin.show(
        id: _notifId++,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload ?? 'requested',
      );
      debugPrint('PUSH_NOTIF: Shown successfully (id=${_notifId - 1})');
    } catch (e) {
      debugPrint('PUSH_NOTIF ERROR: $e');
    }

    if (vibrate) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate(duration: 300);
        }
      } catch (e) {
        debugPrint('Vibration error: $e');
      }
    }
  }

  // ── Convenience methods ────────────────────────────────────────────────

  Future<void> showPunchIn() => show(
    title: 'Punched In',
    body: 'You have successfully punched in. Have a productive day!',
    payload: 'punch_in',
  );

  Future<void> showPunchOut() => show(
    title: 'Punched Out',
    body: 'You have successfully punched out. See you tomorrow!',
    payload: 'punch_out',
  );

  Future<void> showRequestApplied(String type) => show(
    title: '$type Submitted',
    body: 'Your $type request has been submitted successfully.',
    payload: 'request_submitted',
  );

  Future<void> showRequestAssigned(String type) => show(
    title: 'New $type Assigned',
    body: 'A new $type request has been assigned to you for approval.',
    payload: 'request_assigned',
  );

  Future<void> showSalaryCredit({required String month}) => show(
    title: 'Salary Credited',
    body: 'Your salary for $month has been credited to your account.',
    payload: 'salary',
  );
}
