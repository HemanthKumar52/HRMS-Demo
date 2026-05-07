import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/punch_metadata_service.dart';
import '../services/secure_token_service.dart';

enum UserRole { employee, manager, hr, admin }

class AppProvider extends ChangeNotifier {
  UserRole _role = UserRole.employee;
  bool _isLoggedIn = false;
  String _userName = '';
  String _designation = '';
  String _department = '';
  String _employeeId = '';
  String _email = '';
  bool _isPunchedIn = false;
  DateTime? _punchInTime;
  String? _attendanceSource;
  bool _canPunchViaMobile = true;
  int _bottomNavIndex = 0;
  int _requestsTabIndex = 0;

  int _leaveBalance = 0;
  int _approvedLeaves = 0;
  int _pendingLeaves = 0;
  int _approvedClaims = 0;
  double _claimAmount = 0;
  int _openTickets = 0;
  double _attendancePct = 0;
  List<Map<String, dynamic>> _recentAttendance = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _leaveBalances = [];
  List<Map<String, dynamic>> _claimRequests = [];
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadNotifications = 0;
  Map<String, dynamic> _pendingApprovals = {};
  Map<String, dynamic> _teamSummary = {};
  Map<String, dynamic> _userProfile = {};
  bool _isLoading = false;

  bool _showDynamicIsland = false;
  String _dynamicIslandMessage = '';
  IconData _dynamicIslandIcon = Icons.check_circle;
  Color _dynamicIslandColor = Colors.green;

  Timer? _attendancePollTimer;
  Timer? _heartbeatTimer;
  // Timesheet removed — timers cleaned up.

  AppProvider() {
    _loadUserData();
    _loadIpSetting();
  }

