import '../view/welcome_view_contract.dart';

class WelcomePresenter {
  final WelcomeViewContract view;

  WelcomePresenter({
    required this.view,
  });

  void onGetStartedPressed() {
    view.navigateToCreateAccount();
  }

  void onExistingAccountPressed() {
    view.navigateToSignIn();
  }
}