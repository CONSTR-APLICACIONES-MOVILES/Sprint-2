import '../../domain/entities/auth_failure.dart';
import '../../domain/use_cases/sign_in.dart';
import 'auth_state.dart';
import 'auth_view_model.dart';

class SignInViewModel extends AuthViewModel {
  final SignIn _signIn;
  bool _loaded = false;
  SignInViewModel(this._signIn);

  Future<void> load() async {
    if (_loaded || isDisposed) return;
    _loaded = true;
    try {
      final user = await _signIn.recognizedUser();
      emit(value.copyWith(recognizedUser: user, message: value.message));
    } catch (_) {
      if (value.status == AuthStatus.idle) {
        emit(value.copyWith(
            status: AuthStatus.authenticationError,
            message:
                'Unable to load your saved account. You can still sign in.'));
      }
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      authenticate(() => _signIn(email: email, password: password));

  Future<void> signInWithGoogle() => authenticate(_signIn.withGoogle);

  Future<void> continueAsRecognizedUser() => authenticate(() async {
        final user = value.recognizedUser;
        if (user == null) {
          throw const AuthValidationException(
              'No recognized account is available.');
        }
        return _signIn.withRecognizedUser(user);
      });
}
