import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/features/auth/domain/entities/authenticated_user.dart';
import 'package:parchapp/features/auth/domain/use_cases/sign_in.dart';
import 'package:parchapp/features/auth/domain/use_cases/create_account.dart';
import 'package:parchapp/features/auth/presentation/view_models/auth_state.dart';
import 'package:parchapp/features/auth/presentation/view_models/sign_in_view_model.dart';
import 'package:parchapp/features/auth/presentation/view_models/create_account_view_model.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SignInViewModel signIn;
  late CreateAccountViewModel createAccount;
  setUp(() {
    repository = FakeAuthRepository();
    signIn = SignInViewModel(SignIn(repository));
    createAccount = CreateAccountViewModel(CreateAccount(repository));
  });
  tearDown(() {
    signIn.dispose();
    createAccount.dispose();
  });

  test('sign-in emits loading then authenticated and trims email', () async {
    repository.pendingSignIn = Completer<AuthenticatedUser>();
    final transitions = <AuthStatus>[];
    signIn.addListener(() => transitions.add(signIn.value.status));
    final request =
        signIn.signIn(email: ' student@example.com ', password: 'password');
    expect(signIn.value.status, AuthStatus.loading);
    repository.pendingSignIn!.complete(FakeAuthRepository.user);
    await request;
    expect(transitions, [AuthStatus.loading, AuthStatus.authenticated]);
    expect(signIn.value.user, FakeAuthRepository.user);
    expect(repository.lastEmail, 'student@example.com');
  });

  test('rejected credentials expose an authentication error', () async {
    repository.rejectCredentials = true;
    await signIn.signIn(email: 'student@example.com', password: 'incorrect');
    expect(signIn.value.status, AuthStatus.authenticationError);
    expect(signIn.value.message, 'Invalid credentials.');
    expect(signIn.value.user, isNull);
  });

  for (final input in [
    ('', 'password'),
    ('invalid', 'password'),
    ('a@b.com', '')
  ]) {
    test('invalid sign-in input $input never reaches the repository', () async {
      await signIn.signIn(email: input.$1, password: input.$2);
      expect(signIn.value.status, AuthStatus.validationError);
      expect(repository.signInCalls, 0);
    });
  }

  test('duplicate sign-in submission is ignored while loading', () async {
    repository.pendingSignIn = Completer<AuthenticatedUser>();
    final first = signIn.signIn(email: 'a@b.com', password: 'password');
    await signIn.signIn(email: 'a@b.com', password: 'password');
    expect(repository.signInCalls, 1);
    repository.pendingSignIn!.complete(FakeAuthRepository.user);
    await first;
  });

  test('disposed ViewModel ignores async completion', () async {
    final model = SignInViewModel(SignIn(repository));
    repository.pendingSignIn = Completer<AuthenticatedUser>();
    var notifications = 0;
    model.addListener(() => notifications++);
    final request = model.signIn(email: 'a@b.com', password: 'password');
    model.dispose();
    repository.pendingSignIn!.complete(FakeAuthRepository.user);
    await request;
    expect(notifications, 1);
  });

  test('saved account and Google sign-in use domain operations', () async {
    await signIn.load();
    expect(signIn.value.recognizedUser, FakeAuthRepository.user);
    await signIn.continueAsRecognizedUser();
    expect(signIn.value.status, AuthStatus.authenticated);
    final google = SignInViewModel(SignIn(repository));
    addTearDown(google.dispose);
    await google.signInWithGoogle();
    expect(google.value.status, AuthStatus.authenticated);
  });

  test('missing saved account reports validation failure', () async {
    await signIn.continueAsRecognizedUser();
    expect(signIn.value.status, AuthStatus.validationError);
  });

  test('lookup failure is recoverable with credential sign-in', () async {
    repository.failLookup = true;
    await signIn.load();
    expect(signIn.value.status, AuthStatus.authenticationError);
    await signIn.signIn(email: 'a@b.com', password: 'password');
    expect(signIn.value.status, AuthStatus.authenticated);
    expect(signIn.value.message, isNull);
  });

  test('late saved-account lookup does not erase an authentication error',
      () async {
    repository.pendingRecognizedUser = Completer<AuthenticatedUser?>();
    repository.rejectCredentials = true;
    final lookup = signIn.load();
    await signIn.signIn(email: 'a@b.com', password: 'incorrect');
    repository.pendingRecognizedUser!.complete(FakeAuthRepository.user);
    await lookup;
    expect(signIn.value.status, AuthStatus.authenticationError);
    expect(signIn.value.message, 'Invalid credentials.');
  });

  test('account creation emits loading and success with trimmed inputs',
      () async {
    final states = <AuthStatus>[];
    createAccount.addListener(() => states.add(createAccount.value.status));
    await createAccount.createAccount(
        fullName: ' Student ',
        email: ' a@b.com ',
        password: 'password',
        confirmPassword: 'password');
    expect(states, [AuthStatus.loading, AuthStatus.authenticated]);
    expect(repository.lastName, 'Student');
    expect(repository.lastEmail, 'a@b.com');
  });

  for (final input in [
    ('', 'a@b.com', 'p', 'p'),
    ('Name', '', 'p', 'p'),
    ('Name', 'invalid', 'p', 'p'),
    ('Name', 'a@b.com', '', 'p'),
    ('Name', 'a@b.com', 'p', ''),
    ('Name', 'a@b.com', 'p', 'different')
  ]) {
    test('invalid account input $input does not call the repository', () async {
      await createAccount.createAccount(
          fullName: input.$1,
          email: input.$2,
          password: input.$3,
          confirmPassword: input.$4);
      expect(createAccount.value.status, AuthStatus.validationError);
      expect(repository.createCalls, 0);
    });
  }

  test('account rejection produces authenticationError', () async {
    repository.rejectCredentials = true;
    await createAccount.createAccount(
        fullName: 'Student',
        email: 'a@b.com',
        password: 'password',
        confirmPassword: 'password');
    expect(createAccount.value.status, AuthStatus.authenticationError);
  });

  test('Google account creation loads suggestion then authenticates', () async {
    await createAccount.load();
    expect(createAccount.value.suggestedGoogleAccount,
        FakeAuthRepository.googleAccount);
    await createAccount.continueWithGoogle();
    expect(createAccount.value.status, AuthStatus.authenticated);
  });

  test('Google creation without a suggestion reports validationError',
      () async {
    await createAccount.continueWithGoogle();
    expect(createAccount.value.status, AuthStatus.validationError);
  });
}
