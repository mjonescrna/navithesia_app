import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:navithesia_beta/constants/app_constants.dart';
import 'package:navithesia_beta/providers/auth_provider.dart';
import 'package:navithesia_beta/screens/auth/register_screen.dart';
import 'package:navithesia_beta/screens/auth/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isBiometricSupported = false;
  String _biometricType = 'Biometrics';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      _isBiometricSupported = await _localAuth.isDeviceSupported();

      // Determine biometric type for better UI
      if (_canCheckBiometrics && _isBiometricSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();

        if (Platform.isIOS) {
          if (availableBiometrics.contains(BiometricType.face)) {
            _biometricType = 'Face ID';
          } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
            _biometricType = 'Touch ID';
          }
        } else if (Platform.isAndroid) {
          if (availableBiometrics.contains(BiometricType.face)) {
            _biometricType = 'Face Unlock';
          } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
            _biometricType = 'Fingerprint';
          }
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        // Instead of using demo credentials, use the last logged in user
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.loginWithLastUser(true);

        if (success) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not find previous login information. Please log in with your credentials.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');

      // Show a helpful message to the user when biometric auth fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric authentication is currently unavailable. Please log in with your credentials.',
          ),
        ),
      );
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Save credentials if "Remember Me" is checked
      if (_rememberMe) {
        // Save email and password securely
        // In a real app, you would use a secure storage solution
        // For now, we'll use SharedPreferences for demonstration
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('remembered_email', email);

        // Note: Storing passwords in SharedPreferences is not secure
        // In a production app, use encrypted storage or a keychain
        await prefs.setString('remembered_password', password);

        debugPrint('Credentials saved for future use');
      }

      final success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(email: email, password: password);

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to login. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load remembered credentials
  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberedPassword = prefs.getString('remembered_password');

      if (rememberedEmail != null && rememberedPassword != null) {
        setState(() {
          _emailController.text = rememberedEmail;
          _passwordController.text = rememberedPassword;
          _rememberMe = true;
        });
        debugPrint('Remembered credentials loaded');
      }
    } catch (e) {
      debugPrint('Error loading remembered credentials: $e');
    }
  }

  // Get the appropriate biometric icon based on platform and available biometrics
  IconData _getBiometricIcon() {
    if (Platform.isIOS) {
      if (_biometricType.contains('Face')) {
        return Icons.face_retouching_natural;
      } else {
        return Icons.fingerprint;
      }
    } else {
      if (_biometricType.contains('Face')) {
        return Icons.face;
      } else {
        return Icons.fingerprint;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  Image.asset(
                    'assets/images/navisthesia_logo_transparent.png',
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),

                  // Updated Tagline
                  Text(
                    "Navigating Your Nurse Anesthesia Residency",
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show biometric icon if available
                          if (_canCheckBiometrics && _isBiometricSupported)
                            IconButton(
                              icon: Icon(_getBiometricIcon()),
                              onPressed:
                                  authProvider.isLoading
                                      ? null
                                      : _authenticateWithBiometrics,
                              tooltip: 'Sign in with $_biometricType',
                            ),
                          // Password visibility toggle
                          IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Remember Me checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                      const Text(
                        'Remember Me',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Forgot Password link - Move it here to balance the row
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/forgot-password');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        authProvider.isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Login'),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('Register'),
                      ),
                    ],
                  ),

                  // Admin Access - small, discreet link at the bottom
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => _showAdminLoginDialog(context),
                      child: Text(
                        'Admin Access',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textLight,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final adminUsernameController = TextEditingController();
    final adminPasswordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Admin Login'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: adminUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: adminPasswordController,
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Check against hardcoded admin credentials
                        if (adminUsernameController.text ==
                                AdminCredentials.username &&
                            adminPasswordController.text ==
                                AdminCredentials.password) {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed(AppRoutes.admin);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid admin credentials'),
                              backgroundColor: AppColors.errorColor,
                            ),
                          );
                        }
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
          ),
    );
  }
}

/// Custom painter for the NT logo
class NTLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.08
          ..strokeCap = StrokeCap.round;

    // N part
    final nPath = Path();
    // Starting point of the N
    nPath.moveTo(size.width * 0.25, size.height * 0.25);
    // Draw vertical line
    nPath.lineTo(size.width * 0.25, size.height * 0.75);
    // Draw diagonal line
    nPath.lineTo(size.width * 0.5, size.height * 0.25);
    // Draw vertical line
    nPath.lineTo(size.width * 0.5, size.height * 0.75);

    // T part (connects to the N)
    final tPath = Path();
    // Start at the top right of N
    tPath.moveTo(size.width * 0.5, size.height * 0.25);
    // Draw horizontal line for top of T
    tPath.lineTo(size.width * 0.75, size.height * 0.25);
    // Move to center of T
    tPath.moveTo(size.width * 0.625, size.height * 0.25);
    // Draw vertical line for stem of T
    tPath.lineTo(size.width * 0.625, size.height * 0.75);

    // Draw the paths
    canvas.drawPath(nPath, paint);
    canvas.drawPath(tPath, paint);

    // Add a small connecting dot at the intersection
    final dotPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      size.width * 0.06,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
