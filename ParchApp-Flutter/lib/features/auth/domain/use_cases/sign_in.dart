import '../entities/authenticated_user.dart';
import '../entities/auth_failure.dart';
import '../entities/biometric_sign_in.dart';
import '../entities/saved_credentials.dart';
import '../repositories/auth_repository.dart';
import '../repositories/biometric_authenticator.dart';
import '../repositories/saved_credentials_repository.dart';

class SignIn {
  final AuthRepository _repository;
  final BiometricAuthenticator? _biometrics;
  final SavedCredentialsRepository? _credentials;
  const SignIn(this._repository,
      {BiometricAuthenticator? biometrics,
      SavedCredentialsRepository? credentials})
      : _biometrics = biometrics,
        _credentials = credentials;

  Future<AuthenticatedUser?> recognizedUser() =>
      _repository.getRecognizedUser();

  Future<BiometricSignIn> biometricSignIn() async {
    final biometrics = _biometrics;
    final credentials = _credentials;
    if (biometrics == null ||
        credentials == null ||
        !await biometrics.isAvailable()) {
      return BiometricSignIn.unavailable;
    }
    return await credentials.read() == null
        ? BiometricSignIn.available
        : BiometricSignIn.enabled;
  }

  Future<AuthenticatedUser> call(
      {required String email,
      required String password,
      bool rememberWithBiometrics = false}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw const AuthValidationException(
          'Please enter your university email.');
    }
    if (!cleanEmail.contains('@')) {
      throw const AuthValidationException(
          'Please enter a valid email address.');
    }
    if (password.isEmpty) {
      throw const AuthValidationException('Please enter your password.');
    }
    final user = await _repository.signIn(cleanEmail, password);
    if (rememberWithBiometrics) {
      await _remember(SavedCredentials(email: cleanEmail, password: password));
    }
    return user;
  }

  Future<void> _remember(SavedCredentials saved) async {
    final biometrics = _biometrics;
    final credentials = _credentials;
    if (biometrics == null || credentials == null) return;
    try {
      if (await biometrics
          .authenticate('Confirm it is you to turn on Face ID sign-in')) {
        await credentials.save(saved);
      }
    } catch (_) {}
  }

  Future<AuthenticatedUser> withBiometrics() async {
    final biometrics = _biometrics;
    final saved = await _credentials?.read();
    if (biometrics == null || saved == null) {
      throw const AuthValidationException('Face ID sign-in is not turned on.');
    }
    if (!await biometrics.authenticate('Confirm it is you to sign in')) {
      throw const AuthenticationException(
          'We could not confirm it is you. Try again or sign in with your password.');
    }
    return _repository.signIn(saved.email, saved.password);
  }

  Future<void> turnOffBiometricSignIn() async => _credentials?.clear();

  Future<AuthenticatedUser> withGoogle() => _repository.signInWithGoogle();

  Future<AuthenticatedUser> withRecognizedUser(AuthenticatedUser user) async {
    final biometrics = _biometrics;
    if (biometrics != null &&
        await biometrics.isAvailable() &&
        !await biometrics
            .authenticate('Confirm it is you to continue as ${user.firstName}')) {
      throw const AuthenticationException(
          'We could not confirm it is you. Try again or sign in with your password.');
    }
    return _repository.continueAsRecognizedUser(user);
  }
}