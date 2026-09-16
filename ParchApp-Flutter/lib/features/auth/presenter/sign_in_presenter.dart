import '../model/auth_model.dart';
import '../model/auth_user.dart';
import '../view/contracts/sign_in_view_contract.dart';

class SignInPresenter {
  final SignInViewContract view;
  final AuthModel model;

  AuthUser? _recognizedUser;
  bool _isAuthenticating = false;

  SignInPresenter({
    required this.view,
    required this.model,
  });

  Future<void> load() async {
    final user = await model.getRecognizedUser();

    _recognizedUser = user;

    view.showRecognizedUser(user);
  }

  Future<void> onContinueAsRecognizedUserPressed() async {
    final user = _recognizedUser;

    if (user == null) {
      view.showError(
        'No recognized account is available.',
      );
      return;
    }

    await _authenticate(
      () => model.continueAsRecognizedUser(user),
    );
  }

  Future<void> onGoogleSignInPressed() async {
    await _authenticate(
      model.signInWithGoogle,
    );
  }

  Future<void> onSignInPressed({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      view.showError(
        'Please enter your university email.',
      );
      return;
    }

    if (!cleanEmail.contains('@')) {
      view.showError(
        'Please enter a valid email address.',
      );
      return;
    }

    if (password.isEmpty) {
      view.showError(
        'Please enter your password.',
      );
      return;
    }

    await _authenticate(
      () => model.signInWithCredentials(
        email: cleanEmail,
        password: password,
      ),
    );
  }

  void onForgotPasswordPressed() {
    view.showInfo(
      'Password recovery will be implemented next.',
    );
  }

  void onCreateAccountPressed() {
    view.navigateToCreateAccount();
  }

  Future<void> _authenticate(
    Future<bool> Function() action,
  ) async {
    if (_isAuthenticating) {
      return;
    }

    _isAuthenticating = true;
    view.showLoading(true);

    try {
      final success = await action();

      if (success) {
        view.navigateToHome();
      } else {
        view.showError(
          'Unable to sign in. Please try again.',
        );
      }
    } catch (_) {
      view.showError(
        'Something went wrong. Please try again.',
      );
    } finally {
      _isAuthenticating = false;
      view.showLoading(false);
    }
  }
}