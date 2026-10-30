import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchapp/core/data/mobile_api.dart';
import 'package:parchapp/features/auth/data/data_sources/firebase_auth_data_source.dart';
import 'package:parchapp/features/auth/domain/entities/auth_failure.dart';

class AccountUser extends Fake implements User {
  @override
  final String uid;
  AccountUser(this.uid);
  int displayUpdates = 0;
  @override
  String get email => '$uid@test.example';
  @override
  String? get displayName => null;
  @override
  bool get emailVerified => false;
  @override
  Future<void> updateDisplayName(String? displayName) async {
    displayUpdates++;
  }
}

class Credential extends Fake implements UserCredential {
  @override
  final User user;
  Credential(this.user);
}

class AccountAuth extends Fake implements FirebaseAuth {
  final owner = AccountUser('owner'), peer = AccountUser('peer');
  @override
  User? currentUser;
  int creates = 0;
  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    creates++;
    currentUser = owner;
    return Credential(owner);
  }
}

class ProfileApi implements MobileApi {
  final AccountAuth auth;
  final bool switchAtRead, switchAtWrite;
  final calls = <Map<String, dynamic>>[];
  ProfileApi(this.auth,
      {this.switchAtRead = false, this.switchAtWrite = false});
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    calls.add({'method': name, ...input});
    if (name == 'getProfile') {
      if (switchAtRead) auth.currentUser = auth.peer;
      return {'name': 'New account'};
    }
    if (switchAtWrite) auth.currentUser = auth.peer;
    throw StateError('Profile unavailable after Auth already created the user');
  }
}

void main() {
  test(
      'a profile failure after Auth creation returns the created account without recreating or verifying it',
      () async {
    final auth = AccountAuth();
    final api = ProfileApi(auth);
    final source = FirebaseAuthDataSource(auth, profiles: api);
    final account = await source.createAccount(
        'New account', 'owner@test.example', 'Password123!');
    expect(auth.creates, 1);
    expect(account!.id, 'owner');
    expect(account.verified, false);
    expect(api.calls.last['clientUserId'], 'owner');
  });
  test(
      'switching during profile read reports the account exists and does not update another account',
      () async {
    final auth = AccountAuth();
    final api = ProfileApi(auth, switchAtRead: true);
    await expectLater(
        FirebaseAuthDataSource(auth, profiles: api)
            .createAccount('Name', 'owner@test.example', 'Password123!'),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.message, 'message', contains('Account created'))));
    expect(auth.creates, 1);
    expect(auth.peer.displayUpdates, 0);
    expect(api.calls.where((c) => c['method'] == 'updateProfile'), isEmpty);
  });
  test(
      'a delayed profile update remains bound to the created UID when the session changes',
      () async {
    final auth = AccountAuth();
    final api = ProfileApi(auth, switchAtWrite: true);
    await expectLater(
        FirebaseAuthDataSource(auth, profiles: api)
            .createAccount('Name', 'owner@test.example', 'Password123!'),
        throwsA(isA<AuthenticationException>()));
    expect(api.calls.last['clientUserId'], 'owner');
    expect(auth.peer.displayUpdates, 0);
    expect(auth.creates, 1);
  });
}
