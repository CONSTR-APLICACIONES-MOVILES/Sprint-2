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
    await _refreshBiometricSignIn();
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

  Future<void> _refreshBiometricSignIn() async {
    try {
      final status = await _signIn.biometricSignIn();
      emit(value.copyWith(biometricSignIn: status, message: value.message));
    } catch (_) {}
  }

  Future<void> signIn(
          {required String email,
          required String password,
          bool rememberWithBiometrics = false}) =>
      authenticate(() => _signIn(
          email: email,
          password: password,
          rememberWithBiometrics: rememberWithBiometrics));

  Future<void> signInWithBiometrics() => authenticate(_signIn.withBiometrics);

  Future<void> turnOffBiometricSignIn() async {
    if (isDisposed || value.isLoading) return;
    try {
      await _signIn.turnOffBiometricSignIn();
    } catch (_) {}
    final status = await _signIn.biometricSignIn();
    emit(value.copyWith(
        biometricSignIn: status, message: 'Face ID sign-in is turned off.'));
  }

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