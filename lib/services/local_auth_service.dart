import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    if (kIsWeb) {
      // Web doesn't support biometric auth, so we'll just return true
      return true;
    }

    try {
      // Check if device supports biometric authentication
      final canAuthenticate = await _auth.canCheckBiometrics;
      if (!canAuthenticate) {
        debugPrint('Device does not support biometric authentication');
        return false;
      }

      // Get available biometrics
      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        debugPrint('No biometrics enrolled on this device');
        return false;
      }

      // Authenticate
      return await _auth.authenticate(
        localizedReason: 'Authenticate to sign in',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }
}
