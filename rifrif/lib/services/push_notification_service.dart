import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize push notifications
  static Future<void> initialize() async {
    print('[Push Notifications] Initializing...');

    // Initialize local notifications first
    await _initializeLocalNotifications();
    print('[Push Notifications] Local notifications initialized');

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

    print(
        '[Push Notifications] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
      return; // Don't continue if permission denied
    }

    // Configure Firebase Messaging for background handling
    await _configureFirebaseMessaging();

    // Request battery optimization exemption for better background delivery
    await _requestBatteryOptimizationExemption();

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages - ALWAYS show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          '[FCM] Foreground message received: ${message.notification?.title}');
      await _handleForegroundMessage(message);
    });

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

    // Subscribe to the main broadcast topics for all users
    await subscribeToTopic('all_users');
    await subscribeToTopic('rif_2025_broadcast');
    await subscribeToTopic('general'); // General notifications

    print('[Push Notifications] Subscribed to broadcast topics');

    // Listen for Firestore-based notifications (for cross-device delivery)
    _listenForFirestoreNotifications();

    print('[Push Notifications] Initialization complete');
  }

  // Initialize for sending only (no message listeners to avoid conflicts)
  static Future<void> initializeForSendingOnly() async {
    print('[Push Notifications] Initializing for sending only...');

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

    print(
        '[Push Notifications] Permission status: ${settings.authorizationStatus}');

    // Get FCM token for sending
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _saveTokenToFirestore(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);

    print('[Push Notifications] Send-only initialization complete');
  }

  // Handle background messages (called from main.dart background handler)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print(
        '[FCM Background] Processing background message: ${message.notification?.title}');

    try {
      // Initialize local notifications for background processing
      await _initializeLocalNotifications();

      // Show the notification with default settings
      await _showLocalNotification(
        message: message,
        soundEnabled: true,
        vibrationEnabled: true,
      );

      print('[FCM Background] Background message processed successfully');
    } catch (e) {
      print('[FCM Background] Error processing background message: $e');
    }
  }

  // Configure Firebase Messaging for optimal background performance
  static Future<void> _configureFirebaseMessaging() async {
    print('[FCM Config] Configuring Firebase Messaging for background...');

    // Enable auto initialization
    await _firebaseMessaging.setAutoInitEnabled(true);

    // Set delivery metrics export to BigQuery
    await _firebaseMessaging.setDeliveryMetricsExportToBigQuery(true);

    print('[FCM Config] Firebase Messaging configured for background delivery');
  }

  // Request battery optimization exemption for reliable background notifications
  static Future<void> _requestBatteryOptimizationExemption() async {
    try {
      print('[Battery] Requesting battery optimization exemption...');

      // Store a flag to show user guidance about battery optimization
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_battery_optimization_tip', true);

      print('[Battery] Battery optimization guidance flag set');
    } catch (e) {
      print('[Battery] Error with battery optimization request: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/launcher_icon'); // Use custom app logo

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rif_2025_notifications', // Channel ID
      'RIF 2025 Notifications', // Channel name
      description:
          'Notifications for RIF 2025 conference', // Channel description
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on notification payload
    if (response.payload != null) {
      // Parse payload and navigate accordingly
      print('Payload: ${response.payload}');
    }
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

    // Check sound and vibration preferences
    final soundEnabled = prefs.getBool('sound_enabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    // Show system notification
    await _showLocalNotification(
      message: message,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
    );
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required RemoteMessage message,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    try {
      final title = message.notification?.title ?? 'RIF 2025';
      final body = message.notification?.body ?? 'New notification';
      final data = message.data;

      // Determine notification icon and priority based on type
      String iconName = '@mipmap/launcher_icon'; // Use custom app logo
      Priority priority = Priority.high;
      Importance importance = Importance.high;

      if (data.containsKey('type')) {
        switch (data['type']) {
          case 'urgent':
            priority = Priority.max;
            importance = Importance.max;
            break;
          case 'conference':
          case 'session':
            priority = Priority.high;
            importance = Importance.high;
            break;
          default:
            priority = Priority.defaultPriority;
            importance = Importance.defaultImportance;
        }
      }

      // Android notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rif_2025_notifications',
        'RIF 2025 Notifications',
        channelDescription: 'Notifications for RIF 2025 conference',
        importance: importance,
        priority: priority,
        enableVibration: vibrationEnabled,
        enableLights: true,
        playSound: soundEnabled,
        icon: iconName,
        color: const Color(0xFFAA6B94), // RIF 2025 theme color
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        autoCancel: true,
        ongoing: false,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'RIF 2025',
        ),
        actions: [
          AndroidNotificationAction(
            'view_action',
            'View',
            showsUserInterface: true,
          ),
        ],
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.active,
      );

      // Notification details
      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate unique notification ID
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Show the notification
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: message.data.toString(),
      );

      print('System notification shown successfully');
    } catch (e) {
      print('Error showing local notification: $e');
    }
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

  // Send push notification to all users (admin only) - WITH LOCAL FALLBACK
  static Future<void> sendPushNotificationToAll({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      print('[FCM] Sending notification to all users...');
      print('[FCM] Title: $title');
      print('[FCM] Body: $body');

      // Method 1: Create Cloud Function trigger (for when CF is deployed)
      await _firestore.collection('push_notifications').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'sent': false,
        'topic': 'all_users',
      });

      // Method 2: Local notification fallback (immediate for testing)
      print('[FCM] Showing local notification fallback...');
      await _showLocalNotificationDirect(
        title: title,
        body: body,
        data: data ?? {},
      );

      // Method 3: Firestore-based cross-device notification
      await _triggerFirestoreNotification(title, body, data);

      print('[FCM] Notification sent via multiple channels');
    } catch (e) {
      print('[FCM] Error sending notification to all users: $e');
      throw e;
    }
  }

  // Direct local notification (for immediate display)
  static Future<void> _showLocalNotificationDirect({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // Create a mock RemoteMessage for consistency
      await _showLocalNotification(
        message: _createMockRemoteMessage(title, body, data),
        soundEnabled: true,
        vibrationEnabled: true,
      );
      print('[FCM] Local notification displayed');
    } catch (e) {
      print('[FCM] Error showing local notification: $e');
    }
  }

  // Create mock RemoteMessage for local notifications
  static RemoteMessage _createMockRemoteMessage(
      String title, String body, Map<String, String> data) {
    return RemoteMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      notification: RemoteNotification(
        title: title,
        body: body,
      ),
      data: data,
      sentTime: DateTime.now(),
    );
  }

  // Trigger Firestore-based notification for cross-device
  static Future<void> _triggerFirestoreNotification(
      String title, String body, Map<String, String>? data) async {
    try {
      // Create notification document that other devices can listen to
      await _firestore.collection('live_notifications').add({
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
        'type': data?['type'] ?? 'general',
      });
      print('[FCM] Firestore notification created for cross-device delivery');
    } catch (e) {
      print('[FCM] Error creating Firestore notification: $e');
    }
  }

  // Listen for Firestore-based notifications
  static void _listenForFirestoreNotifications() {
    print('[Firestore] Setting up listener for live_notifications...');

    _firestore
        .collection('live_notifications')
        .where('processed', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data() as Map<String, dynamic>;

          // Check if this notification is recent (within last 5 minutes to avoid old notifications)
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final notificationTime = timestamp.toDate();
            final now = DateTime.now();
            final difference = now.difference(notificationTime).inMinutes;

            if (difference > 5) {
              print(
                  '[Firestore] Skipping old notification (${difference} minutes old)');
              continue;
            }
          }

          print('[Firestore] New notification received: ${data['title']}');

          // Show the notification
          await _showLocalNotificationDirect(
            title: data['title'] ?? 'RIF 2025',
            body: data['body'] ?? 'New notification',
            data: Map<String, String>.from(data['data'] ?? {}),
          );

          // Mark as processed to avoid showing again
          await docChange.doc.reference.update({'processed': true});

          print('[Firestore] Notification processed and marked as processed');
        }
      }
    }).onError((error) {
      print('[Firestore] Error listening for notifications: $error');
    });
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

  // Test method to verify local notifications work
  static Future<void> testLocalNotification() async {
    try {
      print('[Test] Showing test notification...');

      await _localNotifications.show(
        999,
        'RIF 2025 Test',
        'This is a test notification to verify system notifications work!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rif_2025_notifications',
            'RIF 2025 Notifications',
            channelDescription: 'Notifications for RIF 2025 conference',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            icon: '@mipmap/launcher_icon', // Use custom app logo
            color: const Color(0xFFAA6B94),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      print('[Test] Test notification sent');
    } catch (e) {
      print('[Test] Error showing test notification: $e');
    }
  }
}
