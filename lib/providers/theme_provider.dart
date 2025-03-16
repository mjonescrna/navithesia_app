import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String themePreferenceKey = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeProvider(this._prefs)
    : _themeMode =
          ThemeMode.values[_prefs.getInt(themePreferenceKey) ??
              ThemeMode.light.index];

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Toggle between light and dark themes
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }

  // Set a specific theme mode
  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    _saveThemePreference();
    notifyListeners();
  }

  // Save the current theme preference to SharedPreferences
  void _saveThemePreference() {
    _prefs.setInt(themePreferenceKey, _themeMode.index);
  }
}
