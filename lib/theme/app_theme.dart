import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepBlue = Color(0xFF0F172A);
  static const Color blueSoft = Color(0xFF2563EB);
  static const Color emeraldGreen = Color(0xFF14B8A6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF111827);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceAlt = Color(0xFFE2E8F0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: blueSoft,
      brightness: Brightness.light,
      primary: blueSoft,
      secondary: emeraldGreen,
      surface: surface,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3F6FB),
      primaryColor: blueSoft,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFDBEAFE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w700);
          }
          return const TextStyle(fontWeight: FontWeight.w500);
        }),
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueSoft,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blueSoft, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: blueSoft,
      brightness: Brightness.dark,
      primary: blueSoft,
      secondary: emeraldGreen,
      surface: const Color(0xFF0F172A),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF111827),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF1F2937), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF111827),
        indicatorColor: const Color(0xFF1D4ED8),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w700);
          }
          return const TextStyle(fontWeight: FontWeight.w500);
        }),
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blueSoft,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blueSoft, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: white,
        displayColor: white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }
}
