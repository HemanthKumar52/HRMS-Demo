import 'package:flutter/material.dart';
import '../services/live_activity_service.dart';

/// Controller for managing Live Activities (iOS) and ongoing notifications (Android).
/// Supports: Attendance tracking, Leave request status, Shift reminders, Payroll.
class LiveActivityController {
  LiveActivityController._();
  static final LiveActivityController instance = LiveActivityController._();

  bool _isAttendanceRunning = false;
  bool get isAttendanceRunning => _isAttendanceRunning;

  Future<void> init() async {
    try {
      await LiveActivityService.instance.init();
    } catch (e) {
      debugPrint('LiveActivityController: Init error - $e');
    }
  }

  // ── Attendance ──────────────────────────────────────

  Future<void> startAttendance({
    required String userName,
    required DateTime punchTime,
  }) async {
    await LiveActivityService.instance.startPunchIn(
      userName: userName,
      punchTime: punchTime,
    );
    _isAttendanceRunning = true;
  }

  Future<void> stopAttendance({Duration? totalWorked}) async {
    await LiveActivityService.instance.stopPunchOut(totalWorked: totalWorked);
    _isAttendanceRunning = false;
  }

  // ── Leave Tracking ──────────────────────────────────

  Future<void> trackLeaveRequest({
    required String leaveType,
    required String dateRange,
    String status = 'submitted',
  }) async {
    await LiveActivityService.instance.startLeaveTracking(
      leaveType: leaveType,
      dateRange: dateRange,
      status: status,
    );
  }

  Future<void> updateLeaveRequestStatus({
    required String status,
    String? reviewerName,
  }) async {
    await LiveActivityService.instance.updateLeaveStatus(
      status: status,
      reviewerName: reviewerName,
    );
  }

  // ── Shift Reminder ──────────────────────────────────

  Future<void> remindShift({
    required String shiftName,
    required DateTime shiftStart,
    required DateTime shiftEnd,
  }) async {
    await LiveActivityService.instance.showShiftReminder(
      shiftName: shiftName,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
    );
  }

  Future<void> dismissShift() async {
    await LiveActivityService.instance.dismissShiftReminder();
  }

  // ── Payroll ──────────────────────────────────────────

  Future<void> notifyPayrollCredited({
    required String month,
    required double netPay,
    String currency = '₹',
  }) async {
    await LiveActivityService.instance.showPayrollCredited(
      month: month,
      netPay: netPay,
      currency: currency,
    );
  }

  void dispose() {
    LiveActivityService.instance.dispose();
  }
}
