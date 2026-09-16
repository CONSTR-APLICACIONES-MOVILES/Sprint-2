import '../model/auth_model.dart';
import '../model/google_account.dart';
import '../view/contracts/create_account_view_contract.dart';

class CreateAccountPresenter {
  final CreateAccountViewContract view;
  final AuthModel model;

  GoogleAccount? _suggestedGoogleAccount;
  bool _isSubmitting = false;

  CreateAccountPresenter({
    required this.view,
    required this.model,
  });

  Future<void> load() async {
    final account =
        await model.getSuggestedGoogleAccount();

    _suggestedGoogleAccount = account;

    view.showSuggestedGoogleAccount(
      account,
    );
  }

  void onBackPressed() {
    view.navigateBack();
  }

  void onGoogleAccountSelected() {
    final account = _suggestedGoogleAccount;

    if (account == null) {
      view.showError(
        'No Google account is currently available.',
      );
      return;
    }

    view.fillFormFromGoogleAccount(
      account,
    );
  }

  Future<void> onContinueWithGooglePressed() async {
    final account = _suggestedGoogleAccount;

    if (account == null) {
      view.showError(
        'Please choose a Google account first.',
      );
      return;
    }

    await _submit(
      () => model.createAccountWithGoogle(
        account,
      ),
    );
  }

  void onUseAnotherGoogleAccountPressed() {
    view.showInfo(
      'Google account selection will be connected later.',
    );
  }

  Future<void> onContinuePressed({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      view.showError(
        'Please enter your full name.',
      );
      return;
    }

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
        'Please enter a password.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      view.showError(
        'Please confirm your password.',
      );
      return;
    }

    if (password != confirmPassword) {
      view.showError(
        'Passwords do not match.',
      );
      return;
    }

    await _submit(
      () => model.createAccount(
        fullName: cleanName,
        email: cleanEmail,
        password: password,
      ),
    );
  }

  Future<void> _submit(
    Future<bool> Function() action,
  ) async {
    if (_isSubmitting) {
      return;
    }

    _isSubmitting = true;

    view.showLoading(true);

    try {
      final success = await action();

      if (success) {
        view.navigateToNextStep();
      } else {
        view.showError(
          'Unable to create your account.',
        );
      }
    } catch (_) {
      view.showError(
        'Something went wrong. Please try again.',
      );
    } finally {
      _isSubmitting = false;

      view.showLoading(false);
    }
  }
}