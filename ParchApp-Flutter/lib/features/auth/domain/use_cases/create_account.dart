import '../entities/authenticated_user.dart';
import '../entities/auth_failure.dart';
import '../entities/google_account.dart';
import '../repositories/auth_repository.dart';

class CreateAccount {
  final AuthRepository _repository;
  const CreateAccount(this._repository);

  Future<GoogleAccount?> suggestedAccount() =>
      _repository.getSuggestedGoogleAccount();
  Future<AuthenticatedUser> withGoogle(GoogleAccount account) =>
      _repository.createAccountWithGoogle(account);

  Future<AuthenticatedUser> call({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();
    if (cleanName.isEmpty) {
      throw const AuthValidationException('Please enter your full name.');
    }
    if (cleanEmail.isEmpty) {
      throw const AuthValidationException(
          'Please enter your university email.');
    }
    if (!cleanEmail.contains('@')) {
      throw const AuthValidationException(
          'Please enter a valid email address.');
    }
    if (password.isEmpty) {
      throw const AuthValidationException('Please enter a password.');
    }
    if (confirmPassword.isEmpty) {
      throw const AuthValidationException('Please confirm your password.');
    }
    if (password != confirmPassword) {
      throw const AuthValidationException('Passwords do not match.');
    }
    return _repository.createAccount(cleanName, cleanEmail, password);
  }
}
