import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:navithesia_beta/models/user_model.dart';
import 'package:navithesia_beta/services/local_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Provider class that handles authentication state and operations
class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final LocalAuthService _localAuth = LocalAuthService();

  // Firebase Auth instance
  late final firebase_auth.FirebaseAuth _auth;
  bool _isFirebaseInitialized = false;

  User? _currentUser;
  User? _lastUser;
  bool _isLoading = false;
  String? _error;
  // Flag to prevent multiple simultaneous authentication attempts
  static bool _isAuthenticating = false;

  // Try with a simpler approach to avoid Firebase plugin issues
  Future<bool> registerManually({
    required String email,
    required String password,
    required String name,
    required String school,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(
        'Attempting manual registration without Firebase UserCredential',
      );

      // Generate a UUID for the user instead of using Firebase UID
      final userId = const Uuid().v4();
      final now = DateTime.now();

      // Create local user
      final user = User(
        id: userId,
        name: name,
        email: email,
        school: school,
        settings: {}, // Empty settings map
        createdAt: now,
        lastLogin: now,
      );

      // Save user data locally
      _currentUser = user;
      await _saveCurrentUser(user);

      // Also save as the last user for biometric authentication
      _lastUser = user;
      await _saveLastUser(user);

      debugPrint('User data saved locally with manual ID: $userId');
      debugPrint('Registered name: $name');

      // Automatically log in the user with Firebase
      try {
        debugPrint('Attempting to create Firebase user in the background...');
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // If successful, update the display name
        await userCredential.user?.updateDisplayName(name);
        debugPrint(
          'Firebase user created successfully: ${userCredential.user?.uid}',
        );
      } catch (e) {
        // If Firebase fails, we already have the local user created, so just log the error
        debugPrint('Failed to create Firebase user: $e');
        // Don't return false here since we still want to proceed with local user
      }

      return true;
    } catch (e, stackTrace) {
      _error = 'Registration failed: ${e.toString()}';
      debugPrint('Error during manual registration: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AuthProvider(this._prefs) {
    _loadCurrentUser();
    _loadLastUser();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized to avoid multiple initializations
      if (Firebase.apps.isEmpty) {
        debugPrint('Initializing Firebase in AuthProvider...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint(
          'Firebase initialized in AuthProvider with options: ${DefaultFirebaseOptions.currentPlatform}',
        );
      } else {
        debugPrint('Firebase was already initialized');
      }

      _auth = firebase_auth.FirebaseAuth.instance;
      _isFirebaseInitialized = true;

      debugPrint('Successfully obtained FirebaseAuth instance');

      // Set up auth state listener
      _auth.authStateChanges().listen((firebase_auth.User? firebaseUser) {
        if (firebaseUser != null) {
          // User is signed in
          debugPrint('Firebase user signed in: ${firebaseUser.uid}');
          _updateUserFromFirebase(
            firebaseUser.uid,
            firebaseUser.email ?? '',
            firebaseUser.displayName ?? '',
          );
        } else {
          // User is signed out
          debugPrint('Firebase user signed out');
          // We don't clear _currentUser here to allow for offline usage
        }
      });
    } catch (e, stackTrace) {
      _isFirebaseInitialized = false;
      debugPrint('Error initializing Firebase in AuthProvider: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// The current logged-in user, or null if no user is logged in
  User? get currentUser => _currentUser;

  /// Whether the provider is currently loading
  bool get isLoading => _isLoading;

  /// Whether a user is currently authenticated
  bool get isAuthenticated => _currentUser != null;

  /// The error message if an authentication operation fails
  String? get error => _error;

  /// The last authenticated user, or null if no user has been authenticated
  User? get lastUser => _lastUser;

  /// Check if the user is logged in (for backward compatibility)
  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

  /// Load current user from SharedPreferences
  Future<void> _loadCurrentUser() async {
    final userJson = _prefs.getString('currentUser');
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        debugPrint('Error loading current user: $e');
      }
    }
  }

  /// Load last user from SharedPreferences
  Future<void> _loadLastUser() async {
    final userJson = _prefs.getString('lastUser');
    if (userJson != null) {
      try {
        _lastUser = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        debugPrint('Error loading last user: $e');
      }
    }
  }

  // Update user from Firebase data
  void _updateUserFromFirebase(String uid, String email, String displayName) {
    final existingUser = _currentUser;
    if (existingUser != null && existingUser.id == uid) {
      // Update existing user
      _currentUser = existingUser.copyWith(
        email: email.isNotEmpty ? email : existingUser.email,
        name: displayName.isNotEmpty ? displayName : existingUser.name,
      );
    } else {
      // Create new user
      final now = DateTime.now();
      _currentUser = User(
        id: uid,
        email: email,
        name: displayName.isNotEmpty ? displayName : email.split('@').first,
        school: 'Not specified', // Default school value
        settings: {}, // Empty settings map
        createdAt: now,
        lastLogin: now,
      );
    }

    _saveCurrentUser(_currentUser!);
    notifyListeners();
  }

  Future<void> _saveCurrentUser(User user) async {
    await _prefs.setString('currentUser', jsonEncode(user.toJson()));
    // Also save by email for better retrieval
    await _saveUserByEmail(user);
  }

  Future<void> _saveLastUser(User user) async {
    await _prefs.setString('lastUser', jsonEncode(user.toJson()));
    // Also save by email for better retrieval
    await _saveUserByEmail(user);
  }

  /// Register a new user with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String school,
  }) async {
    // If we encounter issues with the Firebase UserCredential, use the manual registration
    if (_error?.contains("not a subtype of type 'PigeonUserDetails") ?? false) {
      debugPrint(
        'Detected PigeonUserDetails error, falling back to manual registration',
      );
      return registerManually(
        email: email,
        password: password,
        name: name,
        school: school,
      );
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Attempting to register with Firebase: $email');

      // Check if Firebase is initialized
      if (!_isFirebaseInitialized) {
        _error =
            'Firebase has not been properly initialized. Please restart the app.';
        debugPrint('Error: Firebase not initialized during registration');
        return false;
      }

      // Check password strength (Firebase requires 6+ characters)
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters long';
        debugPrint('Password too short: ${password.length} chars');
        return false;
      }

      // Register with Firebase Auth
      debugPrint('Creating user with email and password...');
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint(
          'User registered successfully with ID: ${userCredential.user?.uid}',
        );

        // Update display name in Firebase
        await userCredential.user?.updateDisplayName(name);
        debugPrint('Display name updated in Firebase: $name');

        final userId = userCredential.user?.uid ?? const Uuid().v4();
        final now = DateTime.now();

        final user = User(
          id: userId,
          name: name,
          email: email,
          school: school,
          settings: {}, // Empty settings map
          createdAt: now,
          lastLogin: now,
        );

        // Save user data locally
        _currentUser = user;
        await _saveCurrentUser(user);

        // Also save as last user for biometric login
        _lastUser = user;
        await _saveLastUser(user);

        debugPrint('User data saved locally');
        debugPrint('Registered with name: $name');

        return true;
      } catch (e) {
        if (e.toString().contains("not a subtype of type 'PigeonUserDetails")) {
          _error =
              "Registration error with Firebase plugin. Trying alternative method...";
          return registerManually(
            email: email,
            password: password,
            name: name,
            school: school,
          );
        } else {
          rethrow;
        }
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'email-already-in-use':
          _error =
              'This email is already registered. Please use a different email or try logging in.';
          break;
        case 'invalid-email':
          _error = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          _error =
              'Email/password registration is not enabled. Please contact support.';
          break;
        case 'weak-password':
          _error = 'The password is too weak. Please use a stronger password.';
          break;
        case 'internal-error':
          if (e.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
            _error =
                'Firebase Authentication is not properly configured. Please contact the app administrator to enable Email/Password authentication in the Firebase Console.';
            debugPrint(
              'Firebase CONFIGURATION_NOT_FOUND error detected. Email/Password authentication needs to be enabled in the Firebase Console.',
            );
          } else {
            _error = e.message ?? 'Registration failed';
          }
          break;
        case 'unknown':
          if (e.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
            _error =
                'Firebase Authentication is not properly configured. Please contact the app administrator to enable Email/Password authentication in the Firebase Console.';
            debugPrint(
              'Firebase CONFIGURATION_NOT_FOUND error detected. Email/Password authentication needs to be enabled in the Firebase Console.',
            );
          } else {
            _error = e.message ?? 'Registration failed';
          }
          break;
        default:
          _error = e.message ?? 'Registration failed';
      }

      debugPrint(
        'Firebase Auth Error during registration: [${e.code}] - ${e.message}',
      );
      return false;
    } on FirebaseException catch (e) {
      _error = 'Firebase configuration error: ${e.message}';
      debugPrint('Firebase Error: [${e.code}] - ${e.message}');
      return false;
    } catch (e, stackTrace) {
      if (e.toString().contains("not a subtype of type 'PigeonUserDetails")) {
        return registerManually(
          email: email,
          password: password,
          name: name,
          school: school,
        );
      }
      _error = 'Unexpected error: ${e.toString()}';
      debugPrint('Unexpected error during registration: $_error');
      debugPrint('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Standardize email format for lookups
      final normalizedEmail = email.toLowerCase().trim();

      debugPrint('Attempting to login with email: $normalizedEmail');
      debugPrint('-----Name Persistence Debug-----');

      // Create a Firebase app instance specifically for authentication
      if (!_isFirebaseInitialized) {
        await _reinitializeFirebase();
      }

      // IMPORTANT: First directly try to retrieve user from SharedPreferences by email
      // This is more reliable than the _findLocalUserByEmail method
      User? directUser;
      try {
        final userJson = _prefs.getString('user_${normalizedEmail}');
        if (userJson != null) {
          directUser = User.fromJson(jsonDecode(userJson));
          debugPrint(
            'Direct SharedPreferences lookup found: ${directUser.name}',
          );
        } else {
          debugPrint('No user found in direct SharedPreferences lookup');
        }
      } catch (e) {
        debugPrint('Error in direct SharedPreferences lookup: $e');
      }

      // Backup lookup using the helper method
      final localUser = await _findLocalUserByEmail(normalizedEmail);
      final registeredName = localUser?.name;

      // Compare user data sources
      if (directUser != null && localUser != null) {
        debugPrint('Both direct and helper lookup found users');
        debugPrint('Direct user name: ${directUser.name}');
        debugPrint('Helper-found user name: ${localUser.name}');
      }

      // Prioritize direct lookup over helper method
      final bestLocalUser = directUser ?? localUser;
      final bestLocalName = bestLocalUser?.name;

      debugPrint('Best local name found: ${bestLocalName ?? "none"}');

      try {
        // Sign in with Firebase Auth
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        // Get the user ID safely
        final uid = userCredential.user?.uid;

        if (uid == null) {
          throw Exception(
            'Firebase authentication succeeded but no user ID was returned',
          );
        }

        debugPrint('Login successful for user ID: $uid');

        // Get display name from Firebase
        String? firebaseName;
        try {
          firebaseName = userCredential.user?.displayName;
          if (firebaseName != null && firebaseName.isNotEmpty) {
            debugPrint('Firebase display name: $firebaseName');
          } else {
            debugPrint('Firebase display name is empty or null');
          }
        } catch (e) {
          debugPrint('Error getting Firebase display name: $e');
        }

        // Update Firebase display name if we have a registered name but Firebase doesn't
        if (bestLocalName != null &&
            bestLocalName.isNotEmpty &&
            (firebaseName == null || firebaseName.isEmpty)) {
          try {
            await userCredential.user?.updateDisplayName(bestLocalName);
            debugPrint('Updated Firebase display name to: $bestLocalName');
            firebaseName = bestLocalName;
          } catch (e) {
            debugPrint('Error updating Firebase display name: $e');
          }
        }

        // Name priority: direct stored name > helper found name > Firebase display name > email extraction
        String name = bestLocalName ?? firebaseName ?? '';
        debugPrint('Final name choice: $name');

        if (name.isEmpty) {
          // Only extract from email as last resort
          debugPrint('No name found, extracting from email as last resort');
          name = normalizedEmail
              .split('@')
              .first
              .split('.')
              .map(
                (part) =>
                    part.isNotEmpty
                        ? part[0].toUpperCase() + part.substring(1)
                        : '',
              )
              .join(' ');
          debugPrint('Name extracted from email: $name');
        } else {
          debugPrint('Using existing name: $name');
        }

        // Create user with verified data and preserved registration info
        final now = DateTime.now();
        final user = User(
          id: uid,
          email: normalizedEmail,
          name: name,
          school: bestLocalUser?.school ?? 'Not specified',
          settings: bestLocalUser?.settings ?? {},
          createdAt: bestLocalUser?.createdAt ?? now,
          lastLogin: now,
        );

        _currentUser = user;
        await _saveCurrentUser(user);

        // Also save directly by email key for more reliable retrieval
        await _prefs.setString(
          'user_${normalizedEmail}',
          jsonEncode(user.toJson()),
        );
        debugPrint('Saved user directly with key: user_${normalizedEmail}');

        // Also save as last user for biometric login
        _lastUser = user;
        await _saveLastUser(user);
        debugPrint('Saved current user as last user for biometric login');
        debugPrint('-----End Name Persistence Debug-----');

        return true;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _error = 'Invalid email or password. Please check your credentials.';
        } else if (e.code == 'user-not-found') {
          _error = 'No account found with this email address.';
        } else {
          _error = e.message ?? 'Login failed';
        }
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        return false;
      }
    } catch (e) {
      debugPrint('Unexpected login error: $e');

      // Special handling for the PigeonUserDetails error
      if (e.toString().contains("PigeonUserDetails")) {
        debugPrint(
          'PigeonUserDetails error detected, trying alternative method...',
        );
        debugPrint('-----PigeonUserDetails Alternative Name Debug-----');

        // Standardize email format for lookups
        final normalizedEmail = email.toLowerCase().trim();

        // Try direct lookup in SharedPreferences first
        User? directUser;
        try {
          final userJson = _prefs.getString('user_${normalizedEmail}');
          if (userJson != null) {
            directUser = User.fromJson(jsonDecode(userJson));
            debugPrint(
              'Alt path - Direct SharedPreferences lookup found: ${directUser.name}',
            );
          } else {
            debugPrint(
              'Alt path - No user found in direct SharedPreferences lookup',
            );
          }
        } catch (e) {
          debugPrint('Alt path - Error in direct SharedPreferences lookup: $e');
        }

        // Check if we have a local user with this email
        final localUser = await _findLocalUserByEmail(normalizedEmail);

        // Prioritize direct lookup over helper method
        final bestLocalUser = directUser ?? localUser;
        final bestLocalName = bestLocalUser?.name;

        debugPrint(
          'Alt path - Best local name found: ${bestLocalName ?? "none"}',
        );

        // Try to get the user ID directly using the Firebase REST API
        try {
          // First, try signing in again without using the user object
          await _auth.signOut(); // Sign out any existing user

          // We have to try a different approach - use the token-only login flow
          final result = await _auth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );

          final uid = result.user?.uid;

          if (uid != null) {
            debugPrint('Alt path - Successfully retrieved UID: $uid');

            // Use best available name
            String name = bestLocalName ?? '';

            if (name.isEmpty) {
              debugPrint(
                'Alt path - No registered name found, extracting from email',
              );
              name = normalizedEmail
                  .split('@')
                  .first
                  .split('.')
                  .map(
                    (part) =>
                        part.isNotEmpty
                            ? part[0].toUpperCase() + part.substring(1)
                            : '',
                  )
                  .join(' ');
              debugPrint('Alt path - Name extracted from email: $name');
            } else {
              debugPrint('Alt path - Using registered name: $name');
            }

            // Create the user with minimal safe data
            final now = DateTime.now();
            final user = User(
              id: uid,
              email: normalizedEmail,
              name: name,
              school: bestLocalUser?.school ?? 'Not specified',
              settings: bestLocalUser?.settings ?? {},
              createdAt: bestLocalUser?.createdAt ?? now,
              lastLogin: now,
            );

            _currentUser = user;
            await _saveCurrentUser(user);

            // Also save directly for more reliable retrieval
            await _prefs.setString(
              'user_${normalizedEmail}',
              jsonEncode(user.toJson()),
            );
            debugPrint(
              'Alt path - Saved user with email key: user_${normalizedEmail}',
            );

            // Also save as last user for biometric login
            _lastUser = user;
            await _saveLastUser(user);
            debugPrint('Alt path - Saved as last user for biometric login');

            debugPrint(
              '-----End PigeonUserDetails Alternative Name Debug-----',
            );
            return true;
          } else {
            throw Exception('Failed to get user ID from Firebase');
          }
        } catch (innerError) {
          debugPrint('Alternative method also failed: $innerError');

          // Final fallback - use local user or create one with email hash
          if (bestLocalUser != null) {
            // Use existing local user with updated login time
            final now = DateTime.now();
            final user = bestLocalUser.copyWith(lastLogin: now);

            _currentUser = user;
            await _saveCurrentUser(user);

            // Also save directly for more reliable retrieval
            await _prefs.setString(
              'user_${normalizedEmail}',
              jsonEncode(user.toJson()),
            );
            debugPrint(
              'Alt path - Saved emergency user with email key: user_${normalizedEmail}',
            );

            // Also save as last user for biometric login
            _lastUser = user;
            await _saveLastUser(user);

            debugPrint(
              'Alt path - Using existing local user for: $normalizedEmail',
            );
            debugPrint('Alt path - User name: ${user.name}');
            debugPrint('-----End PigeonUserDetails Fallback Debug-----');
            return true;
          }

          // Create emergency fallback user
          final now = DateTime.now();

          // Extract a proper name from the email as last resort
          debugPrint('Alt path - Creating emergency user with name from email');
          String name = normalizedEmail
              .split('@')
              .first
              .split('.')
              .map(
                (part) =>
                    part.isNotEmpty
                        ? part[0].toUpperCase() + part.substring(1)
                        : '',
              )
              .join(' ');
          debugPrint('Alt path - Emergency name: $name');

          final user = User(
            id: normalizedEmail.hashCode.toString(),
            email: normalizedEmail,
            name: name,
            school: 'Not specified',
            settings: {},
            createdAt: now,
            lastLogin: now,
          );

          _currentUser = user;
          await _saveCurrentUser(user);

          // Also save directly for more reliable retrieval
          await _prefs.setString(
            'user_${normalizedEmail}',
            jsonEncode(user.toJson()),
          );
          debugPrint(
            'Alt path - Saved emergency user with email key: user_${normalizedEmail}',
          );

          // Also save as last user for biometric login
          _lastUser = user;
          await _saveLastUser(user);

          debugPrint(
            'Alt path - Created emergency fallback user for: $normalizedEmail',
          );
          debugPrint('-----End PigeonUserDetails Fallback Debug-----');
          return true;
        }
      }

      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Re-initialize Firebase to ensure it's working properly
  Future<void> _reinitializeFirebase() async {
    try {
      debugPrint('Re-initializing Firebase for authentication...');

      // Make sure we have a clean Firebase instance
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _auth = firebase_auth.FirebaseAuth.instance;
      _isFirebaseInitialized = true;

      debugPrint('Firebase re-initialized successfully');
    } catch (e) {
      debugPrint('Error re-initializing Firebase: $e');
      // We'll continue with the existing instance if available
    }
  }

  // Helper method for manual login when Firebase plugin has issues
  Future<bool> _loginManually(String email, String password) async {
    try {
      debugPrint('Attempting manual login for: $email');

      // Try to sign in with Firebase Auth directly
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint(
          'Manual login successful for user: ${userCredential.user?.uid}',
        );

        // Create a basic user object without relying on PigeonUserDetails
        final now = DateTime.now();
        final user = User(
          id: userCredential.user!.uid,
          email: email,
          name: userCredential.user!.displayName ?? email.split('@').first,
          school: 'Not specified', // Default school value
          settings: {}, // Empty settings map
          createdAt: now,
          lastLogin: now,
        );

        _currentUser = user;
        await _saveCurrentUser(user);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error during manual login: $e');
      return false;
    }
  }

  // Login with the last authenticated user (for biometric authentication)
  Future<bool> loginWithLastUser([bool useBiometrics = true]) async {
    // Prevent multiple authentication attempts
    if (_isAuthenticating) {
      debugPrint(
        'Biometric authentication already in progress, ignoring duplicate call',
      );
      return false;
    }

    _isAuthenticating = true;
    debugPrint('Attempting to login with last user...');

    if (_lastUser == null) {
      _error = "No previous user found";
      debugPrint('No previous user found in local storage');
      notifyListeners();
      _isAuthenticating = false; // Reset flag
      return false;
    }

    debugPrint('Found last user: ${_lastUser!.email}');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (useBiometrics) {
        final authenticated = await _localAuth.authenticate();

        if (!authenticated) {
          _error = "Biometric authentication failed";
          debugPrint('Biometric authentication failed');
          return false;
        }

        debugPrint('Biometric authentication successful');
      }

      // We don't need to check _auth.currentUser here as we're just loading saved user data
      // for quick login after biometric auth. The saved lastUser is already authenticated.

      // If we need to verify with Firebase, we can try a silent token refresh later

      // Set the current user from the last user
      _currentUser = _lastUser;
      await _saveCurrentUser(_currentUser!);

      debugPrint('Successfully logged in as last user: ${_currentUser!.email}');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error during biometric login: $_error');
      return false;
    } finally {
      _isLoading = false;
      _isAuthenticating = false; // Reset flag
      notifyListeners();
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Firebase Auth
      await _auth.signOut();

      // Save the current user as the last user for quick login
      if (_currentUser != null) {
        _lastUser = _currentUser;
        await _saveLastUser(_lastUser!);
      }

      _currentUser = null;
      await _prefs.remove('currentUser');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error during logout: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a password reset email
  Future<bool> sendPasswordResetEmail({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Attempting to send password reset email to: $email');

      // Send password reset email directly without checking if user exists first
      // This handles edge cases where users might have been created locally but not properly synced with Firebase
      try {
        await _auth.sendPasswordResetEmail(email: email);
        debugPrint('Password reset email sent successfully to: $email');

        // Sign out the current user to ensure they use the new password on next login
        if (_auth.currentUser != null) {
          await _auth.signOut();
          debugPrint(
            'Signed out current user to ensure clean login with new password',
          );
        }

        return true;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // If the user doesn't exist in Firebase but might exist locally, try to recreate the Firebase account
          final localUsers = await _findLocalUserByEmail(email);
          if (localUsers != null) {
            _error =
                'Account synchronization issue detected. Please try registering again or contact support.';
            debugPrint('Local user found but not in Firebase: $email');
          } else {
            _error = 'No account found with this email address.';
          }
        } else {
          rethrow; // Let the outer catch handle other Firebase errors
        }
        return false;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          _error = 'The email address is not valid.';
          break;
        case 'user-not-found':
          _error = 'No account found with this email address.';
          break;
        case 'too-many-requests':
          _error = 'Too many requests. Please try again later.';
          break;
        default:
          _error = e.message ?? 'Failed to send password reset email';
      }

      debugPrint(
        'Firebase Auth Error during password reset: [${e.code}] - ${e.message}',
      );
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Unexpected error sending password reset: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to find a local user by email
  Future<User?> _findLocalUserByEmail(String email) async {
    debugPrint('Looking for user with email: $email');

    // Check if current user matches the email
    if (_currentUser?.email.toLowerCase() == email.toLowerCase()) {
      debugPrint('Found matching current user');
      return _currentUser;
    }

    // Check if last user matches the email
    if (_lastUser?.email.toLowerCase() == email.toLowerCase()) {
      debugPrint('Found matching last user');
      return _lastUser;
    }

    // Check for user in SharedPreferences by email
    try {
      final userJson = _prefs.getString('user_${email.toLowerCase()}');
      if (userJson != null) {
        debugPrint('Found user in SharedPreferences by email');
        return User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint('Error loading user from SharedPreferences: $e');
    }

    debugPrint('No matching user found for email: $email');
    return null;
  }

  // Save user by email for better persistence
  Future<void> _saveUserByEmail(User user) async {
    try {
      final email = user.email.toLowerCase();
      await _prefs.setString('user_$email', jsonEncode(user.toJson()));
      debugPrint('Saved user data for email: $email');
    } catch (e) {
      debugPrint('Error saving user by email: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    required String email,
    String? school,
  }) async {
    if (_currentUser == null) {
      _error = 'No user is currently logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Update Firebase Auth profile
      if (_auth.currentUser != null) {
        // Update display name
        await _auth.currentUser!.updateDisplayName(name);

        // Update email if changed
        if (_auth.currentUser!.email != email) {
          await _auth.currentUser!.updateEmail(email);
        }
      }

      // Update local user data
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        school: school ?? _currentUser!.school,
      );

      await _saveCurrentUser(_currentUser!);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to update profile';
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user settings
  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    if (_currentUser == null) {
      _error = 'No user is currently logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Merge new settings with existing settings
      final updatedSettings = {..._currentUser!.settings, ...newSettings};

      // Update user with new settings
      _currentUser = _currentUser!.copyWith(settings: updatedSettings);
      await _saveCurrentUser(_currentUser!);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating settings: $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
