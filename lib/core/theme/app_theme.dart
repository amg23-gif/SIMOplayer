import 'package:flutter/material.dart';

// ألوان التطبيق وثيماته المختلفة
class AppTheme {
  AppTheme._();

  // --- ألوان الثيم ---
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color accentColor = Color(0xFF00E5FF);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF242424);
  static const Color oledBg = Color(0xFF000000);
  static const Color lightBg = Color(0xFFF5F5F5);

  // --- الثيم الداكن (افتراضي) ---
  static ThemeData darkTheme({Color? seedColor}) {
    final seed = seedColor ?? primaryColor;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: seed,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Cairo',
      cardColor: darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Cairo'),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        displayMedium: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        displaySmall: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        headlineLarge: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        headlineMedium: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        headlineSmall: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        titleLarge: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        titleMedium: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        titleSmall: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        bodyLarge: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        bodyMedium: TextStyle(fontFamily: 'Cairo', color: Colors.white70),
        bodySmall: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        labelLarge: TextStyle(fontFamily: 'Cairo', color: Colors.white),
        labelMedium: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        labelSmall: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
      ),
    );
  }

  // --- الثيم الفاتح ---
  static ThemeData lightTheme({Color? seedColor}) {
    final seed = seedColor ?? primaryColor;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: seed,
      scaffoldBackgroundColor: lightBg,
      fontFamily: 'Cairo',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cairo'),
        displayMedium: TextStyle(fontFamily: 'Cairo'),
        bodyLarge: TextStyle(fontFamily: 'Cairo'),
        bodyMedium: TextStyle(fontFamily: 'Cairo'),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- ثيم OLED أسود ---
  static ThemeData oledTheme({Color? seedColor}) {
    return darkTheme(seedColor: seedColor).copyWith(
      scaffoldBackgroundColor: oledBg,
      cardColor: const Color(0xFF111111),
    );
  }
}

// أوضاع الثيم المتاحة
enum AppThemeMode {
  dark,   // داكن (افتراضي)
  light,  // فاتح
  oled,   // OLED أسود
  custom, // مخصص باللون
}
