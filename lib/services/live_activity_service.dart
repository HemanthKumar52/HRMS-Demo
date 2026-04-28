import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:live_activities/live_activities.dart';

/// Manages Live Activities (iOS) and ongoing notifications (Android)
/// for attendance tracking, leave requests, shift reminders, and payroll.
class LiveActivityService {
  LiveActivityService._();
  static final LiveActivityService instance = LiveActivityService._();

  final LiveActivities _liveActivities = LiveActivities();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  String? _attendanceActivityId;
  String? _leaveActivityId;
  Timer? _attendanceTimer;
  DateTime? _punchInTime;
  bool _isAttendanceActive = false;
  bool _initialized = false;

  // Notification IDs (Android)
  static const int _attendanceNotifId = 9999;
  static const int _leaveNotifId = 9998;
  static const int _shiftNotifId = 9997;
  static const int _payrollNotifId = 9996;

  // Channel IDs
  static const String _attendanceChannelId = 'attendance_live';
  static const String _leaveChannelId = 'leave_tracking';
  static const String _shiftChannelId = 'shift_reminder';
  static const String _payrollChannelId = 'payroll_updates';

  static const String _appGroupId = 'group.com.ppulse.hrmsDemo';

  /// Initialize all channels and live activity system
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (!kIsWeb && Platform.isIOS) {
        await _liveActivities.init(appGroupId: _appGroupId);
      }

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _attendanceChannelId,
              'Attendance Tracker',
              description: 'Live attendance tracking',
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
              showBadge: false,
            ),
          );
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _leaveChannelId,
              'Leave Tracking',
              description: 'Leave request status updates',
              importance: Importance.low,
              playSound: false,
              enableVibration: false,
              showBadge: true,
            ),
          );
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _shiftChannelId,
              'Shift Reminders',
              description: 'Upcoming shift notifications',
              importance: Importance.defaultImportance,
              playSound: true,
              enableVibration: true,
            ),
          );
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              _payrollChannelId,
              'Payroll Updates',
              description: 'Salary and payroll notifications',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
        }
      }

      _initialized = true;
      debugPrint('LIVE_ACTIVITY: Initialized');
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Init error - $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // 1. ATTENDANCE TRACKING
  // ═══════════════════════════════════════════════════════

  Future<void> startPunchIn({
    required String userName,
    required DateTime punchTime,
  }) async {
    _punchInTime = punchTime;
    _isAttendanceActive = true;
    if (kIsWeb) return;
    if (!_initialized) await init();

    try {
      if (Platform.isIOS) {
        _attendanceActivityId = await _liveActivities.createActivity(
          'AttendanceActivity',
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
      } else if (Platform.isAndroid) {
        await _notifications.show(
          id: _attendanceNotifId,
          title: 'Checked In - $userName',
          body: 'Working since ${_formatTime(punchTime)}',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _attendanceChannelId,
              'Attendance Tracker',
              importance: Importance.low,
              priority: Priority.low,
              ongoing: true,
              autoCancel: false,
              showWhen: true,
              when: punchTime.millisecondsSinceEpoch,
              usesChronometer: true,
              chronometerCountDown: false,
              category: AndroidNotificationCategory.progress,
              showProgress: true,
              maxProgress: 100,
              progress: 0,
              subText: 'Working',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Attendance start error - $e');
    }

    _attendanceTimer?.cancel();
    _attendanceTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateAttendance(),
    );
  }

  Future<void> stopPunchOut({Duration? totalWorked}) async {
    _isAttendanceActive = false;
    _attendanceTimer?.cancel();
    _attendanceTimer = null;
    if (kIsWeb) return;

    try {
      if (Platform.isIOS && _attendanceActivityId != null) {
        await _liveActivities.endActivity(_attendanceActivityId!);
        _attendanceActivityId = null;
      } else if (Platform.isAndroid) {
        if (totalWorked != null) {
          final h = totalWorked.inHours;
          final m = totalWorked.inMinutes.remainder(60);
          await _notifications.show(
            id: _attendanceNotifId,
            title: 'Checked Out',
            body: 'Total worked: ${h}h ${m.toString().padLeft(2, '0')}m',
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                _attendanceChannelId,
                'Attendance Tracker',
                importance: Importance.defaultImportance,
                ongoing: false,
                autoCancel: true,
                playSound: false,
                enableVibration: false,
              ),
            ),
          );
        } else {
          await _notifications.cancel(id: _attendanceNotifId);
        }
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Attendance stop error - $e');
    }
    _punchInTime = null;
  }

  void _updateAttendance() {
    if (!_isAttendanceActive || _punchInTime == null) return;
    final worked = DateTime.now().difference(_punchInTime!);
    final progress = (worked.inMinutes / 540).clamp(0.0, 1.0);
    final h = worked.inHours;
    final m = worked.inMinutes.remainder(60);

    try {
      if (Platform.isIOS && _attendanceActivityId != null) {
        _liveActivities.updateActivity(_attendanceActivityId!, {
          'workedHours': h,
          'workedMinutes': m,
          'progress': progress,
          'status': 'working',
        });
      } else if (Platform.isAndroid) {
        final pct = (progress * 100).toInt();
        _notifications.show(
          id: _attendanceNotifId,
          title: 'Working',
          body: '${h}h ${m.toString().padLeft(2, '0')}m  |  $pct% of 9h target',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _attendanceChannelId,
              'Attendance Tracker',
              importance: Importance.low,
              priority: Priority.low,
              ongoing: true,
              autoCancel: false,
              showWhen: true,
              when: _punchInTime!.millisecondsSinceEpoch,
              usesChronometer: true,
              showProgress: true,
              maxProgress: 100,
              progress: pct,
              subText: '${h}h ${m.toString().padLeft(2, '0')}m / 9h',
              playSound: false,
              enableVibration: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Attendance update error - $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // 2. LEAVE REQUEST TRACKING
  // ═══════════════════════════════════════════════════════

  /// Show a live activity for a submitted leave request
  Future<void> startLeaveTracking({
    required String leaveType,
    required String dateRange,
    required String status, // submitted, approved, rejected
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final statusLabel = _leaveStatusLabel(status);
    final statusIcon = _leaveStatusIcon(status);

    try {
      if (Platform.isIOS) {
        _leaveActivityId = await _liveActivities.createActivity(
          'LeaveRequestActivity',
          {
            'leaveType': leaveType,
            'dateRange': dateRange,
            'status': status,
            'statusLabel': statusLabel,
          },
          removeWhenAppIsKilled: false,
        );
      } else if (Platform.isAndroid) {
        await _notifications.show(
          id: _leaveNotifId,
          title: '$statusIcon $leaveType Request - $statusLabel',
          body: '$dateRange',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _leaveChannelId,
              'Leave Tracking',
              importance: Importance.low,
              priority: Priority.low,
              ongoing: status == 'submitted',
              autoCancel: status == 'approved' || status == 'rejected',
              category: AndroidNotificationCategory.status,
              subText: statusLabel,
              playSound: false,
              enableVibration: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Leave tracking error - $e');
    }
  }

  /// Update leave request status
  Future<void> updateLeaveStatus({
    required String status,
    String? reviewerName,
  }) async {
    if (kIsWeb) return;
    final statusLabel = _leaveStatusLabel(status);
    final statusIcon = _leaveStatusIcon(status);

    try {
      if (Platform.isIOS && _leaveActivityId != null) {
        if (status == 'approved' || status == 'rejected') {
          await _liveActivities.endActivity(_leaveActivityId!);
          _leaveActivityId = null;
        } else {
          await _liveActivities.updateActivity(_leaveActivityId!, {
            'status': status,
            'statusLabel': statusLabel,
          });
        }
      } else if (Platform.isAndroid) {
        await _notifications.show(
          id: _leaveNotifId,
          title: '$statusIcon Leave Request - $statusLabel',
          body: reviewerName != null
              ? 'Reviewed by $reviewerName'
              : statusLabel,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _leaveChannelId,
              'Leave Tracking',
              importance: status == 'approved' || status == 'rejected'
                  ? Importance.high
                  : Importance.low,
              ongoing: false,
              autoCancel: true,
              playSound: status == 'approved' || status == 'rejected',
              enableVibration: status == 'approved' || status == 'rejected',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Leave update error - $e');
    }
  }

  String _leaveStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String _leaveStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return '📋';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '⏳';
    }
  }

  // ═══════════════════════════════════════════════════════
  // 3. SHIFT REMINDER
  // ═══════════════════════════════════════════════════════

  /// Show an upcoming shift reminder
  Future<void> showShiftReminder({
    required String shiftName,
    required DateTime shiftStart,
    required DateTime shiftEnd,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final startStr = _formatTime(shiftStart);
    final endStr = _formatTime(shiftEnd);
    final minutesUntil = shiftStart.difference(DateTime.now()).inMinutes;
    final timeUntilStr = minutesUntil > 60
        ? '${minutesUntil ~/ 60}h ${minutesUntil % 60}m'
        : '${minutesUntil}m';

    try {
      if (Platform.isIOS) {
        await _liveActivities.createActivity(
          'ShiftReminderActivity',
          {
            'shiftName': shiftName,
            'shiftStart': shiftStart.millisecondsSinceEpoch ~/ 1000,
            'shiftEnd': shiftEnd.millisecondsSinceEpoch ~/ 1000,
            'startTime': startStr,
            'endTime': endStr,
            'minutesUntil': minutesUntil,
          },
          removeWhenAppIsKilled: true,
          staleIn: Duration(minutes: minutesUntil + 30),
        );
      } else if (Platform.isAndroid) {
        await _notifications.show(
          id: _shiftNotifId,
          title: '🕐 Shift Starting in $timeUntilStr',
          body: '$shiftName: $startStr - $endStr',
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _shiftChannelId,
              'Shift Reminders',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              ongoing: true,
              autoCancel: false,
              when: shiftStart.millisecondsSinceEpoch,
              usesChronometer: true,
              chronometerCountDown: true,
              category: AndroidNotificationCategory.reminder,
              subText: shiftName,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Shift reminder error - $e');
    }
  }

  /// Dismiss shift reminder (after shift starts or user dismisses)
  Future<void> dismissShiftReminder() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        await _notifications.cancel(id: _shiftNotifId);
      }
      // iOS: handled by staleIn or auto-dismiss
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Shift dismiss error - $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // 4. PAYROLL NOTIFICATION
  // ═══════════════════════════════════════════════════════

  /// Show payroll credited notification (both platforms)
  Future<void> showPayrollCredited({
    required String month,
    required double netPay,
    required String currency,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    final amountStr = '$currency${netPay.toStringAsFixed(0)}';

    try {
      if (Platform.isIOS) {
        // Short-lived live activity showing salary credited
        final id = await _liveActivities.createActivity(
          'PayrollActivity',
          {
            'month': month,
            'amount': amountStr,
            'status': 'credited',
          },
          removeWhenAppIsKilled: true,
          staleIn: const Duration(hours: 2),
        );
        // Auto-end after 2 hours
        Future.delayed(const Duration(hours: 2), () {
          if (id != null) _liveActivities.endActivity(id);
        });
      } else if (Platform.isAndroid) {
        await _notifications.show(
          id: _payrollNotifId,
          title: '💰 Salary Credited',
          body: '$month salary of $amountStr has been credited to your account',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _payrollChannelId,
              'Payroll Updates',
              importance: Importance.high,
              priority: Priority.high,
              ongoing: false,
              autoCancel: true,
              category: AndroidNotificationCategory.message,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('LIVE_ACTIVITY: Payroll error - $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // UTILS
  // ═══════════════════════════════════════════════════════

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  void dispose() {
    _attendanceTimer?.cancel();
  }
}
