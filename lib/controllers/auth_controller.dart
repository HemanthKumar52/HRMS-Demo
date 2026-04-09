import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  /// Login with username/password, returns user data or throws
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final baseUrl = ApiService.baseUrl.replaceAll('/v1', '');
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _persistSession(data);
      return data;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['detail'] ?? 'Invalid credentials');
    }
  }

  /// Persist auth tokens and user data
  Future<void> _persistSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = data['user'];
    await prefs.setString('auth_token', data['access_token']);
    if (data['refresh_token'] != null) {
      await prefs.setString('refresh_token', data['refresh_token']);
    }
    await prefs.setString('employee_id', userData['employee_id'] ?? '');
    await prefs.setString('user_name', userData['name'] ?? '');
    await prefs.setString('user_email', userData['email'] ?? '');
    await prefs.setString('user_designation', userData['designation'] ?? '');
    await prefs.setString('user_department', userData['department'] ?? '');
  }

  /// Apply user data from login response to the provider
  void applyToProvider(AppProvider provider, Map<String, dynamic> data) {
    final userData = data['user'];
    provider.setUserName(userData['name'] ?? '');
    provider.setDesignation(userData['designation'] ?? '');
    provider.setDepartment(userData['department'] ?? '');
    provider.setEmployeeId(userData['employee_id'] ?? '');

    final roleStr = userData['role'] ?? 'employee';
    if (roleStr == 'hr') {
      provider.setRole(UserRole.hr);
    } else if (roleStr == 'manager') {
      provider.setRole(UserRole.manager);
    } else {
      provider.setRole(UserRole.employee);
    }

    provider.login();
  }

  /// Restore session from stored preferences
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Logout — clear stored data
  Future<void> logout(AppProvider provider) async {
    provider.logout();
  }

  /// Get Microsoft SSO login URL
  String getMicrosoftSSOUrl() {
    final baseUrl = ApiService.baseUrl.replaceAll('/v1', '');
    return '$baseUrl/v1/auth/microsoft/login?redirect_uri=ppulse://auth-callback';
  }
}
