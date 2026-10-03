import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/auth_failure.dart';
import '../models/authenticated_user_model.dart';
import '../models/google_account_model.dart';
import 'auth_data_source.dart';

class FirebaseAuthDataSource implements AuthDataSource {
  final FirebaseAuth _auth;
  FirebaseAuthDataSource(this._auth);
  @override
  Future<void> signOut() => _auth.signOut();

  AuthenticatedUserModel? _model(User? user) => user == null
      ? null
      : AuthenticatedUserModel(
          id: user.uid,
          name: user.displayName ?? user.email ?? '',
          email: user.email ?? '',
          verified: user.emailVerified);

  Future<AuthenticatedUserModel?> _authenticate(
      Future<UserCredential> Function() action) async {
    try {
      return _model((await action()).user);
    } on FirebaseAuthException catch (error) {
      throw AuthenticationException(switch (error.code) {
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' =>
          'Check your email and password.',
        'email-already-in-use' =>
          'An account already exists for this email. Sign in instead.',
        'weak-password' => 'Use a password with at least six characters.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Unable to sign in. Check your connection and try again.',
      });
    }
  }

  @override
  Future<AuthenticatedUserModel?> signIn(String email, String password) =>
      _authenticate(() =>
          _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<AuthenticatedUserModel?> createAccount(
      String name, String email, String password) async {
    final model = await _authenticate(() =>
        _auth.createUserWithEmailAndPassword(email: email, password: password));
    // Account creation has already succeeded. A profile-update failure must not
    // misleadingly encourage creating the same account again.
    try {
      await _auth.currentUser?.updateDisplayName(name);
    } on FirebaseAuthException {/* Retryable profile update. */}
    return _model(_auth.currentUser) ?? model;
  }

  @override
  Future<AuthenticatedUserModel?> getRecognizedUser() async =>
      _model(_auth.currentUser);

  @override
  Future<AuthenticatedUserModel?> continueAsRecognizedUser(
      String userId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      throw const AuthenticationException('Sign in again to continue.');
    }
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    return _model(_auth.currentUser);
  }

  @override
  Future<GoogleAccountModel?> getSuggestedGoogleAccount() async => null;
  @override
  Future<AuthenticatedUserModel?> signInWithGoogle() async =>
      throw const AuthenticationException(
          'Use email and password. Google sign-in is not configured.');
  @override
  Future<AuthenticatedUserModel?> createAccountWithGoogle(String accountId) =>
      signInWithGoogle();
}
