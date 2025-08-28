import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Auth/login.dart';
import 'pages/main_layout.dart';
import 'theme.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('[Firebase Init] Starting Firebase initialization...');

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    print('[Firebase Init] Firebase initialized successfully');

    // Initialize Firebase Service
    FirebaseService.initialize();
    print('[Firebase Init] Firebase Service initialized');

    if (FirebaseAuth.instance.currentUser != null) {
      print(
          '[Firebase Init] User already logged in: ${FirebaseAuth.instance.currentUser?.email}');
    }

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
      title: 'RIF 2025',
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const MainLayout(userRole: 'user'),
      },
    );
  }
}
