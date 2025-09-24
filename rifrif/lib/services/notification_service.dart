import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'push_notification_service.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static final CollectionReference _notificationsCollection =
      _firestore.collection('notifications');

  // Send notification for a session
  static Future<void> sendSessionNotification({
    required String sessionId,
    required String sessionTitle,
    required String message,
    String? sessionDate,
    String? sessionTime,
  }) async {
    try {
      final notification = {
        'type': 'session',
        'sessionId': sessionId,
        'title': 'Session Notification',
        'message': message,
        'sessionTitle': sessionTitle,
        'sessionDate': sessionDate,
        'sessionTime': sessionTime,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'normal',
      };

      await _notificationsCollection.add(notification);

      // Send push notification to all users
      await PushNotificationService.sendPushNotificationToAll(
        title: 'Session Starting Soon',
        body: message,
        data: {
          'type': 'session',
          'sessionId': sessionId,
          'sessionTitle': sessionTitle,
          'sessionDate': sessionDate ?? '',
          'sessionTime': sessionTime ?? '',
        },
      );

      print('Session notification sent successfully');
    } catch (e) {
      print('Error sending session notification: $e');
      throw e;
    }
  }

  // Send notification for a specific conference
  static Future<void> sendConferenceNotification({
    required String conferenceId,
    required String conferenceTitle,
    required String presenter,
    required String message,
    String? sessionDate,
    String? sessionTime,
  }) async {
    try {
      final notification = {
        'type': 'conference',
        'conferenceId': conferenceId,
        'title': 'Conference Notification',
        'message': message,
        'conferenceTitle': conferenceTitle,
        'presenter': presenter,
        'sessionDate': sessionDate,
        'sessionTime': sessionTime,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'high',
      };

      await _notificationsCollection.add(notification);

      // Send push notification to all users
      await PushNotificationService.sendPushNotificationToAll(
        title: 'Conference Starting Now',
        body: message,
        data: {
          'type': 'conference',
          'conferenceId': conferenceId,
          'conferenceTitle': conferenceTitle,
          'presenter': presenter,
          'sessionDate': sessionDate ?? '',
          'sessionTime': sessionTime ?? '',
        },
      );

      print('Conference notification sent successfully');
    } catch (e) {
      print('Error sending conference notification: $e');
      throw e;
    }
  }

  // Send general notification
  static Future<void> sendGeneralNotification({
    required String title,
    required String message,
    String priority = 'normal',
  }) async {
    try {
      final notification = {
        'type': 'general',
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': priority,
      };

      await _notificationsCollection.add(notification);

      // Send push notification to all users
      await PushNotificationService.sendPushNotificationToAll(
        title: title,
        body: message,
        data: {
          'type': 'general',
          'priority': priority,
        },
      );

      print('General notification sent successfully');
    } catch (e) {
      print('Error sending general notification: $e');
      throw e;
    }
  }

  // Get notifications stream for real-time updates
  static Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _notificationsCollection
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      throw e;
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _notificationsCollection
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      throw e;
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      throw e;
    }
  }

  // Delete all notifications (batch operation)
  static Future<void> deleteAllNotifications() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _notificationsCollection.get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All notifications deleted successfully');
    } catch (e) {
      print('Error deleting all notifications: $e');
      throw e;
    }
  }

  // Get unread notifications count
  static Stream<int> getUnreadCountStream() {
    return _notificationsCollection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Show notification dialog for admin
  static Future<void> showNotificationDialog({
    required BuildContext context,
    required String title,
    required String initialMessage,
    required Function(String message) onSend,
  }) async {
    final messageController = TextEditingController(text: initialMessage);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Notification Message',
                border: OutlineInputBorder(),
                hintText: 'Enter your notification message...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                onSend(messageController.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF614f96),
              foregroundColor: Colors.white,
            ),
            child: Text('Send Notification'),
          ),
        ],
      ),
    );
  }
}
