import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

enum UserRole { employee, manager, hr }

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
  Map<String, dynamic> _userProfile = {};
  bool _isLoading = false;

  bool _showDynamicIsland = false;
  String _dynamicIslandMessage = '';
  IconData _dynamicIslandIcon = Icons.check_circle;
  Color _dynamicIslandColor = Colors.green;

  AppProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final designation = prefs.getString('user_designation') ?? '';
    final department = prefs.getString('user_department') ?? '';
    final employeeId = prefs.getString('employee_id') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final token = prefs.getString('auth_token');

    if (token != null && name.isNotEmpty) {
      _userName = name;
      _designation = designation;
      _department = department;
      _employeeId = employeeId;
      _email = email;
      _isLoggedIn = true;
      notifyListeners();
      await fetchDashboardData();
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
        if (att['status'] == 'clocked_in') {
          _isPunchedIn = true;
          if (att['punch_in'] != null) {
            final today = DateTime.now();
            final parts = att['punch_in'].toString().split(':');
            _punchInTime = DateTime(today.year, today.month, today.day,
                int.parse(parts[0]), int.parse(parts[1]));
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
        _recentActivity = List<Map<String, dynamic>>.from(summary['recent_activity'] ?? []);

        // Pending approvals
        _pendingApprovals = Map<String, dynamic>.from(summary['pending_approvals'] ?? {});
      } catch (e) {
        debugPrint('Error fetching dashboard summary: $e');
      }

      // Fetch leave balances
      try {
        final leaveData = await ApiService.getLeaveBalance();
        _leaveRequests = List<Map<String, dynamic>>.from(leaveData['balances'] ?? []);
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
        _announcements = List<Map<String, dynamic>>.from(announcementData['announcements'] ?? []);
      } catch (e) {
        debugPrint('Error fetching announcements: $e');
      }

      // Fetch user profile and update role
      try {
        _userProfile = await ApiService.getCurrentUser();
        final roleStr = _userProfile['role'] ?? '';
        if (roleStr == 'hr') {
          _role = UserRole.hr;
        } else if (roleStr == 'manager') {
          _role = UserRole.manager;
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
        _recentAttendance = List<Map<String, dynamic>>.from(attendance is List ? attendance : []);
      } catch (e) {
        debugPrint('Error fetching attendance: $e');
      }

      // Fetch notifications
      try {
        final notifData = await ApiService.getNotifications();
        _notifications = List<Map<String, dynamic>>.from(notifData['notifications'] ?? []);
        _unreadNotifications = (notifData['unread_count'] ?? 0) as int;
      } catch (e) {
        debugPrint('Error fetching notifications: $e');
      }

      // Fetch claims
      try {
        _claimRequests = List<Map<String, dynamic>>.from(await ApiService.getClaimRequests());
        _approvedClaims = _claimRequests.where((c) => c['status'] == 'approved').length;
      } catch (e) {
        debugPrint('Error fetching claims: $e');
      }

      // Fetch tickets
      try {
        _tickets = List<Map<String, dynamic>>.from(await ApiService.getTickets());
        _openTickets = _tickets.where((t) => t['status'] == 'requested' || t['status'] == 'open').length;
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
      await ApiService.punchIn();
      _isPunchedIn = true;
      _punchInTime = DateTime.now();
      triggerDynamicIsland('Punched In Successfully', Icons.login, const Color(0xFF34D399));
      NotificationService.instance.showPunchIn();
      LiveActivityService.instance.startPunchIn(userName: _userName, punchTime: _punchInTime!);
      notifyListeners();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ALREADY_PUNCHED_IN') || msg.contains('Already clocked in')) {
        // Already punched in — just sync the state
        _isPunchedIn = true;
        _punchInTime ??= DateTime.now();
        triggerDynamicIsland('Already Clocked In', Icons.check_circle, const Color(0xFF34D399));
        notifyListeners();
      } else {
        triggerDynamicIsland('Punch In Failed', Icons.error, Colors.red);
      }
    }
  }

  Future<void> punchOut() async {
    try {
      final workedDuration = _punchInTime != null ? DateTime.now().difference(_punchInTime!) : null;
      await ApiService.punchOut();
      _isPunchedIn = false;
      _punchInTime = null;
      triggerDynamicIsland('Punched Out Successfully', Icons.logout, const Color(0xFFFF8C42));
      NotificationService.instance.showPunchOut();
      LiveActivityService.instance.stopPunchOut(totalWorked: workedDuration);
      notifyListeners();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('NOT_PUNCHED_IN') || msg.contains('without punching in')) {
        _isPunchedIn = false;
        _punchInTime = null;
        triggerDynamicIsland('Not Clocked In Yet', Icons.info, Colors.orange);
        notifyListeners();
      } else {
        triggerDynamicIsland('Punch Out Failed', Icons.error, Colors.red);
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
    final present = _recentAttendance.where((a) => a['status'] == 'present' || a['status'] == 'P').length;
    return (present / _recentAttendance.length * 100).roundToDouble();
  }

  int get totalWorkDays => _recentAttendance.length;
  int get presentDays => _recentAttendance.where((a) => a['status'] == 'present' || a['status'] == 'P').length;

  UserRole get role => _role;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get designation => _designation;
  String get department => _department;
  String get employeeId => _employeeId;
  String get email => _email;
  bool get isPunchedIn => _isPunchedIn;
  DateTime? get punchInTime => _punchInTime;
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
    triggerDynamicIsland('Welcome back, $_userName!', Icons.waving_hand, const Color(0xFF4F8EF7));
  }

  void logout() async {
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

  void updateNotifications(List<Map<String, dynamic>> notifications, int unreadCount) {
    _notifications = notifications;
    _unreadNotifications = unreadCount;
    notifyListeners();
  }

  Future<void> markNotificationRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);
      final idx = _notifications.indexWhere((n) => n['id'].toString() == id.toString());
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