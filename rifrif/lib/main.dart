import 'package:flutter/material.dart';
import 'Auth/login.dart';
import 'pages/main_layout.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
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
