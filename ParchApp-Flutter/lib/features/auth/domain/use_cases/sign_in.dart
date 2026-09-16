import '../entities/authenticated_user.dart';
import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository _repository;
  const SignIn(this._repository);

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

  Future<AuthenticatedUser> withRecognizedUser(AuthenticatedUser user) =>
      _repository.continueAsRecognizedUser(user);
}
