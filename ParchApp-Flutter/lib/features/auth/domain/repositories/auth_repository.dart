import '../entities/authenticated_user.dart';
import '../entities/google_account.dart';

abstract interface class AuthRepository {
  Future<AuthenticatedUser?> getRecognizedUser();
  Future<GoogleAccount?> getSuggestedGoogleAccount();
  Future<AuthenticatedUser> signIn(String email, String password);
  Future<AuthenticatedUser> signInWithGoogle();
  Future<AuthenticatedUser> continueAsRecognizedUser(AuthenticatedUser user);
  Future<AuthenticatedUser> createAccount(
      String name, String email, String password);
  Future<AuthenticatedUser> createAccountWithGoogle(GoogleAccount account);
}
