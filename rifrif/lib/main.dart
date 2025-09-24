import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Auth/login.dart';
import 'pages/main_layout.dart';
import 'pages/profile.dart';
import 'pages_admin/main_layout.dart' as admin;
import 'pages_presenter/presentation.dart';
import 'theme.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/push_notification_service.dart';

// Background message handler for push notifications
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(
      '[FCM Background] Background message received: ${message.notification?.title}');
  print('[FCM Background] Message body: ${message.notification?.body}');
  print('[FCM Background] Message data: ${message.data}');

  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[FCM Background] Firebase initialized for background handler');

  // Use standard push notification service for background messages
  await PushNotificationService.handleBackgroundMessage(message);
  print('[FCM Background] Background message processed successfully');
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

    // Initialize Push Notification Service for sending and receiving
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
        '/profile': (context) => const ProfileSetupWrapper(),
        '/admin': (context) => const admin.MainLayout(userRole: 'admin'),
        '/presenter': (context) => const ProtectedPresenterRoute(),
      },
    );
  }
}

// Authentication Wrapper to handle persistent login and first-time profile setup
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
                    color: Color(0xFF614f96),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Vérification de l\'authentification...',
                    style: TextStyle(
                      color: Color(0xFF614f96),
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
          // User is logged in, check if profile setup is needed
          return UserRouteDecider(user: snapshot.data!);
        } else {
          print('[Auth] No user logged in, showing login page');
          // User is not logged in, show login page
          return const LoginPage();
        }
      },
    );
  }
}

// Decides whether to show home or profile page based on user's profile completion status
class UserRouteDecider extends StatelessWidget {
  final User user;

  const UserRouteDecider({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: FirebaseService.shouldRedirectToProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDFDFD),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF614f96),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Chargement de votre profil...',
                    style: TextStyle(
                      color: Color(0xFF614f96),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('[Auth] Error checking profile status: ${snapshot.error}');
          // On error, default to home page
          return const MainLayout(userRole: 'user');
        }

        final shouldShowProfile = snapshot.data ?? false;

        if (shouldShowProfile) {
          print(
              '[Auth] Redirecting to profile page for first-time/incomplete user');
          return const ProfileSetupWrapper();
        } else {
          print('[Auth] Redirecting to home page for existing user');
          return const MainLayout(userRole: 'user');
        }
      },
    );
  }
}

// Wrapper for profile setup that ensures user goes to home after completion
class ProfileSetupWrapper extends StatelessWidget {
  const ProfileSetupWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
        title: Text(
          'Complétez votre profil',
          style: TextStyle(
            color: Color(0xFF614f96),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Skip button for users who want to complete profile later
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainLayout(userRole: 'user'),
                ),
              );
            },
            child: Text(
              'Passer',
              style: TextStyle(
                color: Color(0xFF614f96),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ProfilePage(
        onProfileCompleted: () {
          // Navigate to home page after profile completion
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainLayout(userRole: 'user'),
            ),
          );
        },
      ), // Use the existing ProfilePage with completion callback
    );
  }
}

// Protected route for presenter page - only accessible via proper authentication
class ProtectedPresenterRoute extends StatelessWidget {
  const ProtectedPresenterRoute({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if this was navigated from proper authentication
    // If user tries to access directly via URL or other means, redirect to login
    return FutureBuilder<bool>(
      future: _checkPresenterAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDFDFD),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF614f96),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          // Access granted - show presenter page
          return const PresentationPage();
        } else {
          // Access denied - redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            backgroundColor: Color(0xFFFDFDFD),
            body: Center(
              child: Text(
                'Access Denied\nRedirecting to login...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF614f96),
                  fontSize: 16,
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Future<bool> _checkPresenterAccess() async {
    // For now, we'll implement a simple check
    // In a real app, you might want to check a secure token or session
    // Since presenter authentication is static, we'll verify if user came through proper login

    // This is a basic implementation - you could enhance it with:
    // - Secure tokens
    // - Session management
    // - Time-based access tokens

    // For this implementation, we'll deny direct access to the route
    // The only proper way to access is through the login page
    return false; // This will force users to go through login
  }
}
