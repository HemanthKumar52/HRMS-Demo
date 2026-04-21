import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationController {
  NotificationController._();
  static final NotificationController instance = NotificationController._();

  Set<int> _seenNotifIds = {};
  int _lastKnownUnread = -1;

  /// Poll for new notifications and fire local push for new ones
  Future<void> poll(AppProvider provider) async {
    try {
      final data = await ApiService.getNotifications();
      final unread = (data['unread_count'] ?? 0) as int;
      final notifications = List<Map<String, dynamic>>.from(
        ((data['notifications'] as List?) ?? []).map(
          (n) => Map<String, dynamic>.from(n),
        ),
      );

      // Fire local push for new unread notifications
      if (_lastKnownUnread >= 0) {
        for (final n in notifications) {
          final id = n['id'];
          final isRead = n['read'] == true;
          if (!isRead && id != null && !_seenNotifIds.contains(id)) {
            NotificationService.instance.show(
              title: n['title'] as String? ?? 'New Notification',
              body: n['body'] as String? ?? '',
              payload: 'notification',
            );
          }
        }
      }

      _seenNotifIds = notifications.map((n) => n['id'] as int? ?? 0).toSet();
      _lastKnownUnread = unread;

      provider.updateNotifications(notifications, unread);
    } catch (e) {
      debugPrint('NotificationController: Poll error - $e');
    }
  }

  /// Mark a single notification as read
  Future<void> markRead(AppProvider provider, int id) async {
    await provider.markNotificationRead(id);
  }

  /// Mark all notifications as read
  Future<void> markAllRead(AppProvider provider) async {
    await provider.markAllNotificationsRead();
  }
}
