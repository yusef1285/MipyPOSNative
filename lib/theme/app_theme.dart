import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepBlue = Color(0xFF1A2A4F);
  static const Color emeraldGreen = Color(0xFF00C896);
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData light() {
    final textTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: deepBlue,
        onPrimary: white,
        secondary: emeraldGreen,
        onSecondary: white,
        error: Colors.red,
        onError: white,
        surface: white,
        onSurface: Colors.black,
      ),
      primaryColor: deepBlue,
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlue,
        foregroundColor: white,
        elevation: 2,
      ),

      // ✔ Reemplazo de GoogleFonts por Poppins local
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins'),
        displayMedium: TextStyle(fontFamily: 'Poppins'),
        displaySmall: TextStyle(fontFamily: 'Poppins'),
        headlineLarge: TextStyle(fontFamily: 'Poppins'),
        headlineMedium: TextStyle(fontFamily: 'Poppins'),
        headlineSmall: TextStyle(fontFamily: 'Poppins'),
        titleLarge: TextStyle(fontFamily: 'Poppins'),
        titleMedium: TextStyle(fontFamily: 'Poppins'),
        titleSmall: TextStyle(fontFamily: 'Poppins'),
        bodyLarge: TextStyle(fontFamily: 'Poppins'),
        bodyMedium: TextStyle(fontFamily: 'Poppins'),
        bodySmall: TextStyle(fontFamily: 'Poppins'),
        labelLarge: TextStyle(fontFamily: 'Poppins'),
        labelMedium: TextStyle(fontFamily: 'Poppins'),
        labelSmall: TextStyle(fontFamily: 'Poppins'),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: white,
        ),
      ),
    );
  }
}
