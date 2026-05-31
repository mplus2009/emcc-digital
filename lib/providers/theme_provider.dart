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
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
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
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF1E1E1E),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2A5298),
      secondary: Color(0xFF10B981),
    ),
  );
}
