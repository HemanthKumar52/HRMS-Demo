import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Backend host. Can be overridden at build/run time with
  /// `--dart-define=API_HOST=192.168.1.26` so the same APK works on the
  /// Android emulator (10.0.2.2), an iOS simulator (127.0.0.1), or a real
  /// device on the LAN.
  static const String _apiHostOverride = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );
  static const String _apiPortOverride = String.fromEnvironment(
    'API_PORT',
    defaultValue: '8000',
  );

  static String get baseUrl {
    if (_apiHostOverride.isNotEmpty) {
      return 'http://$_apiHostOverride:$_apiPortOverride/v1';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_apiPortOverride/v1';
    }
    return 'http://127.0.0.1:$_apiPortOverride/v1';
  }

  /// Web backend URL for payroll APIs.
  /// In production: same server. In dev: separate port (8001).
  static const String _webPortOverride = String.fromEnvironment(
    'WEB_PORT',
    defaultValue: '8001',
  );

  static String get webBaseUrl {
    if (_apiHostOverride.isNotEmpty) {
      return 'http://$_apiHostOverride:$_webPortOverride/api';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_webPortOverride/api';
    }
    return 'http://127.0.0.1:$_webPortOverride/api';
  }

  /// JWT token for the web backend (separate from mobile backend token).
  static String? _webToken;

  static Future<String> _getWebToken() async {
    if (_webToken != null) return _webToken!;
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_name_login') ?? 'admin';
    final password = prefs.getString('user_pass_login') ?? 'admin23';
    final resp = await http.post(
      Uri.parse('$webBaseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      _webToken = data['access'] as String?;
      return _webToken ?? '';
    }
    return '';
  }

  /// Clear web token on logout.
  static void clearWebToken() => _webToken = null;

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
    var response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
    }
    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    var headers = await _getHeaders();
    var response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
    }
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    var headers = await _getHeaders();
    var response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
    }
    return _handleResponse(response);
  }

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    var headers = await _getHeaders();
    var response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
    }
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    var headers = await _getHeaders();
    var response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    if (response.statusCode == 401 && await _tryRefreshToken()) {
      headers = await _getHeaders();
      response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
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
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
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
        dynamic raw =
            body['detail'] ??
            body['error'] ??
            body['non_field_errors']?[0] ??
            'Request failed';
        String msg;
        String? code;
        if (raw is Map) {
          msg =
              raw['message'] ??
              raw['detail'] ??
              raw.values.first?.toString() ??
              'Request failed';
          code = raw['code']?.toString();
        } else if (raw is List) {
          msg = raw.first?.toString() ?? 'Request failed';
        } else {
          msg = raw.toString();
        }
        // Embed the error code into the exception so callers can match it
        throw Exception(code != null ? '[$code] $msg' : msg);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Request failed (${response.statusCode})');
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    return await post('/auth/login', {
      'username': username,
      'password': password,
    });
  }

  static Future<void> logout() async {
    try {
      await post('/auth/logout', {});
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
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

  static Future<List<dynamic>> getEmployees({
    String? search,
    String? department,
  }) async {
    String qs = '';
    final params = <String>[];
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (department != null && department.isNotEmpty)
      params.add('department=$department');
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

  static Future<Map<String, dynamic>> getAttendanceSummary({
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    return await get('/attendance/monthly?month=$m&year=$y');
  }

  static Future<List<dynamic>> getAttendanceHistory({
    int? month,
    int? year,
  }) async {
    final response = await getAttendanceSummary(month: month, year: year);
    return response['daily'] ?? [];
  }

  static Future<Map<String, dynamic>> getWeeklyAttendance({
    String? weekStart,
  }) async {
    final qs = weekStart != null ? '?week_start=$weekStart' : '';
    return await get('/attendance/weekly$qs');
  }

  static Future<Map<String, dynamic>> getTeamAttendance() async {
    return await get('/attendance/team');
  }

  static Future<Map<String, dynamic>> punchIn([
    Map<String, dynamic>? metadata,
  ]) async {
    return await post('/attendance/punch-in', metadata ?? {});
  }

  /// WFH face-verified punch-in. `imageBase64` is the raw base64-encoded JPEG/PNG
  /// of the user's selfie. Other metadata (lat/lng/source/device_info) is merged in.
  static Future<Map<String, dynamic>> facePunchIn({
    required String imageBase64,
    Map<String, dynamic>? metadata,
    List<String>? extraFrames,
  }) async {
    final body = <String, dynamic>{
      'image': imageBase64,
      if (extraFrames != null && extraFrames.isNotEmpty)
        'extra_frames': extraFrames,
      ...?metadata,
    };
    return await post('/attendance/face-punch-in', body);
  }

  static Future<Map<String, dynamic>> punchOut([
    Map<String, dynamic>? metadata,
  ]) async {
    return await post('/attendance/punch-out', metadata ?? {});
  }

  static Future<Map<String, dynamic>> regularizeAttendance(
    Map<String, dynamic> data,
  ) async {
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

  static Future<Map<String, dynamic>> applyLeave(
    Map<String, dynamic> data,
  ) async {
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

  static Future<Map<String, dynamic>> submitClaim(
    Map<String, dynamic> data,
  ) async {
    return await post('/claims/submit', data);
  }

  // ═══════════════════════════════════════════════════════
  // TICKETS
  // ═══════════════════════════════════════════════════════

  static Future<List<dynamic>> getTickets() async {
    final response = await get('/requests?type=Tickets');
    return response['requests'] ?? [];
  }

  static Future<Map<String, dynamic>> raiseTicket(
    Map<String, dynamic> data,
  ) async {
    return await post('/tickets/raise', data);
  }

  // ═══════════════════════════════════════════════════════
  // SHIFT REQUESTS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> requestShiftChange(
    Map<String, dynamic> data,
  ) async {
    return await post('/shifts/request', data);
  }

  static Future<List<dynamic>> getShifts() async {
    final response = await get('/shifts');
    return response['shifts'] ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // WORK TYPE REQUESTS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> requestWorkType(
    Map<String, dynamic> data,
  ) async {
    return await post('/work-type/request', data);
  }

  static Future<List<dynamic>> getWorkTypes() async {
    final response = await get('/work-types');
    return response['work_types'] ?? [];
  }

  // ═══════════════════════════════════════════════════════
  // ASSET REQUESTS
  // ═══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> requestAsset(
    Map<String, dynamic> data,
  ) async {
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

  static Future<Map<String, dynamic>> acceptRequest(
    int id, {
    String? comment,
  }) async {
    final body = (comment != null && comment.isNotEmpty)
        ? {'comment': comment}
        : <String, dynamic>{};
    return await put('/requests/$id/accept', body);
  }

  static Future<Map<String, dynamic>> rejectRequest(
    int id, {
    String? reason,
  }) async {
    return await put(
      '/requests/$id/reject',
      reason != null ? {'rejection_reason': reason} : {},
    );
  }

  static Future<void> cancelRequest(int id) async {
    await delete('/requests/$id/cancel');
  }

  // ═══════════════════════════════════════════════════════
  // PAYSLIPS
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  // PAYROLL — calls the mobile backend proxy which forwards
  // to the HRMS web backend. Falls back to direct web calls
  // or local mobile-backend data when the proxy is unavailable.
  // ═══════════════════════════════════════════════════════

  /// Fetch paginated payslip list via the mobile backend proxy.
  /// Pass [admin] = true to request the admin view (all employees).
  static Future<Map<String, dynamic>> getWebPayslips({
    bool admin = false,
  }) async {
    final qs = admin ? '?view=admin' : '';
    return await get('/payslip/web/$qs');
  }

  /// Fetch a single payslip's full detail via the mobile backend proxy.
  static Future<Map<String, dynamic>> getWebPayslipDetail(int id) async {
    return await get('/payslip/web/$id/');
  }

  /// List payslips from web backend (via proxy).
  /// - Admin: sees all employees' payslips (grouped by employee name)
  /// - Manager: sees assigned team's payslips (in production with shared DB)
  /// - Employee: sees only own payslips
  /// Filtered to past 6 months only.
  static Future<Map<String, dynamic>> getPayslipsList({
    int? year,
    String? filterEmployee,
  }) async {
    final y = year ?? DateTime.now().year;
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

    // Try local mobile DB first (always available, has synced data).
    try {
      final localData = await get('/payslips/list?year=$y');
      final localPayslips = localData['payslips'] as List? ?? [];
      if (localPayslips.isNotEmpty) return localData;
    } catch (_) {}

    // Then try the mobile-backend proxy (proxies to web HRMS).
    try {
      final proxyData = await getWebPayslips(admin: true);
      final results = List<Map<String, dynamic>>.from(
        proxyData['results'] ?? [],
      );

      final filtered = results.where((p) {
        final sd = p['start_date']?.toString() ?? '';
        final yearMatch = sd.startsWith('$y-');
        final pDate = DateTime.tryParse(sd);
        final withinWindow = pDate != null && pDate.isAfter(sixMonthsAgo);
        if (filterEmployee != null && filterEmployee.isNotEmpty) {
          final empName = (p['employee'] as Map?)?['name']?.toString() ?? '';
          return yearMatch && withinWindow && empName == filterEmployee;
        }
        return yearMatch && withinWindow;
      }).toList();

      final employees = <String>{};
      for (final p in results) {
        final name = (p['employee'] as Map?)?['name']?.toString() ?? '';
        if (name.isNotEmpty) employees.add(name);
      }

      return {
        'year': y,
        'employees': employees.toList()..sort(),
        'payslips': filtered.map((p) {
          final sd = p['start_date']?.toString() ?? '';
          final month =
              int.tryParse(sd.split('-').elementAtOrNull(1) ?? '') ?? 0;
          return {
            'id': p['id'],
            'month': month,
            'label': p['payslip_month_year'] ?? '',
            'employee_name': (p['employee'] as Map?)?['name'] ?? '',
            'employee_badge': (p['employee'] as Map?)?['badge_id'] ?? '',
            'net_pay': p['net_pay'] ?? 0,
            'gross_pay': p['gross_pay'] ?? 0,
            'deduction': p['deduction'] ?? 0,
            'status': p['status'] ?? '',
            'currency': p['currency'] ?? '\u20B9',
          };
        }).toList(),
      };
    } catch (_) {}

    // Fallback: call web backend directly (legacy path).
    try {
      final token = await _getWebToken();
      final resp = await http.get(
        Uri.parse('$webBaseUrl/payroll/payslip/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = List<Map<String, dynamic>>.from(data['results'] ?? []);

        final filtered = results.where((p) {
          final sd = p['start_date']?.toString() ?? '';
          final yearMatch = sd.startsWith('$y-');
          final pDate = DateTime.tryParse(sd);
          final withinWindow = pDate != null && pDate.isAfter(sixMonthsAgo);
          if (filterEmployee != null && filterEmployee.isNotEmpty) {
            final empName = (p['employee'] as Map?)?['name']?.toString() ?? '';
            return yearMatch && withinWindow && empName == filterEmployee;
          }
          return yearMatch && withinWindow;
        }).toList();

        final employees = <String>{};
        for (final p in results) {
          final name = (p['employee'] as Map?)?['name']?.toString() ?? '';
          if (name.isNotEmpty) employees.add(name);
        }

        return {
          'year': y,
          'employees': employees.toList()..sort(),
          'payslips': filtered.map((p) {
            final sd = p['start_date']?.toString() ?? '';
            final month =
                int.tryParse(sd.split('-').elementAtOrNull(1) ?? '') ?? 0;
            return {
              'id': p['id'],
              'month': month,
              'label': p['payslip_month_year'] ?? '',
              'employee_name': (p['employee'] as Map?)?['name'] ?? '',
              'employee_badge': (p['employee'] as Map?)?['badge_id'] ?? '',
              'net_pay': p['net_pay'] ?? 0,
              'gross_pay': p['gross_pay'] ?? 0,
              'deduction': p['deduction'] ?? 0,
              'status': p['status'] ?? '',
              'currency': p['currency'] ?? '\u20B9',
            };
          }).toList(),
        };
      }
    } catch (_) {}

    // Primary source: mobile backend local DB (always available).
    return await get('/payslips/list?year=$y');
  }

  /// Get single payslip detail — tries proxy, then direct web, then local.
  static Future<Map<String, dynamic>> getPayslip({
    int? month,
    int? year,
    int? id,
  }) async {
    // Try local mobile backend first (always available).
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    try {
      final localData = await get('/payslips?month=$m&year=$y');
      if (localData['error'] == null) return localData;
    } catch (_) {}

    // Then try web proxy if we have an ID.
    if (id != null) {
      try {
        return await getWebPayslipDetail(id);
      } catch (_) {}

      try {
        final token = await _getWebToken();
        final resp = await http.get(
          Uri.parse('$webBaseUrl/payroll/payslip/$id/'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (resp.statusCode == 200) {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {'error': 'No payslip found'};
  }

  /// Download payslip PDF — tries direct web first (for binary),
  /// then falls back to mobile backend proxy.
  static Future<http.Response> getPayslipPdf(int id) async {
    try {
      final token = await _getWebToken();
      final resp = await http.get(
        Uri.parse('$webBaseUrl/payroll/payslip-download/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200 && resp.bodyBytes.length > 500) {
        return resp;
      }
    } catch (_) {}
    // Fallback to mobile backend
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

  // Super-admin only.
  static Future<Map<String, dynamic>> getAdminCommandCenter() async {
    return await get('/admin/command-center');
  }

  static Future<Map<String, dynamic>> getAdminAuditLogs({
    int limit = 50,
    int offset = 0,
    String? action,
  }) async {
    final params = ['limit=$limit', 'offset=$offset'];
    if (action != null && action.isNotEmpty) params.add('action=$action');
    return await get('/admin/audit-logs?${params.join('&')}');
  }

  /// URL of the audit-log CSV export. Browser handles the download.
  static String adminAuditLogsExportUrl({String? action}) {
    final base = '$baseUrl/admin/audit-logs/export-csv';
    if (action == null || action.isEmpty) return base;
    return '$base?action=${Uri.encodeQueryComponent(action)}';
  }

  // Admin — user management.
  static Future<Map<String, dynamic>> getAdminUsers({
    String? search,
    String? role,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String>['limit=$limit', 'offset=$offset'];
    if (search != null && search.isNotEmpty)
      params.add('search=${Uri.encodeQueryComponent(search)}');
    if (role != null && role.isNotEmpty) params.add('role=$role');
    return await get('/admin/users?${params.join('&')}');
  }

  /// Action POST helper for admin user actions like enable/disable/promote.
  /// `action` values: enable, disable, force-logout, reset-password, promote.
  static Future<Map<String, dynamic>> adminUserAction(
    int userId,
    String action, {
    Map<String, dynamic>? body,
  }) async {
    return await post('/admin/users/$userId/$action', body ?? {});
  }

  // ── Tier 2 admin endpoints ──────────────────────────────────────
  static Future<Map<String, dynamic>> getAdminGeofences() async =>
      await get('/admin/geofences');

  static Future<Map<String, dynamic>> createAdminGeofence(
    Map<String, dynamic> body,
  ) async => await post('/admin/geofences', body);

  static Future<Map<String, dynamic>> updateAdminGeofence(
    int id,
    Map<String, dynamic> body,
  ) async => await put('/admin/geofences/$id', body);

  static Future<void> deleteAdminGeofence(int id) async =>
      await delete('/admin/geofences/$id');

  static Future<Map<String, dynamic>> getAdminHolidays() async =>
      await get('/admin/holidays');

  static Future<Map<String, dynamic>> createAdminHoliday(
    Map<String, dynamic> body,
  ) async => await post('/admin/holidays', body);

  static Future<Map<String, dynamic>> updateAdminHoliday(
    int id,
    Map<String, dynamic> body,
  ) async => await put('/admin/holidays/$id', body);

  static Future<void> deleteAdminHoliday(int id) async =>
      await delete('/admin/holidays/$id');

  static Future<Map<String, dynamic>> getAdminEmailTemplates() async =>
      await get('/admin/email-templates');

  static Future<Map<String, dynamic>> saveAdminEmailTemplate(
    Map<String, dynamic> body,
  ) async => await post('/admin/email-templates', body);

  static Future<Map<String, dynamic>> listAdminBackups() async =>
      await get('/admin/backup');

  static Future<Map<String, dynamic>> triggerAdminBackup() async =>
      await post('/admin/backup', {});

  /// Returns the absolute URL of the admin CSV export endpoint so the
  /// platform browser can download it (multipart binary, not JSON).
  static String adminEmployeesExportUrl() =>
      '$baseUrl/admin/employees/export-csv';

  // ── Round 3 — Tier 3/4 admin endpoints ──────────────────────────
  static Future<Map<String, dynamic>> getAdminSystemStats() async =>
      await get('/admin/system-stats');

  static Future<Map<String, dynamic>> getAdminLiveActivity() async =>
      await get('/admin/live-activity');

  static Future<Map<String, dynamic>> sendAdminPushCampaign({
    required String title,
    required String body,
    String audience = 'all',
  }) async {
    return await post('/admin/push-campaign', {
      'title': title,
      'body': body,
      'audience': audience,
    });
  }

  static Future<Map<String, dynamic>> getAdminFaceEnrollments() async =>
      await get('/admin/face-enrollments');

  static Future<Map<String, dynamic>> deleteAdminFaceEnrollment(
    int employeeId,
  ) async =>
      await delete('/admin/face-enrollments?employee_id=$employeeId')
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> enrollFace({
    required int employeeId,
    required String imageBase64,
  }) async => await post('/admin/face-enrollments', {
    'employee_id': employeeId,
    'image': imageBase64,
  });

  static Future<Map<String, dynamic>> getAdminWebhooks() async =>
      await get('/admin/webhooks');

  static Future<Map<String, dynamic>> createAdminWebhook(
    Map<String, dynamic> body,
  ) async => await post('/admin/webhooks', body);

  static Future<Map<String, dynamic>> updateAdminWebhook(
    int id,
    Map<String, dynamic> body,
  ) async => await put('/admin/webhooks/$id', body);

  static Future<void> deleteAdminWebhook(int id) async =>
      await delete('/admin/webhooks/$id');

  static Future<Map<String, dynamic>> adminGdprExport(int userId) async =>
      await get('/admin/users/$userId/gdpr-export');

  static Future<Map<String, dynamic>> adminGdprDelete(int userId) async =>
      await post('/admin/users/$userId/gdpr-delete', {});

  static Future<Map<String, dynamic>> getAdminRetentionPolicies() async =>
      await get('/admin/retention-policies');

  static Future<Map<String, dynamic>> saveAdminRetentionPolicy(
    String modelName,
    int maxDays, {
    bool isActive = true,
  }) async {
    return await post('/admin/retention-policies', {
      'model_name': modelName,
      'max_days': maxDays,
      'is_active': isActive,
    });
  }

  static Future<Map<String, dynamic>> getAdminConsentLedger({
    int? userId,
  }) async => await get(
    '/admin/consent-ledger${userId != null ? "?user_id=$userId" : ""}',
  );

  // ── Round 4 — login telemetry + IP allowlist ────────────────────
  static Future<Map<String, dynamic>> getAdminAllowedIps() async =>
      await get('/admin/allowed-ips');

  static Future<Map<String, dynamic>> createAdminAllowedIp(
    Map<String, dynamic> body,
  ) async => await post('/admin/allowed-ips', body);

  static Future<Map<String, dynamic>> updateAdminAllowedIp(
    int id,
    Map<String, dynamic> body,
  ) async => await put('/admin/allowed-ips/$id', body);

  static Future<void> deleteAdminAllowedIp(int id) async =>
      await delete('/admin/allowed-ips/$id');

  static Future<Map<String, dynamic>> getAdminLoginRecords({
    int limit = 100,
    int offset = 0,
  }) async => await get('/admin/login-records?limit=$limit&offset=$offset');

  /// Async typeahead for the request CC field. Matches name / email / badge id
  /// and returns each hit's auth `user_id` so the client can submit it
  /// directly inside the request payload's `cc` array.
  static Future<List<Map<String, dynamic>>> searchEmployees(
    String query, {
    int limit = 12,
  }) async {
    if (query.trim().length < 2) return const [];
    final r = await get(
      '/employees/search?q=${Uri.encodeQueryComponent(query)}&limit=$limit',
    );
    return List<Map<String, dynamic>>.from(r['items'] ?? const []);
  }

  // ── App Feedback ──────────────────────────────────────────────
  static Future<bool> hasFeedback(String version) async {
    final r = await get('/feedback/check?version=$version');
    return r['has_feedback'] == true;
  }

  static Future<void> submitFeedback({
    required int rating,
    String comment = '',
    String version = '1.0.0',
  }) async {
    await post('/feedback/submit', {
      'rating': rating,
      'comment': comment,
      'version': version,
    });
  }

  // ── Round 5 — Activity status / presence ─────────────────────
  static Future<void> heartbeat() async {
    try {
      await post('/me/heartbeat', {});
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getPresenceSettings() async =>
      await get('/me/presence-settings');

  static Future<Map<String, dynamic>> updatePresenceSettings(
    Map<String, dynamic> body,
  ) async => await post('/me/presence-settings', body);

  static Future<List<Map<String, dynamic>>> getPresenceFor(
    List<int> userIds,
  ) async {
    if (userIds.isEmpty) return const [];
    final r = await get('/presence?user_ids=${userIds.join(",")}');
    return List<Map<String, dynamic>>.from(r['items'] ?? const []);
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

  static Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> data,
  ) async {
    return await post('/settings', data);
  }

  // ── Biometric Device Management ─────────────────────────────
  static Future<Map<String, dynamic>> getAdminBiometricDevices() async =>
      await get('/admin/biometric-devices');

  static Future<Map<String, dynamic>> createAdminBiometricDevice(
    Map<String, dynamic> body,
  ) async => await post('/admin/biometric-devices', body);

  static Future<Map<String, dynamic>> updateAdminBiometricDevice(
    String id,
    Map<String, dynamic> body,
  ) async => await patch('/admin/biometric-devices/$id', body);

  static Future<Map<String, dynamic>> deleteAdminBiometricDevice(
    String id,
  ) async => await delete('/admin/biometric-devices/$id');
}
