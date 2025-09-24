import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: Color(0xFF614f96),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF7862ab),
          primary: Color(0xFF614f96),
        ),
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF7862ab),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFF614f96)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
