import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:parchapp/core/auth/google_sign_in_session.dart';
import 'package:parchapp/features/auth/data/data_sources/firebase_auth_data_source.dart';
import 'package:parchapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:parchapp/features/auth/domain/entities/auth_failure.dart';
import 'package:parchapp/features/auth/domain/use_cases/create_account.dart';
import 'package:parchapp/features/auth/presentation/view_models/create_account_view_model.dart';
import 'package:parchapp/features/auth/presentation/view_models/auth_state.dart';

class GoogleUser extends Fake implements User {
  @override
  String get uid => 'google-user';
  @override
  String get email => 'student@example.test';
  @override
  String get displayName => 'Google student';
  @override
  bool get emailVerified => true;
}

class GoogleCredential extends Fake implements UserCredential {
  @override
  final User user;
  GoogleCredential(this.user);
}

class GoogleAuth extends Fake implements FirebaseAuth {
  @override
  User? currentUser;
  OAuthCredential? received;
  FirebaseAuthException? error;
  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    received = credential as OAuthCredential;
    if (error != null) throw error!;
    currentUser = GoogleUser();
    return GoogleCredential(currentUser!);
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
  }
}

class Identity implements GoogleIdentitySource {
  Object? error;
  bool failCleanup = false;
  @override
  Future<String> authenticate() async {
    if (error != null) throw error!;
    return 'test-id-token';
  }

  @override
  Future<void> signOut() async {
    if (failCleanup) throw StateError('cleanup');
  }
}

void main() {
  test(
      'Google identity token is exchanged with Firebase, not treated as an email suggestion',
      () async {
    final auth = GoogleAuth();
    final user = await FirebaseAuthDataSource(auth, google: Identity())
        .signInWithGoogle();
    expect(auth.received!.providerId, 'google.com');
    expect(auth.received!.idToken, 'test-id-token');
    expect(user!.id, 'google-user');
    expect(user.verified, true);
  });
  test(
      'create-account Google button works without a preselected suggested account',
      () async {
    final model = CreateAccountViewModel(CreateAccount(AuthRepositoryImpl(
        FirebaseAuthDataSource(GoogleAuth(), google: Identity()))));
    await model.load();
    expect(model.value.suggestedGoogleAccount, isNull);
    await model.continueWithGoogle();
    expect(model.value.status, AuthStatus.authenticated);
    model.dispose();
  });
  test('cancellation never creates a Firebase session', () async {
    final auth = GoogleAuth(),
        identity = Identity()
          ..error = const GoogleSignInException(
              code: GoogleSignInExceptionCode.canceled);
    await expectLater(
        FirebaseAuthDataSource(auth, google: identity).signInWithGoogle(),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.message, 'message', contains('cancelled'))));
    expect(auth.received, isNull);
    expect(auth.currentUser, isNull);
  });
  test('Google credential failure does not report an incorrect password',
      () async {
    final auth = GoogleAuth()
      ..error = FirebaseAuthException(code: 'invalid-credential');
    await expectLater(
        FirebaseAuthDataSource(auth, google: Identity()).signInWithGoogle(),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.message, 'message', contains('Google'))));
  });
  test('provider cleanup failure cannot undo successful Firebase sign-out',
      () async {
    final auth = GoogleAuth()..currentUser = GoogleUser();
    await FirebaseAuthDataSource(auth, google: Identity()..failCleanup = true)
        .signOut();
    expect(auth.currentUser, isNull);
  });
}
