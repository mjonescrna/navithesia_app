import 'package:flutter/material.dart';

/// App-wide colors for consistent theming
class AppColors {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color primaryColorLight = Color(0xFF64B5F6);
  static const Color primaryColorDark = Color(0xFF1976D2);

  // Accent colors
  static const Color accentColor = Color(0xFFFFA726); // Orange
  static const Color accentColorLight = Color(0xFFFFCC80);
  static const Color accentColorDark = Color(0xFFFF8F00);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF5F5F5);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Divider and border colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color darkDivider = Color(0xFF424242);
  static const Color darkBorder = Color(0xFF424242);

  // Helper methods for theme-aware colors
  static Color getTextPrimary(bool isDarkMode) {
    return isDarkMode ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(bool isDarkMode) {
    return isDarkMode ? darkTextSecondary : textSecondary;
  }

  static Color getBackground(bool isDarkMode) {
    return isDarkMode ? darkBackground : background;
  }

  static Color getCardBackground(bool isDarkMode) {
    return isDarkMode ? darkCardBackground : cardBackground;
  }
}
