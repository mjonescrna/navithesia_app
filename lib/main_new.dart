import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:navithesia_beta/providers/auth_provider.dart';
import 'package:navithesia_beta/providers/case_provider.dart';
import 'package:navithesia_beta/providers/category_provider.dart';
import 'package:navithesia_beta/providers/clinical_site_provider.dart';
import 'package:navithesia_beta/providers/time_entry_provider.dart';
import 'package:navithesia_beta/providers/user_goals_provider.dart';
import 'package:navithesia_beta/providers/theme_provider.dart';

/// Main entry point for the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Set up our app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (context) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (context) => CaseProvider(prefs)),
        ChangeNotifierProvider(create: (context) => TimeEntryProvider(prefs)),
        ChangeNotifierProvider(create: (context) => ClinicalSiteProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider(prefs)),
        ChangeNotifierProvider(create: (context) => UserGoalsProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

/// The main application widget
class MyApp extends StatelessWidget {
  /// Creates a new instance of [MyApp]
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode from ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Navithesia',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(context),
      darkTheme: _buildDarkTheme(context),
      home: _determineInitialScreen(context, authProvider),
    );
  }

  /// Determines which screen to show when the app first loads
  Widget _determineInitialScreen(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    // If the user is logged in, show the home screen, otherwise show the login screen
    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }

  /// Build the light theme for the app
  ThemeData _buildLightTheme(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      useMaterial3: true,
    );
  }

  /// Build the dark theme for the app
  ThemeData _buildDarkTheme(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }
}

// Placeholder for screens until they are properly imported
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Screen')),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Screen')),
    );
  }
}
