import 'dart:async';
import 'package:parchapp/features/auth/domain/entities/authenticated_user.dart';
import 'package:parchapp/features/auth/domain/entities/auth_failure.dart';
import 'package:parchapp/features/auth/domain/entities/google_account.dart';
import 'package:parchapp/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  int signOutCalls = 0;
  bool failSignOut = false;
  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (failSignOut) throw Exception('offline');
  }

  static const user = AuthenticatedUser(
      id: 'test-user',
      name: 'Test Student',
      email: 'student@example.com',
      program: 'Engineering',
      verified: true);
  static const googleAccount = GoogleAccount(
      id: 'google-test', name: 'Google Student', email: 'google@example.com');
  Completer<AuthenticatedUser>? pendingSignIn;
  Completer<AuthenticatedUser?>? pendingRecognizedUser;
  bool rejectCredentials = false;
  bool failLookup = false;
  int signInCalls = 0;
  int createCalls = 0;
  String? lastEmail;
  String? lastName;

  @override
  Future<AuthenticatedUser?> getRecognizedUser() async {
    if (failLookup) throw Exception('offline');
    return pendingRecognizedUser == null
        ? user
        : await pendingRecognizedUser!.future;
  }

  @override
  Future<GoogleAccount?> getSuggestedGoogleAccount() async {
    if (failLookup) throw Exception('offline');
    return googleAccount;
  }

  @override
  Future<AuthenticatedUser> signIn(String email, String password) async {
    signInCalls++;
    lastEmail = email;
    if (rejectCredentials) {
      throw const AuthenticationException('Invalid credentials.');
    }
    return pendingSignIn == null ? user : await pendingSignIn!.future;
  }

  @override
  Future<AuthenticatedUser> signInWithGoogle() async => user;
  @override
  Future<AuthenticatedUser> continueAsRecognizedUser(
          AuthenticatedUser user) async =>
      user;
  @override
  Future<AuthenticatedUser> createAccount(
      String name, String email, String password) async {
    createCalls++;
    lastName = name;
    lastEmail = email;
    if (rejectCredentials) {
      throw const AuthenticationException('Account creation failed.');
    }
    return user;
  }

  @override
  Future<AuthenticatedUser> createAccountWithGoogle(
          GoogleAccount account) async =>
      user;
}
