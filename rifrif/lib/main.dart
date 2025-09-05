import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Auth/login.dart';
import 'pages/main_layout.dart';
import 'pages_admin/main_layout.dart' as admin;
import 'theme.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/push_notification_service.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM] Background message received: ${message.notification?.title}');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background message here
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('[Firebase Init] Starting Firebase initialization...');

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print('[Firebase Init] Firebase initialized successfully');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize Firebase Service
    FirebaseService.initialize();
    print('[Firebase Init] Firebase Service initialized');

    // Initialize Push Notification Service
    await PushNotificationService.initialize();
    print('[Firebase Init] Push Notification Service initialized');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('[Firebase Init] Error initializing Firebase:');
    print(e);
    print('[Firebase Init] Stack trace:');
    print(stackTrace);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RIF',
      theme: AppTheme.theme,
      home: const AuthWrapper(), // Use AuthWrapper instead of direct routes
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainLayout(userRole: 'user'),
        '/admin': (context) => const admin.MainLayout(userRole: 'admin'),
      },
    );
  }
}

// Authentication Wrapper to handle persistent login
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDFDFD),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFAA6B94),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Vérification de l\'authentification...',
                    style: TextStyle(
                      color: Color(0xFFAA6B94),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          print('[Auth] User is already logged in: ${snapshot.data!.email}');
          // User is logged in, go to home
          return const MainLayout(userRole: 'user');
        } else {
          print('[Auth] No user logged in, showing login page');
          // User is not logged in, show login page
          return const LoginPage();
        }
      },
    );
  }
}