  @override
  void dispose() {
    _attendancePollTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  /// Start the activity-status heartbeat. Pings /v1/me/heartbeat every 30s
  /// while the app is foregrounded so other users see this account as online.
  void _startHeartbeat({Duration interval = const Duration(seconds: 30)}) {
    _heartbeatTimer?.cancel();
    // Fire one immediately on start so the user is "online" right away.
    if (_isLoggedIn) ApiService.heartbeat();
    _heartbeatTimer = Timer.periodic(interval, (_) {
      if (_isLoggedIn) ApiService.heartbeat();
    });
  }

  /// Start polling /attendance/today every [interval] so a biometric punch made
  /// outside the app is reflected automatically (timer + UI flip to "Synced from
  /// Biometric"). Safe to call multiple times — replaces any existing timer.
  void _startAttendancePolling({
    Duration interval = const Duration(seconds: 30),
  }) {
    _attendancePollTimer?.cancel();
    _attendancePollTimer = Timer.periodic(interval, (_) {
      if (_isLoggedIn) refreshAttendanceStatus();
    });
  }

  /// Lightweight refresh of just the attendance/today record. Updates
  /// [isPunchedIn], [punchInTime], [attendanceSource], [canPunchViaMobile].
  Future<void> refreshAttendanceStatus() async {
    if (!_isLoggedIn) return;
    try {
      final att = await ApiService.getTodayAttendance();
      final wasPunchedIn = _isPunchedIn;
      final wasSource = _attendanceSource;

      _attendanceSource = att['source'] as String?;
      _canPunchViaMobile = att['can_punch_via_mobile'] as bool? ?? true;
      final statusStr = att['status'] as String?;

      if (statusStr == 'checked_in' || statusStr == 'clocked_in') {
        _isPunchedIn = true;
        // Backend stores attendance_clock_in in UTC (TIME_ZONE='UTC' / USE_TZ=True)
        // and `/attendance/today` returns it as a bare "HH:MM:SS" string. Build a
        // UTC DateTime then convert to the device's local time so the dashboard
        // timer matches reality across timezones.
        final raw = att['punch_in']?.toString();
        if (raw != null && raw.isNotEmpty) {
          final parts = raw.split(':');
          if (parts.length >= 2) {
            final h = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[1]) ?? 0;
            final s = parts.length >= 3
                ? (int.tryParse(parts[2].split('.').first) ?? 0)
                : 0;
            final nowUtc = DateTime.now().toUtc();
            var utcStamp = DateTime.utc(
              nowUtc.year,
              nowUtc.month,
              nowUtc.day,
              h,
              m,
              s,
            );
            // If the backend time is *after* the current UTC moment, the punch-in
            // must have happened just before midnight UTC on the previous day.
            if (utcStamp.isAfter(nowUtc)) {
              utcStamp = utcStamp.subtract(const Duration(days: 1));
            }
            _punchInTime = utcStamp.toLocal();
          }
        }
      } else {
        _isPunchedIn = false;
        _punchInTime = null;
      }

      // If biometric just appeared while we weren't punched in, surface a toast +
      // start the live activity timer so the dashboard shows the running clock.
      final biometricArrived =
          !wasPunchedIn && _isPunchedIn && _attendanceSource == 'biometric';
      if (biometricArrived && _punchInTime != null) {
        triggerDynamicIsland(
          'Synced from Biometric',
          Icons.fingerprint,
          const Color(0xFF34D399),
        );
        try {
          LiveActivityService.instance.startPunchIn(
            userName: _userName,
            punchTime: _punchInTime!,
          );
        } catch (_) {
          /* live activity is best-effort */
        }
      }

      if (wasPunchedIn != _isPunchedIn || wasSource != _attendanceSource) {
        notifyListeners();
      }
    } catch (_) {
      // Network blip — keep current state, try again on the next tick.
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final designation = prefs.getString('user_designation') ?? '';
    final department = prefs.getString('user_department') ?? '';
    final employeeId = prefs.getString('employee_id') ?? '';
    final email = prefs.getString('user_email') ?? '';
    // Check secure storage first, fallback to SharedPreferences
    final secureToken = await SecureTokenService.instance.getAccessToken();
    final token = secureToken ?? prefs.getString('auth_token');

    if (token != null && name.isNotEmpty) {
      _userName = name;
      _designation = designation;
      _department = department;
      _employeeId = employeeId;
      _email = email;
      _isLoggedIn = true;
      notifyListeners();
      await fetchDashboardData();
      _startAttendancePolling();
      _startHeartbeat();
    }
  }

  Future<void> fetchDashboardData() async {
    if (!_isLoggedIn) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch dashboard summary (attendance, leave balance, recent activity)
      try {
        final summary = await ApiService.getDashboardSummary();

        // Attendance status
        final att = summary['attendance'] ?? {};
        _attendanceSource = att['source'] as String?;
        _canPunchViaMobile = att['can_punch_via_mobile'] as bool? ?? true;
        if (att['status'] == 'checked_in' || att['status'] == 'clocked_in') {
          _isPunchedIn = true;
          if (att['punch_in'] != null) {
            // Backend time is UTC — convert to device-local. See refreshAttendanceStatus().
            final parts = att['punch_in'].toString().split(':');
            final h = int.tryParse(parts[0]) ?? 0;
            final m = parts.length >= 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
            final s = parts.length >= 3
                ? (int.tryParse(parts[2].split('.').first) ?? 0)
                : 0;
            final nowUtc = DateTime.now().toUtc();
            var utcStamp = DateTime.utc(
              nowUtc.year,
              nowUtc.month,
              nowUtc.day,
              h,
              m,
              s,
            );
            if (utcStamp.isAfter(nowUtc)) {
              utcStamp = utcStamp.subtract(const Duration(days: 1));
            }
            _punchInTime = utcStamp.toLocal();
          }
        } else {
          _isPunchedIn = false;
          _punchInTime = null;
        }

        // Leave balance from summary
        final lb = summary['leave_balance'] ?? {};
        _leaveBalance = (lb['total_remaining'] ?? 0) as int;
        _attendancePct = ((lb['attendance_percentage'] ?? 0) as num).toDouble();

        // Leave summary breakdown
        final ls = summary['leave_summary'] ?? {};
        _leaveBalances = [];
        ls.forEach((key, value) {
          _leaveBalances.add(Map<String, dynamic>.from(value));
        });

        // Recent activity
        _recentActivity = List<Map<String, dynamic>>.from(
          summary['recent_activity'] ?? [],
        );

        // Pending approvals
        _pendingApprovals = Map<String, dynamic>.from(
          summary['pending_approvals'] ?? {},
        );
        // Team block (size, departments, work_types, today snapshot)
        _teamSummary = Map<String, dynamic>.from(summary['team'] ?? {});
      } catch (e) {
        debugPrint('Error fetching dashboard summary: $e');
      }

      // Fetch leave balances
      try {
        final leaveData = await ApiService.getLeaveBalance();
        _leaveRequests = List<Map<String, dynamic>>.from(
          leaveData['balances'] ?? [],
        );
        _leaveBalance = ((leaveData['total_remaining'] ?? 0) as num).toInt();
        _pendingLeaves = 0;
        _approvedLeaves = 0;
        for (var b in _leaveRequests) {
          _pendingLeaves += ((b['used'] ?? 0) as num).toInt();
        }
      } catch (e) {
        debugPrint('Error fetching leaves: $e');
      }

      // Fetch announcements
      try {
        final announcementData = await ApiService.getDashboardAnnouncements();
        _announcements = List<Map<String, dynamic>>.from(
          announcementData['announcements'] ?? [],
        );
      } catch (e) {
        debugPrint('Error fetching announcements: $e');
      }

      // Fetch user profile and update role
      try {
        _userProfile = await ApiService.getCurrentUser();
        final roleStr = _userProfile['role'] ?? '';
        if (roleStr == 'admin') {
          _role = UserRole.admin;
        } else if (roleStr == 'hr') {
          _role = UserRole.hr;
        } else if (roleStr == 'manager') {
          _role = UserRole.manager;
        } else {
          _role = UserRole.employee;
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }

      // Fetch monthly attendance
      try {
        final now = DateTime.now();
        final attendance = await ApiService.getAttendanceHistory(
          month: now.month,
          year: now.year,
        );
        _recentAttendance = List<Map<String, dynamic>>.from(
          attendance is List ? attendance : [],
        );
      } catch (e) {
        debugPrint('Error fetching attendance: $e');
      }

      // Fetch notifications
      try {
        final notifData = await ApiService.getNotifications();
        _notifications = List<Map<String, dynamic>>.from(
          notifData['notifications'] ?? [],
        );
        _unreadNotifications = (notifData['unread_count'] ?? 0) as int;
      } catch (e) {
        debugPrint('Error fetching notifications: $e');
      }

      // Fetch claims
      try {
        _claimRequests = List<Map<String, dynamic>>.from(
          await ApiService.getClaimRequests(),
        );
        _approvedClaims = _claimRequests
            .where((c) => c['status'] == 'approved')
            .length;
      } catch (e) {
        debugPrint('Error fetching claims: $e');
      }

      // Fetch tickets
      try {
        _tickets = List<Map<String, dynamic>>.from(
          await ApiService.getTickets(),
        );
        _openTickets = _tickets
            .where((t) => t['status'] == 'requested' || t['status'] == 'open')
            .length;
      } catch (e) {
        debugPrint('Error fetching tickets: $e');
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> punchIn() async {
    try {
      // Capture location + device info silently
      final metadata = await PunchMetadataService.instance.capture();
      await ApiService.punchIn(metadata);
      _isPunchedIn = true;
      _punchInTime = DateTime.now();
      _attendanceSource = metadata['source'] as String?;
      _canPunchViaMobile = true;
      triggerDynamicIsland(
        'Checked In Successfully',
        Icons.login,
        const Color(0xFF34D399),
      );
      NotificationService.instance.showPunchIn();
      LiveActivityService.instance.startPunchIn(
        userName: _userName,
        punchTime: _punchInTime!,
      );
      notifyListeners();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('GEOFENCE_OFFICE')) {
        triggerDynamicIsland(
          "You're at the office — use the biometric device",
          Icons.fingerprint,
          Colors.orange,
        );
      } else if (msg.contains('BIOMETRIC_PUNCH_ACTIVE')) {
        triggerDynamicIsland(
          'Already Checked In via Biometric',
          Icons.fingerprint,
          Colors.orange,
        );
      } else if (msg.contains('ALREADY_PUNCHED_IN') ||
          msg.contains('Already clocked in')) {
        _isPunchedIn = true;
        _punchInTime ??= DateTime.now();
        triggerDynamicIsland(
          'Already Checked In',
          Icons.check_circle,
          const Color(0xFF34D399),
        );
        notifyListeners();
      } else {
        triggerDynamicIsland('Check In Failed', Icons.error, Colors.red);
      }
    }
  }

  /// WFH face-verified punch-in. Returns null on success, or an error code string
  /// on failure (e.g. 'GEOFENCE_OFFICE', 'WFH_OUT_OF_ZONE', 'FACE_VERIFICATION_FAILED',
  /// 'FACE_MISMATCH', 'BIOMETRIC_PUNCH_ACTIVE', 'ALREADY_PUNCHED_IN').
  Future<String?> facePunchIn(
    String imageBase64, {
    List<String>? extraFrames,
  }) async {
    try {
      final metadata = await PunchMetadataService.instance.capture();
      await ApiService.facePunchIn(
        imageBase64: imageBase64,
        metadata: metadata,
        extraFrames: extraFrames,
      );
      _isPunchedIn = true;
      _punchInTime = DateTime.now();
      _attendanceSource = metadata['source'] as String?;
      _canPunchViaMobile = true;
      triggerDynamicIsland(
        'Checked In Successfully',
        Icons.login,
        const Color(0xFF34D399),
      );
      NotificationService.instance.showPunchIn();
      LiveActivityService.instance.startPunchIn(
        userName: _userName,
        punchTime: _punchInTime!,
      );
      notifyListeners();
      return null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('LOCATION_REQUIRED')) {
        triggerDynamicIsland(
          'Location permission required',
          Icons.location_off,
          Colors.orange,
        );
        return 'LOCATION_REQUIRED';
      } else if (msg.contains('GEOFENCE_OFFICE')) {
        triggerDynamicIsland(
          "You're at the office — use the biometric device",
          Icons.fingerprint,
          Colors.orange,
        );
        return 'GEOFENCE_OFFICE';
      } else if (msg.contains('WFH_OUT_OF_ZONE')) {
        triggerDynamicIsland(
          'Not in an authorized WFH zone',
          Icons.location_off,
          Colors.orange,
        );
        return 'WFH_OUT_OF_ZONE';
      } else if (msg.contains('FACE_MISMATCH')) {
        triggerDynamicIsland(
          'Face does not match this account',
          Icons.error,
          Colors.red,
        );
        return 'FACE_MISMATCH';
      } else if (msg.contains('FACE_VERIFICATION_FAILED')) {
        triggerDynamicIsland('Unknown user', Icons.no_accounts, Colors.red);
        return 'FACE_VERIFICATION_FAILED';
      } else if (msg.contains('BIOMETRIC_PUNCH_ACTIVE')) {
        triggerDynamicIsland(
          'Already Checked In via Biometric',
          Icons.fingerprint,
          Colors.orange,
        );
        return 'BIOMETRIC_PUNCH_ACTIVE';
      } else if (msg.contains('ALREADY_PUNCHED_IN')) {
        _isPunchedIn = true;
        _punchInTime ??= DateTime.now();
        triggerDynamicIsland(
          'Already Checked In',
          Icons.check_circle,
          const Color(0xFF34D399),
        );
        notifyListeners();
        return 'ALREADY_PUNCHED_IN';
      }
      triggerDynamicIsland('Check In Failed', Icons.error, Colors.red);
      return 'UNKNOWN_ERROR';
    }
  }

  Future<void> punchOut() async {
    try {
      final workedDuration = _punchInTime != null
          ? DateTime.now().difference(_punchInTime!)
          : null;
      final metadata = await PunchMetadataService.instance.capture();
      await ApiService.punchOut(metadata);
      _isPunchedIn = false;
      _punchInTime = null;
      _attendanceSource = null;
      _canPunchViaMobile = true;
      triggerDynamicIsland(
        'Checked Out Successfully',
        Icons.logout,
        const Color(0xFFFF8C42),
      );
      NotificationService.instance.showPunchOut();
      LiveActivityService.instance.stopPunchOut(totalWorked: workedDuration);
      notifyListeners();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('BIOMETRIC_PUNCH_ACTIVE')) {
        triggerDynamicIsland(
          'Use Biometric Device to Check Out',
          Icons.fingerprint,
          Colors.orange,
        );
      } else if (msg.contains('NOT_PUNCHED_IN') ||
          msg.contains('without punching in')) {
        _isPunchedIn = false;
        _punchInTime = null;
        triggerDynamicIsland('Not Checked In Yet', Icons.info, Colors.orange);
        notifyListeners();
      } else {
        triggerDynamicIsland('Check Out Failed', Icons.error, Colors.red);
      }
    }
  }

  void togglePunch() {
    if (_isPunchedIn) {
      punchOut();
    } else {
      punchIn();
    }
  }

  double get attendancePercentage {
    if (_recentAttendance.isEmpty) return 0;
    final present = _recentAttendance
        .where((a) => a['status'] == 'present' || a['status'] == 'P')
        .length;
    return (present / _recentAttendance.length * 100).roundToDouble();
  }

  int get totalWorkDays => _recentAttendance.length;
  int get presentDays => _recentAttendance
      .where((a) => a['status'] == 'present' || a['status'] == 'P')
      .length;

  UserRole get role => _role;
  bool get isAdmin => _role == UserRole.admin;
  bool get isHr => _role == UserRole.hr;
  bool get isManager => _role == UserRole.manager;
  bool get isEmployee => _role == UserRole.employee;

  /// Admin/HR/Manager all need approval-style access. Admin implies HR scope.
  bool get isManagerOrAbove =>
      _role == UserRole.manager ||
      _role == UserRole.hr ||
      _role == UserRole.admin;
  // Manager setting: show IP in attendance detail popup
  bool _showIpInAttendance = false;
  bool get showIpInAttendance => _showIpInAttendance;
  Future<void> toggleShowIp() async {
    _showIpInAttendance = !_showIpInAttendance;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_ip_attendance', _showIpInAttendance);
    notifyListeners();
  }

  Future<void> _loadIpSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _showIpInAttendance = prefs.getBool('show_ip_attendance') ?? false;
  }

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get designation => _designation;
  String get department => _department;
  String get employeeId => _employeeId;
  String get email => _email;
  bool get isPunchedIn => _isPunchedIn;
  DateTime? get punchInTime => _punchInTime;
  String? get attendanceSource => _attendanceSource;
  bool get canPunchViaMobile => _canPunchViaMobile;
  bool get isBiometricPunch => _attendanceSource == 'biometric';
  int get bottomNavIndex => _bottomNavIndex;
  int get requestsTabIndex => _requestsTabIndex;
  bool get showDynamicIsland => _showDynamicIsland;
  String get dynamicIslandMessage => _dynamicIslandMessage;
  IconData get dynamicIslandIcon => _dynamicIslandIcon;
  Color get dynamicIslandColor => _dynamicIslandColor;
  int get leaveBalance => _leaveBalance;
  int get approvedLeaves => _approvedLeaves;
  int get pendingLeaves => _pendingLeaves;
  int get approvedClaims => _approvedClaims;
  double get claimAmount => _claimAmount;
  int get openTickets => _openTickets;
  List<Map<String, dynamic>> get recentAttendance => _recentAttendance;
  List<Map<String, dynamic>> get leaveRequests => _leaveRequests;
  List<Map<String, dynamic>> get leaveBalances => _leaveBalances;
  List<Map<String, dynamic>> get claimRequests => _claimRequests;
  List<Map<String, dynamic>> get tickets => _tickets;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  List<Map<String, dynamic>> get announcements => _announcements;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadNotifications => _unreadNotifications;
  Map<String, dynamic> get pendingApprovals => _pendingApprovals;
  Map<String, dynamic> get teamSummary => _teamSummary;
  Map<String, dynamic> get userProfile => _userProfile;
  double get attendancePct => _attendancePct;
  bool get isLoading => _isLoading;

