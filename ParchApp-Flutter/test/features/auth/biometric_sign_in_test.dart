import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/auth/domain/repositories/biometric_authenticator.dart';
import 'package:parchapp/features/auth/domain/use_cases/sign_in.dart';
import 'package:parchapp/features/auth/presentation/view_models/auth_state.dart';
import 'package:parchapp/features/auth/presentation/view_models/sign_in_view_model.dart';
import '../../support/fake_auth_repository.dart';

class _FakeBiometrics implements BiometricAuthenticator {
  bool available = true;
  bool confirms = true;
  final List<String> reasons = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return confirms;
  }
}

void main() {
  late _FakeBiometrics biometrics;
  late SignInViewModel model;

  setUp(() async {
    biometrics = _FakeBiometrics();
    model = SignInViewModel(
        SignIn(FakeAuthRepository(), biometrics: biometrics));
    await model.load();
  });
  tearDown(() => model.dispose());

  test('Face ID confirms the saved account before continuing', () async {
    await model.continueAsRecognizedUser();
    expect(biometrics.reasons, ['Confirm it is you to continue as Test']);
    expect(model.value.status, AuthStatus.authenticated);
  });

  test('a failed Face ID keeps the user on sign in', () async {
    biometrics.confirms = false;
    await model.continueAsRecognizedUser();
    expect(model.value.status, AuthStatus.authenticationError);
    expect(model.value.message, contains('could not confirm'));
  });

  test('devices without biometrics or passcode continue as before', () async {
    biometrics.available = false;
    await model.continueAsRecognizedUser();
    expect(biometrics.reasons, isEmpty);
    expect(model.value.status, AuthStatus.authenticated);
  });
}