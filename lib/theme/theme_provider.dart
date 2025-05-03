import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_styles.dart';


class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  final String _themePreferenceKey = 'theme_preference';


  ThemeProvider() {
    _loadThemePreference();
  }


  bool get isDarkMode => _isDarkMode;
 
  ThemeData get currentTheme => _isDarkMode ? AppTheme.dark() : AppTheme.light();


  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkMode);
  }


  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }
}
