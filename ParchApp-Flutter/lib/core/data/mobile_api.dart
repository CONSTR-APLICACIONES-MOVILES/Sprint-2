import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class MobileApi {
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> input);
}

class FirebaseMobileApi implements MobileApi {
  final FirebaseFunctions functions;
  final FirebaseAuth? auth;
  const FirebaseMobileApi(this.functions, {this.auth});
  @override
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> input) async {
    final owner = auth?.currentUser;
    HttpsCallableResult<dynamic> result;
    try {
      result = await functions.httpsCallable(name).call(input);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'unauthenticated' ||
          owner == null ||
          auth?.currentUser?.uid != owner.uid) {
        rethrow;
      }
      // An unauthenticated callable has not executed the command. Refresh a
      // restored token once; never replay under a different account.
      await owner.getIdToken(true);
      if (auth?.currentUser?.uid != owner.uid) {
        rethrow;
      }
      result = await functions.httpsCallable(name).call(input);
    }
    return Map<String, dynamic>.from(result.data as Map);
  }
}
