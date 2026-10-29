import 'package:local_auth/local_auth.dart';

import '../../domain/repositories/biometric_authenticator.dart';

class LocalBiometricAuthenticator implements BiometricAuthenticator {
  final LocalAuthentication _auth;

  LocalBiometricAuthenticator([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      return false;
    }
  }
}