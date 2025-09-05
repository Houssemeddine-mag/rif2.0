import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize push notifications
  static Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Subscribe to topics based on user preferences
    await _subscribeBasedOnPreferences();
  }

  // Subscribe to topics based on user preferences
  static Future<void> _subscribeBasedOnPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      if (!notificationsEnabled) {
        // Unsubscribe from all topics if notifications are disabled
        await unsubscribeFromTopic('general');
        await unsubscribeFromTopic('sessions');
        await unsubscribeFromTopic('conferences');
        return;
      }

      // Subscribe to general topic by default
      await subscribeToTopic('general');

      // Subscribe to session notifications if enabled
      final sessionNotifications =
          prefs.getBool('session_notifications') ?? true;
      if (sessionNotifications) {
        await subscribeToTopic('sessions');
      } else {
        await unsubscribeFromTopic('sessions');
      }

      // Subscribe to conference notifications if enabled
      final conferenceNotifications =
          prefs.getBool('conference_notifications') ?? true;
      if (conferenceNotifications) {
        await subscribeToTopic('conferences');
      } else {
        await unsubscribeFromTopic('conferences');
      }
    } catch (e) {
      print('Error subscribing based on preferences: $e');
    }
  }

  // Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM token saved to Firestore');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Check if notifications are enabled before processing
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    if (!notificationsEnabled) {
      print('Notifications disabled by user, ignoring message');
      return;
    }

    // Check specific notification type preferences
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'session':
          final sessionNotifications =
              prefs.getBool('session_notifications') ?? true;
          if (!sessionNotifications) {
            print('Session notifications disabled, ignoring message');
            return;
          }
          break;
        case 'conference':
          final conferenceNotifications =
              prefs.getBool('conference_notifications') ?? true;
          if (!conferenceNotifications) {
            print('Conference notifications disabled, ignoring message');
            return;
          }
          break;
        case 'general':
          final generalNotifications =
              prefs.getBool('general_notifications') ?? true;
          if (!generalNotifications) {
            print('General notifications disabled, ignoring message');
            return;
          }
          break;
      }
    }

    // You can show a custom notification UI here if needed
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');

    // Handle navigation based on notification data
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'session':
          // Navigate to session details
          print('Navigate to session: ${data['sessionId']}');
          break;
        case 'conference':
          // Navigate to conference details
          print('Navigate to conference: ${data['conferenceId']}');
          break;
        default:
          print('Unknown notification type');
      }
    }
  }

  // Send push notification to all users (admin only)
  static Future<void> sendPushNotificationToAll({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // This method stores the notification request in Firestore
      // In a real app, you would use a backend service to actually send FCM messages
      await _firestore.collection('notification_requests').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'broadcast',
      });

      print('Notification request stored in Firestore');
    } catch (e) {
      print('Error storing notification request: $e');
      throw e;
    }
  }

  // Get FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Update subscription preferences
  static Future<void> updateSubscriptionPreferences() async {
    await _subscribeBasedOnPreferences();
  }
}

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // Note: Background messages will still be delivered by FCM even if user disabled notifications
  // The filtering should be done in the app when processing the message
}
