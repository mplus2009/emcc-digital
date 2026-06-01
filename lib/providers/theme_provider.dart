// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1E3C72),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E3C72),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1E3C72),
      secondary: Color(0xFF10B981),
      surface: Colors.white,
      background: Color(0xFFF5F7FA),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF0F2B4D),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F2B4D),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Color(0xFF1E1E1E),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A5298),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2A5298),
      secondary: Color(0xFF10B981),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
    ),
  );
}
