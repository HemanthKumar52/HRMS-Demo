import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardController {
  DashboardController._();
  static final DashboardController instance = DashboardController._();

  /// Fetch the full dashboard summary (attendance, leave, activity)
  Future<Map<String, dynamic>> fetchSummary() async {
    try {
      return await ApiService.getDashboardSummary();
    } catch (e) {
      debugPrint('DashboardController: Error fetching summary - $e');
      return {};
    }
  }

  /// Fetch announcements from DB (created by admin/HR)
  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    try {
      final data = await ApiService.getDashboardAnnouncements();
      return List<Map<String, dynamic>>.from(data['announcements'] ?? []);
    } catch (e) {
      debugPrint('DashboardController: Error fetching announcements - $e');
      return [];
    }
  }

  /// Fetch analytics data (for manager/HR)
  Future<Map<String, dynamic>> fetchAnalytics() async {
    try {
      return await ApiService.getDashboardAnalytics();
    } catch (e) {
      debugPrint('DashboardController: Error fetching analytics - $e');
      return {};
    }
  }

  /// Fetch user profile
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      return await ApiService.getCurrentUser();
    } catch (e) {
      debugPrint('DashboardController: Error fetching profile - $e');
      return {};
    }
  }
}
