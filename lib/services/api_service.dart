import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/v1';
    }
    return 'http://127.0.0.1:8000/v1';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String endpoint) async {
    var headers = await _getHeaders();
    var response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    }
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    var headers = await _getHeaders();
    var response = await http.post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(data));
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(data));
    }
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    var headers = await _getHeaders();
    var response = await http.put(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(data));
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.put(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonEncode(data));
    }
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    var headers = await _getHeaders();
    var response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    }
    return _handleResponse(response);
  }

  static bool _isRefreshing = false;

  static Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('auth_token', data['access_token']);
        if (data['refresh_token'] != null) {
          await prefs.setString('refresh_token', data['refresh_token']);
        }
        return true;
      }
    } catch (_) {}
    finally { _isRefreshing = false; }
    return false;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    } else {
      try {
        final body = jsonDecode(response.body);
        // Extract a readable error message from various response formats
        dynamic raw = body['detail'] ?? body['error'] ?? body['non_field_errors']?[0] ?? 'Request failed';
        String msg;
        if (raw is Map) {
          msg = raw['message'] ?? raw['detail'] ?? raw.values.first?.toString() ?? 'Request failed';
        } else if (raw is List) {
          msg = raw.first?.toString() ?? 'Request failed';
        } else {
          msg = raw.toString();
        }
        throw Exception(msg);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Request failed (${response.statusCode})');
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> login(String username, String password) async {
    return await post('/auth/login', {'username': username, 'password': password});
  }

  static Future<void> logout() async {
    try {
      await post('/auth/logout', {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    return await post('/auth/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // ═══════════════════════════════════════════════════════
  // USER PROFILE
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getCurrentUser() async {
    return await get('/users/me');
  }

  // ═══════════════════════════════════════════════════════
  // EMPLOYEES / DIRECTORY
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getEmployees({String? search, String? department}) async {
    String qs = '';
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (department != null && department.isNotEmpty) params.add('department=$department');
    if (params.isNotEmpty) qs = '?${params.join('&')}';
    final response = await get('/employees$qs');
    return response['employees'] ?? [];
  }

  static Future<Map<String, dynamic>> getEmployee(int id) async {
    return await get('/employees/$id');
  }

  // ═══════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getTodayAttendance() async {
    return await get('/attendance/today');
  }

  static Future<Map<String, dynamic>> getAttendanceSummary({int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    return await get('/attendance/monthly?month=$m&year=$y');
  }

  static Future<List<dynamic>> getAttendanceHistory({int? month, int? year}) async {
    final response = await getAttendanceSummary(month: month, year: year);
    return response['daily'] ?? [];
  }

  static Future<Map<String, dynamic>> getWeeklyAttendance({String? weekStart}) async {
    final qs = weekStart != null ? '?week_start=$weekStart' : '';
    return await get('/attendance/weekly$qs');
  }

  static Future<Map<String, dynamic>> getTeamAttendance() async {
    return await get('/attendance/team');
  }

  static Future<Map<String, dynamic>> punchIn() async {
    return await post('/attendance/punch-in', {});
  }

  static Future<Map<String, dynamic>> punchOut() async {
    return await post('/attendance/punch-out', {});
  }

  static Future<Map<String, dynamic>> regularizeAttendance(Map<String, dynamic> data) async {
    return await post('/attendance/regularize', data);
  }

  // ═══════════════════════════════════════════════════════
  // LEAVE
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getLeaveBalance() async {
    return await get('/leaves/balance');
  }

  static Future<List<dynamic>> getLeaveRequests() async {
    final response = await get('/leaves/balance');
    return response['balances'] ?? [];
  }

  static Future<Map<String, dynamic>> applyLeave(Map<String, dynamic> data) async {
    return await post('/leaves/apply', data);
  }

  static Future<List<dynamic>> getLeaveTypes() async {
    final response = await get('/leave-types');
    return response['leave_types'] ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // CLAIMS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getClaimRequests() async {
    final response = await get('/requests?type=Claims');
    return response['requests'] ?? [];
  }

  static Future<Map<String, dynamic>> submitClaim(Map<String, dynamic> data) async {
    return await post('/claims/submit', data);
  }

  // ═══════════════════════════════════════════════════════
  // TICKETS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getTickets() async {
    final response = await get('/requests?type=Tickets');
    return response['requests'] ?? [];
  }

  static Future<Map<String, dynamic>> raiseTicket(Map<String, dynamic> data) async {
    return await post('/tickets/raise', data);
  }

  // ═══════════════════════════════════════════════════════
  // SHIFT REQUESTS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> requestShiftChange(Map<String, dynamic> data) async {
    return await post('/shifts/request', data);
  }

  static Future<List<dynamic>> getShifts() async {
    final response = await get('/shifts');
    return response['shifts'] ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // WORK TYPE REQUESTS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> requestWorkType(Map<String, dynamic> data) async {
    return await post('/work-type/request', data);
  }

  static Future<List<dynamic>> getWorkTypes() async {
    final response = await get('/work-types');
    return response['work_types'] ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // ASSET REQUESTS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> requestAsset(Map<String, dynamic> data) async {
    return await post('/assets/request', data);
  }

  // ═══════════════════════════════════════════════════════
  // REQUESTS (ALL TYPES)
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getRequests({
    String? type,
    String? status,
    String role = 'self',
  }) async {
    final params = <String>['role=$role'];
    if (type != null && type != 'all') params.add('type=$type');
    if (status != null && status != 'all') params.add('status=$status');
    return await get('/requests?${params.join('&')}');
  }

  static Future<Map<String, dynamic>> getRequestDetail(int id) async {
    return await get('/requests/$id');
  }

  static Future<Map<String, dynamic>> acceptRequest(int id) async {
    return await put('/requests/$id/accept', {});
  }

  static Future<Map<String, dynamic>> rejectRequest(int id, {String? reason}) async {
    return await put('/requests/$id/reject', reason != null ? {'rejection_reason': reason} : {});
  }

  static Future<void> cancelRequest(int id) async {
    await delete('/requests/$id/cancel');
  }

  // ═══════════════════════════════════════════════════════
  // PAYSLIPS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getPayslip({int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    return await get('/payslips?month=$m&year=$y');
  }

  static Future<Map<String, dynamic>> getPayslipsList({int? year}) async {
    final y = year ?? DateTime.now().year;
    return await get('/payslips/list?year=$y');
  }

  static Future<http.Response> getPayslipPdf(int id) async {
    final headers = await _getHeaders();
    return await http.get(
      Uri.parse('$baseUrl/payslips/$id/pdf'),
      headers: headers,
    );
  }

  // ═══════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getNotifications() async {
    return await get('/notifications');
  }

  static Future<void> markNotificationRead(int id) async {
    await put('/notifications/$id/read', {});
  }

  static Future<void> markAllNotificationsRead() async {
    await put('/notifications/read-all', {});
  }

  static Future<void> registerDevice(String token, String platform) async {
    await post('/notifications/register-device', {
      'token': token,
      'platform': platform,
    });
  }

  // ═══════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    return await get('/dashboard/summary');
  }

  static Future<Map<String, dynamic>> getDashboardAnnouncements() async {
    return await get('/dashboard/announcements');
  }

  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    return await get('/dashboard/analytics');
  }

  // ═══════════════════════════════════════════════════════
  // REFERENCE DATA
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getDepartments() async {
    final response = await get('/departments');
    return response['departments'] ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSettings() async {
    return await get('/settings');
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    return await post('/settings', data);
  }
}
