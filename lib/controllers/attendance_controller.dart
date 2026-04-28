import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';

class AttendanceController {
  AttendanceController._();
  static final AttendanceController instance = AttendanceController._();

  /// Punch in — updates provider, starts live activity, shows notification
  Future<void> punchIn(AppProvider provider) async {
    try {
      await ApiService.punchIn();
      final now = DateTime.now();
      provider.setPunchState(true, now);
      provider.triggerDynamicIsland(
        'Checked In Successfully',
        Icons.login,
        const Color(0xFF34D399),
      );
      NotificationService.instance.showPunchIn();
      LiveActivityService.instance.startPunchIn(
        userName: provider.userName,
        punchTime: now,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ALREADY_PUNCHED_IN') ||
          msg.contains('Already clocked in')) {
        provider.setPunchState(true, provider.punchInTime ?? DateTime.now());
        provider.triggerDynamicIsland(
          'Already Checked In',
          Icons.check_circle,
          const Color(0xFF34D399),
        );
      } else {
        provider.triggerDynamicIsland(
          'Check In Failed',
          Icons.error,
          Colors.red,
        );
      }
    }
  }

  /// Punch out — updates provider, stops live activity, shows notification
  Future<void> punchOut(AppProvider provider) async {
    try {
      final workedDuration = provider.punchInTime != null
          ? DateTime.now().difference(provider.punchInTime!)
          : null;
      await ApiService.punchOut();
      provider.setPunchState(false, null);
      provider.triggerDynamicIsland(
        'Checked Out Successfully',
        Icons.logout,
        const Color(0xFFFF8C42),
      );
      NotificationService.instance.showPunchOut();
      LiveActivityService.instance.stopPunchOut(totalWorked: workedDuration);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('NOT_PUNCHED_IN') ||
          msg.contains('without punching in')) {
        provider.setPunchState(false, null);
        provider.triggerDynamicIsland(
          'Not Checked In Yet',
          Icons.info,
          Colors.orange,
        );
      } else {
        provider.triggerDynamicIsland(
          'Check Out Failed',
          Icons.error,
          Colors.red,
        );
      }
    }
  }

  /// Toggle punch in/out
  Future<void> togglePunch(AppProvider provider) async {
    if (provider.isPunchedIn) {
      await punchOut(provider);
    } else {
      await punchIn(provider);
    }
  }

  /// Fetch monthly attendance history
  Future<List<Map<String, dynamic>>> fetchMonthlyAttendance({
    required int month,
    required int year,
  }) async {
    try {
      final data = await ApiService.getAttendanceHistory(
        month: month,
        year: year,
      );
      return List<Map<String, dynamic>>.from(data is List ? data : []);
    } catch (e) {
      debugPrint('AttendanceController: Error fetching history - $e');
      return [];
    }
  }
}
