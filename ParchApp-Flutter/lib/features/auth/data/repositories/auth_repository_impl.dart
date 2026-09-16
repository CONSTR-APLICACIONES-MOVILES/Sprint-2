import '../../domain/entities/authenticated_user.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/google_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_data_source.dart';
import '../models/authenticated_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _source;
  const AuthRepositoryImpl(this._source);

  Future<AuthenticatedUser> _authenticate(
      Future<AuthenticatedUserModel?> Function() request) async {
    final AuthenticatedUserModel? model;
    try {
      model = await request();
    } catch (_) {
      throw const AuthenticationException(
          'Authentication is unavailable. Please try again.');
    }
    if (model == null) {
      throw const AuthenticationException(
          'Unable to authenticate. Please check your details and try again.');
    }
    return model.toEntity();
  }

  @override
  Future<AuthenticatedUser?> getRecognizedUser() async =>
      (await _source.getRecognizedUser())?.toEntity();
  @override
  Future<GoogleAccount?> getSuggestedGoogleAccount() async =>
      (await _source.getSuggestedGoogleAccount())?.toEntity();
  @override
  Future<AuthenticatedUser> signIn(String email, String password) =>
      _authenticate(() => _source.signIn(email, password));
  @override
  Future<AuthenticatedUser> signInWithGoogle() =>
      _authenticate(_source.signInWithGoogle);
  @override
  Future<AuthenticatedUser> continueAsRecognizedUser(AuthenticatedUser user) =>
      _authenticate(() => _source.continueAsRecognizedUser(user.id));
  @override
  Future<AuthenticatedUser> createAccount(
          String name, String email, String password) =>
      _authenticate(() => _source.createAccount(name, email, password));
  @override
  Future<AuthenticatedUser> createAccountWithGoogle(GoogleAccount account) =>
      _authenticate(() => _source.createAccountWithGoogle(account.id));
}
