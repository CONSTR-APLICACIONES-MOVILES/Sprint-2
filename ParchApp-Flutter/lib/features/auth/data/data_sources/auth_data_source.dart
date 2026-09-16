import '../models/authenticated_user_model.dart';
import '../models/google_account_model.dart';

abstract interface class AuthDataSource {
  Future<AuthenticatedUserModel?> getRecognizedUser();
  Future<GoogleAccountModel?> getSuggestedGoogleAccount();
  Future<AuthenticatedUserModel?> signIn(String email, String password);
  Future<AuthenticatedUserModel?> signInWithGoogle();
  Future<AuthenticatedUserModel?> continueAsRecognizedUser(String userId);
  Future<AuthenticatedUserModel?> createAccount(
      String name, String email, String password);
  Future<AuthenticatedUserModel?> createAccountWithGoogle(String accountId);
}
