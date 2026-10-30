import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// Discard a restored account only when Auth confirms it is no longer valid.
/// A transport failure must preserve the account and its offline data.
Future<void> validateRestoredAuthSession(FirebaseAuth auth) async {
  final user = auth.currentUser;
  if (user == null) return;
  try {
    await user.reload().timeout(const Duration(seconds: 5));
    if (auth.currentUser?.uid == user.uid) {
      await auth.currentUser!
          .getIdToken(true)
          .timeout(const Duration(seconds: 5));
    }
  } on FirebaseAuthException catch (error) {
    if ({
          'user-not-found',
          'user-disabled',
          'invalid-user-token',
          'user-token-expired'
        }.contains(error.code) &&
        auth.currentUser?.uid == user.uid) {
      await auth.signOut();
    }
  } on TimeoutException {
    // The user can retry sign-in; cached data is not destroyed by a timeout.
  }
}
