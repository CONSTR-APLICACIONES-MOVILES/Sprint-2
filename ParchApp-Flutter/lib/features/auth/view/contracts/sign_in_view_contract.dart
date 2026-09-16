import '../../model/auth_user.dart';

abstract class SignInViewContract {
  void showRecognizedUser(AuthUser? user);

  void showLoading(bool value);

  void showError(String message);

  void showInfo(String message);

  void navigateToHome();

  void navigateToCreateAccount();
}