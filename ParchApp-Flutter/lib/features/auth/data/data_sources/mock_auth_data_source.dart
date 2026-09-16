import 'auth_data_source.dart';
import '../models/authenticated_user_model.dart';
import '../models/google_account_model.dart';

/// Demo responses only; no real credentials, OAuth or persistent session.
class MockAuthDataSource implements AuthDataSource {
  static const _user = AuthenticatedUserModel(
      id: 'user-001',
      name: 'Alex Valenzuela',
      email: 'alex.valenzuela@university.edu',
      program: 'Systems and Computer Engineering',
      verified: true);
  static const _googleAccount = GoogleAccountModel(
      id: 'google-001',
      name: 'Alex Valenzuela',
      email: 'alex.valenzuela@gmail.com');

  @override
  Future<AuthenticatedUserModel?> getRecognizedUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _user;
  }

  @override
  Future<GoogleAccountModel?> getSuggestedGoogleAccount() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _googleAccount;
  }

  @override
  Future<AuthenticatedUserModel?> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (email.isEmpty || password.isEmpty) return null;
    return AuthenticatedUserModel(
        id: 'demo-user', name: email.split('@').first, email: email);
  }

  @override
  Future<AuthenticatedUserModel?> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return AuthenticatedUserModel(
        id: _googleAccount.id,
        name: _googleAccount.name,
        email: _googleAccount.email);
  }

  @override
  Future<AuthenticatedUserModel?> continueAsRecognizedUser(
      String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return userId == _user.id ? _user : null;
  }

  @override
  Future<AuthenticatedUserModel?> createAccount(
      String name, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (name.isEmpty || email.isEmpty || password.isEmpty) return null;
    return AuthenticatedUserModel(id: 'demo-user', name: name, email: email);
  }

  @override
  Future<AuthenticatedUserModel?> createAccountWithGoogle(
      String accountId) async {
    if (accountId != _googleAccount.id) return null;
    return signInWithGoogle();
  }
}
