import '../../model/google_account.dart';

abstract class CreateAccountViewContract {
  void showSuggestedGoogleAccount(
    GoogleAccount? account,
  );

  void fillFormFromGoogleAccount(
    GoogleAccount account,
  );

  void showLoading(bool value);

  void showError(String message);

  void showInfo(String message);

  void navigateBack();

  void navigateToNextStep();
}