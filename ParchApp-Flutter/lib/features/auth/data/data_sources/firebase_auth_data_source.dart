import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/data/mobile_api.dart';
import '../../domain/entities/auth_failure.dart';
import '../models/authenticated_user_model.dart';
import '../models/google_account_model.dart';
import 'auth_data_source.dart';

class FirebaseAuthDataSource implements AuthDataSource {
  final FirebaseAuth _auth;
  final MobileApi? profiles;
  FirebaseAuthDataSource(this._auth, {this.profiles});
  Future<AuthenticatedUserModel?> _resolvedUser(User? user) async {
    final model = _model(user);
    if (model == null || profiles == null) return model;
    try {
      final profile = await profiles!.call('getProfile', {});
      if (_auth.currentUser?.uid != user!.uid) return null;
      return AuthenticatedUserModel(
          id: model.id,
          name: profile['name'] as String? ?? model.name,
          email: model.email,
          verified: model.verified);
    } catch (_) {
      return model;
    }
  }

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
      return await _resolvedUser((await action()).user);
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
    if (model == null || _auth.currentUser?.uid != model.id) {
      throw const AuthenticationException(
          'Account created. Sign in again to continue.');
    }
    final createdUser = _auth.currentUser!;
    // Account creation has already succeeded. A profile-update failure must not
    // misleadingly encourage creating the same account again.
    try {
      await createdUser.updateDisplayName(name);
    } on FirebaseAuthException {/* Retryable profile update. */}
    try {
      await profiles?.call('updateProfile', {
        'clientUserId': model.id,
        'fields': {'name': name.trim()}
      });
    } catch (_) {
      /* Account exists; never request creating it again after a profile failure. */
    }
    if (_auth.currentUser?.uid != model.id) {
      throw const AuthenticationException(
          'Account created. Sign in again to continue.');
    }
    return AuthenticatedUserModel(
        id: model.id,
        name: name.trim(),
        email: email,
        verified: createdUser.emailVerified);
  }

  @override
  Future<AuthenticatedUserModel?> getRecognizedUser() async =>
      _resolvedUser(_auth.currentUser);

  @override
  Future<AuthenticatedUserModel?> continueAsRecognizedUser(
      String userId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      throw const AuthenticationException('Sign in again to continue.');
    }
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    return _resolvedUser(_auth.currentUser);
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
