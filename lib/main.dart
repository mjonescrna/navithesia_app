import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Providers
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/case_provider.dart';
import 'providers/time_entry_provider.dart';
import 'providers/clinical_site_provider.dart';
import 'providers/category_provider.dart';
import 'providers/user_goals_provider.dart';

// Screens - using correct paths
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/logs/logs_screen.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/add_case/add_case_screen.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with more detailed logging
  try {
    debugPrint('Attempting to initialize Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(
      'Firebase initialized successfully with options: ${DefaultFirebaseOptions.currentPlatform}',
    );
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CaseProvider(prefs)),
        ChangeNotifierProvider(create: (_) => TimeEntryProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ClinicalSiteProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UserGoalsProvider(prefs)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Navithesia',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.logs: (context) => const LogsScreen(),
        AppRoutes.goals: (context) => const GoalsScreen(),
        AppRoutes.messages: (context) => const MessagesScreen(),
        AppRoutes.addCase: (context) => const AddCaseScreen(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    final primaryColor = Color(0xFF2196F3); // Changed from teal to blue

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        onPrimary: Colors.white,
        background: Colors.white,
        surface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final primaryColor = Color(0xFF2196F3); // Changed from teal to blue

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.grey[300]),
        labelLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.grey[200]),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      scaffoldBackgroundColor: Color(0xFF121212),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

/// Splash screen shown when the app starts
class SplashScreen extends StatefulWidget {
  /// Creates a new instance of [SplashScreen]
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Simulate splash screen delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;

    // Check if the widget is still mounted before using context
    if (!mounted) return;

    if (isAuthenticated) {
      // Navigate to home screen if user is logged in
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Navigate to login screen if user is not logged in
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/navisthesia_logo_transparent.png',
              height: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              "Navigating Your Nurse Anesthesia Residency",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