  void setRole(UserRole role) {
    _role = role;
    _bottomNavIndex = 0;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
    triggerDynamicIsland(
      'Welcome back, $_userName!',
      Icons.waving_hand,
      const Color(0xFF4F8EF7),
    );
    _startAttendancePolling();
    _startHeartbeat();
  }

  void logout() async {
    _attendancePollTimer?.cancel();
    _attendancePollTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isLoggedIn = false;
    _userName = '';
    _designation = '';
    _department = '';
    _employeeId = '';
    _email = '';
    _isPunchedIn = false;
    _punchInTime = null;
    _leaveBalance = 0;
    _approvedLeaves = 0;
    _pendingLeaves = 0;
    _approvedClaims = 0;
    _claimAmount = 0;
    _openTickets = 0;
    _recentAttendance = [];
    _leaveRequests = [];
    _claimRequests = [];
    _tickets = [];
    _bottomNavIndex = 0;
    await ApiService.logout();
    await SecureTokenService.instance.clearAll();
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }

  void setRequestsTabIndex(int index) {
    _requestsTabIndex = index;
    notifyListeners();
  }

  void navigateToRequested() {
    _bottomNavIndex = 1;
    _requestsTabIndex = 0;
    notifyListeners();
  }

  void triggerDynamicIsland(String message, IconData icon, Color color) {
    _showDynamicIsland = true;
    _dynamicIslandMessage = message;
    _dynamicIslandIcon = icon;
    _dynamicIslandColor = color;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _showDynamicIsland = false;
      notifyListeners();
    });
  }

  void setPunchState(bool isPunchedIn, DateTime? punchTime) {
    _isPunchedIn = isPunchedIn;
    _punchInTime = punchTime;
    notifyListeners();
  }

  void setAnnouncements(List<Map<String, dynamic>> announcements) {
    _announcements = announcements;
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setDesignation(String d) {
    _designation = d;
    notifyListeners();
  }

  void setDepartment(String d) {
    _department = d;
    notifyListeners();
  }

  void setEmployeeId(String id) {
    _employeeId = id;
    notifyListeners();
  }

  void updateNotifications(
    List<Map<String, dynamic>> notifications,
    int unreadCount,
  ) {
    _notifications = notifications;
    _unreadNotifications = unreadCount;
    notifyListeners();
  }

  Future<void> markNotificationRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);
      final idx = _notifications.indexWhere(
        (n) => n['id'].toString() == id.toString(),
      );
      if (idx >= 0) {
        _notifications[idx]['read'] = true;
        _unreadNotifications = (_unreadNotifications - 1).clamp(0, 999);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      for (var n in _notifications) {
        n['read'] = true;
      }
      _unreadNotifications = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }
}
