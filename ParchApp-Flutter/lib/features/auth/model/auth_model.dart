import 'auth_user.dart';
import 'google_account.dart';

abstract class AuthModel {
  Future<AuthUser?> getRecognizedUser();

  Future<bool> continueAsRecognizedUser(
    AuthUser user,
  );

  Future<bool> signInWithGoogle();

  Future<bool> signInWithCredentials({
    required String email,
    required String password,
  });

  Future<GoogleAccount?> getSuggestedGoogleAccount();

  Future<bool> createAccountWithGoogle(
    GoogleAccount account,
  );

  Future<bool> createAccount({
    required String fullName,
    required String email,
    required String password,
  });
}