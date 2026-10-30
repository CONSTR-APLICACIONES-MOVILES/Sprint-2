import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/auth/domain/entities/biometric_sign_in.dart';
import 'package:parchapp/features/auth/domain/entities/saved_credentials.dart';
import 'package:parchapp/features/auth/domain/repositories/biometric_authenticator.dart';
import 'package:parchapp/features/auth/domain/repositories/saved_credentials_repository.dart';
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

class _FakeCredentials implements SavedCredentialsRepository {
  SavedCredentials? saved;

  @override
  Future<SavedCredentials?> read() async => saved;

  @override
  Future<void> save(SavedCredentials credentials) async => saved = credentials;

  @override
  Future<void> clear() async => saved = null;
}

void main() {
  late FakeAuthRepository repository;
  late _FakeBiometrics biometrics;
  late _FakeCredentials credentials;
  late SignInViewModel model;

  setUp(() async {
    repository = FakeAuthRepository();
    biometrics = _FakeBiometrics();
    credentials = _FakeCredentials();
    model = SignInViewModel(SignIn(repository,
        biometrics: biometrics, credentials: credentials));
  });
  tearDown(() => model.dispose());

  group('saved account', () {
    setUp(() => model.load());

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

    test('devices without biometrics or passcode continue as before',
        () async {
      biometrics.available = false;
      await model.continueAsRecognizedUser();
      expect(biometrics.reasons, isEmpty);
      expect(model.value.status, AuthStatus.authenticated);
    });
  });

  group('Face ID sign-in', () {
    test('the switch is offered only when the device supports it', () async {
      await model.load();
      expect(model.value.biometricSignIn, BiometricSignIn.available);

      final other = SignInViewModel(SignIn(repository,
          biometrics: biometrics..available = false,
          credentials: credentials));
      await other.load();
      expect(other.value.biometricSignIn, BiometricSignIn.unavailable);
      other.dispose();
    });

    test('turning it on saves the credentials after Face ID confirms',
        () async {
      await model.load();
      await model.signIn(
          email: ' student@example.com ',
          password: 'secret',
          rememberWithBiometrics: true);
      expect(model.value.status, AuthStatus.authenticated);
      expect(biometrics.reasons,
          ['Confirm it is you to turn on Face ID sign-in']);
      expect(credentials.saved?.email, 'student@example.com');
      expect(credentials.saved?.password, 'secret');
    });

    test('a rejected confirmation signs in without saving', () async {
      biometrics.confirms = false;
      await model.load();
      await model.signIn(
          email: 'student@example.com',
          password: 'secret',
          rememberWithBiometrics: true);
      expect(model.value.status, AuthStatus.authenticated);
      expect(credentials.saved, isNull);
    });

    test('after logout Face ID signs in with the saved credentials',
        () async {
      credentials.saved = const SavedCredentials(
          email: 'student@example.com', password: 'secret');
      await model.load();
      expect(model.value.biometricSignIn, BiometricSignIn.enabled);
      await model.signInWithBiometrics();
      expect(biometrics.reasons, ['Confirm it is you to sign in']);
      expect(repository.lastEmail, 'student@example.com');
      expect(model.value.status, AuthStatus.authenticated);
    });

    test('a failed Face ID never uses the saved credentials', () async {
      credentials.saved = const SavedCredentials(
          email: 'student@example.com', password: 'secret');
      biometrics.confirms = false;
      await model.load();
      await model.signInWithBiometrics();
      expect(repository.signInCalls, 0);
      expect(model.value.status, AuthStatus.authenticationError);
    });

    test('turning it off forgets the credentials', () async {
      credentials.saved = const SavedCredentials(
          email: 'student@example.com', password: 'secret');
      await model.load();
      await model.turnOffBiometricSignIn();
      expect(credentials.saved, isNull);
      expect(model.value.biometricSignIn, BiometricSignIn.available);
      expect(model.value.message, 'Face ID sign-in is turned off.');
    });
  });
}