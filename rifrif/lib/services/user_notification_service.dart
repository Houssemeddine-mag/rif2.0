import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserNotificationService {
  static const String _dismissedNotificationsKey = 'dismissed_notifications';
  static const String _readNotificationsKey = 'read_notifications';

  // Get list of notification IDs that user has dismissed locally
  static Future<List<String>> getDismissedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedJson = prefs.getString(_dismissedNotificationsKey);
      if (dismissedJson != null) {
        final List<dynamic> dismissedList = json.decode(dismissedJson);
        return dismissedList.cast<String>();
      }
      return [];
    } catch (e) {
      print('Error getting dismissed notifications: $e');
      return [];
    }
  }

  // Mark notification as dismissed locally (hidden from user's view)
  static Future<void> dismissNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = await getDismissedNotifications();

      if (!dismissed.contains(notificationId)) {
        dismissed.add(notificationId);
        await prefs.setString(
            _dismissedNotificationsKey, json.encode(dismissed));
        print('Notification $notificationId dismissed locally');
      }
    } catch (e) {
      print('Error dismissing notification: $e');
    }
  }

  // Clear all dismissed notifications (useful for admin actions)
  static Future<void> clearAllDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dismissedNotificationsKey);
      print('All dismissed notifications cleared');
    } catch (e) {
      print('Error clearing dismissed notifications: $e');
    }
  }

  // Get list of notification IDs that user has read locally
  static Future<List<String>> getReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readJson = prefs.getString(_readNotificationsKey);
      if (readJson != null) {
        final List<dynamic> readList = json.decode(readJson);
        return readList.cast<String>();
      }
      return [];
    } catch (e) {
      print('Error getting read notifications: $e');
      return [];
    }
  }

  // Mark notification as read locally
  static Future<void> markAsReadLocally(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = await getReadNotifications();

      if (!read.contains(notificationId)) {
        read.add(notificationId);
        await prefs.setString(_readNotificationsKey, json.encode(read));
        print('Notification $notificationId marked as read locally');
      }
    } catch (e) {
      print('Error marking notification as read locally: $e');
    }
  }

  // Clear all local read status (useful for admin actions)
  static Future<void> clearAllReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_readNotificationsKey);
      print('All local read status cleared');
    } catch (e) {
      print('Error clearing read status: $e');
    }
  }

  // Check if notification is dismissed locally
  static Future<bool> isNotificationDismissed(String notificationId) async {
    final dismissed = await getDismissedNotifications();
    return dismissed.contains(notificationId);
  }

  // Check if notification is read locally
  static Future<bool> isNotificationReadLocally(String notificationId) async {
    final read = await getReadNotifications();
    return read.contains(notificationId);
  }

  // Filter notifications to exclude dismissed ones
  static Future<List<Map<String, dynamic>>> filterVisibleNotifications(
      List<Map<String, dynamic>> notifications) async {
    final dismissed = await getDismissedNotifications();
    return notifications.where((notification) {
      final id = notification['id'] as String?;
      return id != null && !dismissed.contains(id);
    }).toList();
  }

  // Get unread count excluding dismissed notifications
  static Future<int> getVisibleUnreadCount(
      List<Map<String, dynamic>> notifications) async {
    final dismissed = await getDismissedNotifications();
    final read = await getReadNotifications();

    return notifications.where((notification) {
      final id = notification['id'] as String?;
      final isRead = notification['isRead'] as bool? ?? false;

      if (id == null || dismissed.contains(id)) return false;

      // Check both database read status and local read status
      return !isRead && !read.contains(id);
    }).length;
  }
}
