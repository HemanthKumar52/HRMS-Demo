import 'package:flutter/material.dart';
import '../services/live_activity_service.dart';

/// Controller for managing Live Activities (iOS) and ongoing notifications (Android)
/// Used for real-time attendance tracking on lock screen / notification shade.
class LiveActivityController {
  LiveActivityController._();
  static final LiveActivityController instance = LiveActivityController._();

  bool _isActivityRunning = false;
  bool get isActivityRunning => _isActivityRunning;

  /// Initialize the live activity system
  Future<void> init() async {
    try {
      await LiveActivityService.instance.init();
      debugPrint('LiveActivityController: Initialized');
    } catch (e) {
      debugPrint('LiveActivityController: Init error - $e');
    }
  }

  /// Start attendance tracking activity
  Future<void> startAttendance({
    required String userName,
    required DateTime punchTime,
  }) async {
    try {
      await LiveActivityService.instance.startPunchIn(
        userName: userName,
        punchTime: punchTime,
      );
      _isActivityRunning = true;
      debugPrint('LiveActivityController: Attendance activity started');
    } catch (e) {
      debugPrint('LiveActivityController: Start error - $e');
    }
  }

  /// Stop attendance tracking activity
  Future<void> stopAttendance({Duration? totalWorked}) async {
    try {
      await LiveActivityService.instance.stopPunchOut(totalWorked: totalWorked);
      _isActivityRunning = false;
      debugPrint('LiveActivityController: Attendance activity stopped');
    } catch (e) {
      debugPrint('LiveActivityController: Stop error - $e');
    }
  }

  void dispose() {
    LiveActivityService.instance.dispose();
  }
}
