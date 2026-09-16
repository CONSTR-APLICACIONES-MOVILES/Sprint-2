import '../../domain/entities/auth_failure.dart';
import '../../domain/use_cases/create_account.dart';
import 'auth_state.dart';
import 'auth_view_model.dart';

class CreateAccountViewModel extends AuthViewModel {
  final CreateAccount _createAccount;
  bool _loaded = false;
  CreateAccountViewModel(this._createAccount);

  Future<void> load() async {
    if (_loaded || isDisposed) return;
    _loaded = true;
    try {
      final account = await _createAccount.suggestedAccount();
      emit(value.copyWith(
          suggestedGoogleAccount: account, message: value.message));
    } catch (_) {
      if (value.status == AuthStatus.idle) {
        emit(value.copyWith(
            status: AuthStatus.authenticationError,
            message:
                'Unable to load Google accounts. You can still use email.'));
      }
    }
  }

  Future<void> createAccount(
          {required String fullName,
          required String email,
          required String password,
          required String confirmPassword}) =>
      authenticate(() => _createAccount(
          fullName: fullName,
          email: email,
          password: password,
          confirmPassword: confirmPassword));

  Future<void> continueWithGoogle() => authenticate(() async {
        final account = value.suggestedGoogleAccount;
        if (account == null) {
          throw const AuthValidationException(
              'Please choose a Google account first.');
        }
        return _createAccount.withGoogle(account);
      });
}
