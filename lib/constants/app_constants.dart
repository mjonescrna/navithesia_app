import 'package:flutter/material.dart';

class AppConstants {
  // App name
  static const String appName = 'NaviThesia';
  static const String appVersion = '1.0.0';
  static const String appLogo = 'assets/icons/app_icon.png';

  // API endpoints (for future implementation)
  static const String baseUrl =
      'https://api.navithesia.com'; // Not implemented yet

  // Local storage keys
  static const String userKey = 'user_data';
  static const String lastAuthUserKey = 'last_authenticated_user';
  static const String casesKey = 'clinical_cases';
  static const String settingsKey = 'app_settings';
  static const String selectedCategoriesKey = 'selected_dashboard_categories';

  // Default settings
  static const int defaultAnimationDuration = 300; // milliseconds
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const int maxDashboardCategories = 4;

  // SharedPreferences keys
  static const String categoriesKey = 'categories';
  static const String coaSchoolsKey = 'coa_schools';
  static const String clinicalSitesKey = 'clinical_sites';

  // API Keys
  // TODO: Move this to a secure storage solution before production
  static const String googleMapsApiKey =
      'AIzaSyAQY9ByEdXDmMiixPfZuwqZYpVgITsbi1Y';

  // API Endpoints
  static const String hospitalSearchRadius = '80000'; // 50 miles in meters
}

class AppColors {
  // Primary and accent colors
  static const Color primaryColor = Color(0xFF1565C0); // Deep blue
  static const Color accentColor = Color(0xFF42A5F5); // Lighter blue
  static const Color primaryColorDark = Color(
    0xFF0D47A1,
  ); // Darker blue for dark theme
  static const Color accentColorDark = Color(
    0xFF2196F3,
  ); // Adjusted accent for dark theme

  // Background colors
  static const Color backgroundColor = Color(
    0xFFF5F9FF,
  ); // Very light blue tint
  static const Color backgroundColorDark = Color(0xFF121212); // Dark background
  static const Color cardColor = Colors.white;
  static const Color cardColorDark = Color(0xFF1E1E1E); // Dark cards

  // Text colors
  static const Color textPrimary = Color(0xFF2B2B2B);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFAAAAAA);
  static const Color textPrimaryDark = Color(
    0xFFE1E1E1,
  ); // Light text for dark theme
  static const Color textSecondaryDark = Color(
    0xFFB0B0B0,
  ); // Medium light text for dark theme
  static const Color textLightDark = Color(
    0xFF8A8A8A,
  ); // Dimmed text for dark theme

  // Progress indicator colors
  static const Color progressRed = Color(0xFFE53935); // 0-25%
  static const Color progressOrange = Color(0xFFFF9800); // 26-50%
  static const Color progressYellow = Color(0xFFFFEB3B); // 51-90%
  static const Color progressGreen = Color(0xFF4CAF50); // 91-100%

  // Dark theme uses the same progress colors for consistency
  static const Color progressRedDark = progressRed;
  static const Color progressOrangeDark = progressOrange;
  static const Color progressYellowDark = progressYellow;
  static const Color progressGreenDark = progressGreen;

  // Other colors
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF0288D1); // Blue
  static const Color errorColorDark = Color(
    0xFFEF5350,
  ); // Lighter red for dark theme
  static const Color successColorDark = Color(
    0xFF29B6F6,
  ); // Lighter blue for dark theme
  static const Color warningColor = Color(0xFFF57C00);
  static const Color infoColor = Color(0xFF1976D2);

  // Get theme-based colors (used with ThemeProvider to get correct color for current theme)
  static Color getPrimaryColor(bool isDarkMode) =>
      isDarkMode ? primaryColorDark : primaryColor;
  static Color getAccentColor(bool isDarkMode) =>
      isDarkMode ? accentColorDark : accentColor;
  static Color getBackgroundColor(bool isDarkMode) =>
      isDarkMode ? backgroundColorDark : backgroundColor;
  static Color getCardColor(bool isDarkMode) =>
      isDarkMode ? cardColorDark : cardColor;
  static Color getTextPrimaryColor(bool isDarkMode) =>
      isDarkMode ? textPrimaryDark : textPrimary;
  static Color getTextSecondaryColor(bool isDarkMode) =>
      isDarkMode ? textSecondaryDark : textSecondary;
  static Color getTextLightColor(bool isDarkMode) =>
      isDarkMode ? textLightDark : textLight;
  static Color getErrorColor(bool isDarkMode) =>
      isDarkMode ? errorColorDark : errorColor;
  static Color getSuccessColor(bool isDarkMode) =>
      isDarkMode ? successColorDark : successColor;
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );
}

class AppAssets {
  // Image paths
  static const String logoPath = "assets/images/navithesia_logo.png";
  static const String backgroundPath = "assets/images/background.png";
  static const String placeholderImagePath = "assets/images/placeholder.png";

  // Icon paths
  static const String homeIconPath = "assets/icons/home.png";
  static const String logsIconPath = "assets/icons/logs.png";
  static const String addCaseIconPath = "assets/icons/add_case.png";
  static const String goalsIconPath = "assets/icons/goals.png";
  static const String messagesIconPath = "assets/icons/messages.png";
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String logs = '/logs';
  static const String addCase = '/add-case';
  static const String goals = '/goals';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String coaProgress = '/coa-progress';
  static const String admin = '/admin';
  static const String databaseEditor = '/admin/database-editor';
}

// Admin credentials - keep these private and consider more secure storage for production
class AdminCredentials {
  static const String username = "admin";
  static const String password = "naviAdmin2024!";
}
