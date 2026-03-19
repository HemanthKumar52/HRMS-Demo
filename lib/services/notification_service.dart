import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notifId = 0;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Request notification permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
    bool vibrate = true,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'hrms_channel',
      'HRMS Notifications',
      channelDescription: 'Notifications for clock in/out, requests & salary',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: _notifId++,
      title: title,
      body: body,
      notificationDetails: details,
    );

    if (vibrate) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) {
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
      );

  Future<void> showPunchOut() => show(
        title: 'Punched Out',
        body: 'You have successfully punched out. See you tomorrow!',
      );

  Future<void> showRequestApplied(String type) => show(
        title: '$type Submitted',
        body: 'Your $type request has been submitted successfully.',
      );

  Future<void> showRequestAssigned(String type) => show(
        title: 'New $type Assigned',
        body: 'A new $type request has been assigned to you for approval.',
      );

  Future<void> showSalaryCredit({required String month}) => show(
        title: 'Salary Credited',
        body: 'Your salary for $month has been credited to your account.',
      );
}
