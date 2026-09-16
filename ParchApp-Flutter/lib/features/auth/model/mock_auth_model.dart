import 'auth_model.dart';
import 'auth_user.dart';
import 'google_account.dart';

class MockAuthModel implements AuthModel {
  @override
  Future<AuthUser?> getRecognizedUser() async {
    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    return const AuthUser(
      id: 'user-001',
      name: 'Alex Valenzuela',
      program: 'Systems and Computer Engineering',
      email: 'alex.valenzuela@university.edu',
      verified: true,
    );
  }

  @override
  Future<bool> continueAsRecognizedUser(
    AuthUser user,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    return true;
  }

  @override
  Future<bool> signInWithGoogle() async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    return true;
  }

  @override
  Future<bool> signInWithCredentials({
    required String email,
    required String password,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    return email.isNotEmpty && password.isNotEmpty;
  }

  @override
  Future<GoogleAccount?> getSuggestedGoogleAccount() async {
    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    return const GoogleAccount(
      id: 'google-001',
      name: 'Alex Valenzuela',
      email: 'alex.valenzuela@gmail.com',
    );
  }

  @override
  Future<bool> createAccountWithGoogle(
    GoogleAccount account,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    return true;
  }

  @override
  Future<bool> createAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    return fullName.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty;
  }

}