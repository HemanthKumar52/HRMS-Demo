import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:live_activities/live_activities.dart';

/// Manages Live Activities (iOS) and ongoing notifications (Android)
/// for the attendance punch-in timer.
class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();

  final LiveActivities _liveActivities = LiveActivities();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  String? _activityId;
  Timer? _updateTimer;
  DateTime? _punchInTime;
  bool _isActive = false;
  bool _initialized = false;

  static const int _androidNotifId = 9999;
  static const String _androidChannelId = 'attendance_live';
  static const String _androidChannelName = 'Attendance Tracker';
  static const String _appGroupId = 'group.com.ppulse.hrmsDemo';
  static const String _iosActivityId = 'AttendanceActivity';

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (!kIsWeb && Platform.isIOS) {
        await _liveActivities.init(appGroupId: _appGroupId);
      }

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _androidChannelId,
            _androidChannelName,
            description: 'Shows ongoing attendance tracking',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );
      }

      _initialized = true;
      debugPrint('LIVE_ACTIVITY: Initialized');
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Init error - $e');
    }
  }

  /// Start live activity when user punches in
  Future<void> startPunchIn({required String userName, required DateTime punchTime}) async {
    _punchInTime = punchTime;
    _isActive = true;

    if (kIsWeb) return;
    if (!_initialized) await init();

    try {
      if (Platform.isIOS) {
        await _startIOSLiveActivity(userName, punchTime);
      } else if (Platform.isAndroid) {
        await _startAndroidOngoingNotification(userName, punchTime);
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Start error - $e');
    }

    // Update every minute
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateActivity());
  }

  /// Stop live activity when user punches out
  Future<void> stopPunchOut({Duration? totalWorked}) async {
    _isActive = false;
    _updateTimer?.cancel();
    _updateTimer = null;

    if (kIsWeb) return;

    try {
      if (Platform.isIOS) {
        await _stopIOSLiveActivity();
      } else if (Platform.isAndroid) {
        await _stopAndroidOngoingNotification(totalWorked);
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Stop error - $e');
    }

    _punchInTime = null;
  }

  void _updateActivity() {
    if (!_isActive || _punchInTime == null) return;

    final worked = DateTime.now().difference(_punchInTime!);
    final progress = (worked.inMinutes / 540).clamp(0.0, 1.0); // 9h target

    try {
      if (Platform.isIOS) {
        _updateIOSLiveActivity(worked, progress);
      } else if (Platform.isAndroid) {
        _updateAndroidNotification(worked, progress);
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Update error - $e');
    }
  }

  // ═══════════════════════════════════════════
  // iOS LIVE ACTIVITY
  // ═══════════════════════════════════════════

  Future<void> _startIOSLiveActivity(String userName, DateTime punchTime) async {
    _activityId = await _liveActivities.createActivity(
      _iosActivityId,
      {
        'userName': userName,
        'punchInTime': punchTime.millisecondsSinceEpoch ~/ 1000,
        'workedHours': 0,
        'workedMinutes': 0,
        'progress': 0.0,
        'targetHours': 9,
        'status': 'working',
      },
      removeWhenAppIsKilled: true,
    );
    debugPrint('LIVE_ACTIVITY: iOS started id=$_activityId');
  }

  Future<void> _updateIOSLiveActivity(Duration worked, double progress) async {
    if (_activityId == null) return;
    await _liveActivities.updateActivity(
      _activityId!,
      {
        'workedHours': worked.inHours,
        'workedMinutes': worked.inMinutes.remainder(60),
        'progress': progress,
        'status': 'working',
      },
    );
  }

  Future<void> _stopIOSLiveActivity() async {
    if (_activityId == null) return;
    await _liveActivities.endActivity(_activityId!);
    _activityId = null;
    debugPrint('LIVE_ACTIVITY: iOS ended');
  }

  // ═══════════════════════════════════════════
  // ANDROID ONGOING NOTIFICATION
  // ═══════════════════════════════════════════

  Future<void> _startAndroidOngoingNotification(String userName, DateTime punchTime) async {
    final details = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Shows ongoing attendance tracking',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: punchTime.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: false,
      category: AndroidNotificationCategory.progress,
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: false,
      showProgress: true,
      maxProgress: 100,
      progress: 0,
      subText: 'Working',
    );

    await _notifications.show(
      id: _androidNotifId,
      title: 'Punched In - $userName',
      body: 'Working since ${_formatTime(punchTime)}',
      notificationDetails: NotificationDetails(android: details),
    );
    debugPrint('ANDROID_LIVE: Started');
  }

  Future<void> _updateAndroidNotification(Duration worked, double progress) async {
    final h = worked.inHours;
    final m = worked.inMinutes.remainder(60);
    final progressPercent = (progress * 100).toInt();

    final details = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Shows ongoing attendance tracking',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: _punchInTime!.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: false,
      category: AndroidNotificationCategory.progress,
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: false,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      subText: '${h}h ${m.toString().padLeft(2, '0')}m / 9h',
    );

    await _notifications.show(
      id: _androidNotifId,
      title: 'Working',
      body: '${h}h ${m.toString().padLeft(2, '0')}m  |  $progressPercent% of 9h target',
      notificationDetails: NotificationDetails(android: details),
    );
  }

  Future<void> _stopAndroidOngoingNotification(Duration? totalWorked) async {
    if (totalWorked != null) {
      final h = totalWorked.inHours;
      final m = totalWorked.inMinutes.remainder(60);

      const details = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: 'Shows ongoing attendance tracking',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
        playSound: false,
        enableVibration: false,
      );

      await _notifications.show(
        id: _androidNotifId,
        title: 'Punched Out',
        body: 'Total worked: ${h}h ${m.toString().padLeft(2, '0')}m',
        notificationDetails: const NotificationDetails(android: details),
      );
    } else {
      await _notifications.cancel(id: _androidNotifId);
    }
    debugPrint('ANDROID_LIVE: Stopped');
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}
