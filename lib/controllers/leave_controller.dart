import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaveController {
  LeaveController._();
  static final LeaveController instance = LeaveController._();

  /// Fetch leave balances
  Future<Map<String, dynamic>> fetchBalances() async {
    try {
      return await ApiService.getLeaveBalance();
    } catch (e) {
      debugPrint('LeaveController: Error fetching balances - $e');
      return {};
    }
  }

  /// Submit a leave request
  Future<Map<String, dynamic>> applyLeave(Map<String, dynamic> data) async {
    return await ApiService.applyLeave(data);
  }

  /// Fetch leave requests list
  Future<List<dynamic>> fetchLeaveRequests() async {
    try {
      return await ApiService.getLeaveRequests();
    } catch (e) {
      debugPrint('LeaveController: Error fetching requests - $e');
      return [];
    }
  }
}
