import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/data/restore_auth_session.dart';

class _User extends Fake implements User {
  String? failure;
  int refreshes = 0;
  @override
  String get uid => 'saved-user';
  @override
  Future<void> reload() async {
    if (failure != null) throw FirebaseAuthException(code: failure!);
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (forceRefresh) refreshes++;
    return 'test-token';
  }
}

class _Auth extends Fake implements FirebaseAuth {
  User? user;
  int signOuts = 0;
  _Auth(this.user);
  @override
  User? get currentUser => user;
  @override
  Future<void> signOut() async {
    signOuts++;
    user = null;
  }
}

void main() {
  test('deleted restored account is cleared before protected screens load',
      () async {
    final auth = _Auth(_User()..failure = 'user-not-found');
    await validateRestoredAuthSession(auth);
    expect(auth.currentUser, isNull);
    expect(auth.signOuts, 1);
  });
  test('temporary network failure preserves the account for offline use',
      () async {
    final user = _User()..failure = 'network-request-failed';
    final auth = _Auth(user);
    await validateRestoredAuthSession(auth);
    expect(auth.currentUser, user);
    expect(auth.signOuts, 0);
  });
  test('valid restored account refreshes its token without logging out',
      () async {
    final user = _User();
    final auth = _Auth(user);
    await validateRestoredAuthSession(auth);
    expect(user.refreshes, 1);
    expect(auth.signOuts, 0);
  });
}
