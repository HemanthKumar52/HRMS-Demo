import 'package:flutter/material.dart';

enum UserRole { employee, manager, hr }

class AppProvider extends ChangeNotifier {
  UserRole _role = UserRole.employee;
  bool _isLoggedIn = false;
  String _userName = 'Venkat Kumar';
  String _designation = 'Senior Software Engineer';
  String _department = 'Engineering';
  String _employeeId = 'EMP-2024-001';
  bool _isPunchedIn = false;
  DateTime? _punchInTime;
  int _bottomNavIndex = 0;
  int _requestsTabIndex = 0; // 0 = Requests, 1 = Requested

  // Dynamic Island
  bool _showDynamicIsland = false;
  String _dynamicIslandMessage = '';
  IconData _dynamicIslandIcon = Icons.check_circle;
  Color _dynamicIslandColor = Colors.green;

  UserRole get role => _role;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get designation => _designation;
  String get department => _department;
  String get employeeId => _employeeId;
  bool get isPunchedIn => _isPunchedIn;
  DateTime? get punchInTime => _punchInTime;
  int get bottomNavIndex => _bottomNavIndex;
  int get requestsTabIndex => _requestsTabIndex;
  bool get showDynamicIsland => _showDynamicIsland;
  String get dynamicIslandMessage => _dynamicIslandMessage;
  IconData get dynamicIslandIcon => _dynamicIslandIcon;
  Color get dynamicIslandColor => _dynamicIslandColor;

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
  }

  void logout() {
    _isLoggedIn = false;
    _bottomNavIndex = 0;
    notifyListeners();
  }

  void togglePunch() {
    _isPunchedIn = !_isPunchedIn;
    if (_isPunchedIn) {
      _punchInTime = DateTime.now();
      triggerDynamicIsland(
        'Punched In Successfully',
        Icons.login,
        const Color(0xFF34D399),
      );
    } else {
      triggerDynamicIsland(
        'Punched Out Successfully',
        Icons.logout,
        const Color(0xFFFF8C42),
      );
      _punchInTime = null;
    }
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
    _requestsTabIndex = 1;
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
}
