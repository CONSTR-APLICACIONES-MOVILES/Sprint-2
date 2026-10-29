import '../entities/authenticated_user.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';
import '../repositories/biometric_authenticator.dart';

class SignIn {
  final AuthRepository _repository;
  final BiometricAuthenticator? _biometrics;
  const SignIn(this._repository, {BiometricAuthenticator? biometrics})
      : _biometrics = biometrics;

  Future<AuthenticatedUser?> recognizedUser() =>
      _repository.getRecognizedUser();

  Future<AuthenticatedUser> call(
      {required String email, required String password}) async {
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
    return _repository.signIn(cleanEmail, password);
  }

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
