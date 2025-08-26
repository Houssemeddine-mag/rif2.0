import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
    primaryColor: Color(0xFFAA6B94),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: Color(0xFFC87BAA),
      primary: Color(0xFFAA6B94),
    ),
    fontFamily: 'Roboto',
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFC87AAA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: Color(0xFFAA6B94)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
